/*
 * file       : model.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: Model create expectated output from input. 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/


class packet_header #(WIDTH, CHANNELS, PKT_MTU);
    logic [WIDTH-1:0]             meta;
    logic [$clog2(CHANNELS)-1:0]  channel;
    logic [$clog2(PKT_MTU+1)-1:0] packet_size;
    logic discard;

    function string convert2string();
        string msg;

        $swrite(msg, "\n\tmeta %h\n\tchannel %0d\n\tpacket size %0d\n\tdiscard %b", meta, channel, packet_size, discard);
        return msg;
    endfunction
endclass


class model #(ETH_STREAMS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_app_core::model#(ETH_STREAMS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH))

    //RESET
    typedef model#(ETH_STREAMS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH) this_type;

    //ETH
    localparam ETH_TX_LENGTH_WIDTH  = 16;
    localparam ETH_TX_CHANNEL_WIDTH = 8;
    // ETH_RX
    uvm_common::fifo #(uvm_common::model_item#(uvm_logic_vector::sequence_item#(ETH_RX_HDR_WIDTH)))                eth_mvb_rx[ETH_STREAMS];
    uvm_common::fifo #(uvm_common::model_item#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                eth_mfb_rx[ETH_STREAMS];
    // ETH_TX
    uvm_analysis_port #(uvm_common::model_item#(uvm_app_core::packet_header #(0, 2**ETH_TX_CHANNEL_WIDTH, 2**ETH_TX_LENGTH_WIDTH-1))) eth_mvb_tx[ETH_STREAMS];
    uvm_analysis_port #(uvm_common::model_item#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                                  eth_mfb_tx[ETH_STREAMS];
    localparam DMA_RX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_TX_CHANNELS);
    // DMA RX
    uvm_common::fifo #(uvm_common::model_item#(uvm_logic_vector::sequence_item#(DMA_RX_MVB_WIDTH)))                dma_mvb_rx[DMA_STREAMS];
    uvm_common::fifo #(uvm_common::model_item#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                dma_mfb_rx[DMA_STREAMS];
    // DMA TX
    uvm_analysis_port #(uvm_common::model_item#(uvm_app_core::packet_header #(DMA_HDR_META_WIDTH, DMA_RX_CHANNELS, DMA_PKT_MTU))) dma_mvb_tx[DMA_STREAMS];
    uvm_analysis_port #(uvm_common::model_item#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                              dma_mfb_tx[DMA_STREAMS];

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            eth_mvb_rx[it] = null;
            eth_mfb_rx[it] = null;
            eth_mvb_tx[it] = new({"eth_mvb_tx_", it_num}, this);
            eth_mfb_tx[it] = new({"eth_mfb_tx_", it_num}, this);
        end

        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            dma_mvb_rx[it] = null;
            dma_mfb_rx[it] = null;
            dma_mvb_tx[it] = new({"dma_mvb_tx_", it_num}, this);
            dma_mfb_tx[it] = new({"dma_mfb_tx_", it_num}, this);
        end
    endfunction

    virtual function void regmodel_set(uvm_app_core::regmodel m_regmodel_base);
    endfunction

    virtual function bit used();
        bit ret = 0;

        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            ret |= (eth_mvb_rx[it].used() != 0);
            ret |= (eth_mfb_rx[it].used() != 0);
        end
        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            ret |= (dma_mvb_rx[it].used() != 0);
            ret |= (dma_mfb_rx[it].used() != 0);
        end
        return 0;
    endfunction

    virtual function void reset();
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            eth_mvb_rx[it].flush();
            eth_mfb_rx[it].flush();
        end
        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            dma_mvb_rx[it].flush();
            dma_mfb_rx[it].flush();
        end
    endfunction

    virtual task run_eth(uvm_phase phase, int unsigned index);
    endtask

    virtual task run_dma(uvm_phase phase, int unsigned index);
    endtask

    task run_phase(uvm_phase phase);
        for(int it = 0; it < ETH_STREAMS; it++) begin
            fork
                automatic int index = it;
                run_eth(phase, index);
            join_none;
        end

        for(int it = 0; it < DMA_STREAMS; it++) begin
            fork
                automatic int index = it;
                run_dma(phase, index);
            join_none;
        end
    endtask
endclass
