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


class model #(ETH_STREAMS, ETH_CHANNELS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, MVB_ITEMS, MI_DATA_WIDTH, MI_ADDR_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_app_core::model#(ETH_STREAMS, ETH_CHANNELS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, MVB_ITEMS, MI_DATA_WIDTH, MI_ADDR_WIDTH))

    //RESET
    typedef model#(ETH_STREAMS, ETH_CHANNELS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, MVB_ITEMS, MI_DATA_WIDTH, MI_ADDR_WIDTH) this_type;
    uvm_analysis_imp_reset#(uvm_reset::sequence_item, this_type) analysis_imp_reset;

    //ETH
    localparam ETH_TX_LENGTH_WIDTH  = 16;
    localparam ETH_TX_CHANNEL_WIDTH = 8;
    uvm_tlm_analysis_fifo #(uvm_common::model_item#(uvm_logic_vector::sequence_item#(ETH_RX_HDR_WIDTH)))   eth_mvb_rx[ETH_STREAMS];
    uvm_tlm_analysis_fifo #(uvm_common::model_item#(uvm_byte_array::sequence_item))                        eth_mfb_rx[ETH_STREAMS];
    uvm_analysis_port     #(uvm_common::model_item#(packet_header #(0, 2**ETH_TX_CHANNEL_WIDTH, 2**ETH_TX_LENGTH_WIDTH-1)))    eth_mvb_tx[ETH_STREAMS];
    uvm_analysis_port     #(uvm_common::model_item#(uvm_byte_array::sequence_item))                        eth_mfb_tx[ETH_STREAMS];
    //DMA
    localparam DMA_RX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_TX_CHANNELS);
    uvm_tlm_analysis_fifo #(uvm_common::model_item#(uvm_logic_vector::sequence_item#(DMA_RX_MVB_WIDTH))) dma_mvb_rx[DMA_STREAMS];
    uvm_tlm_analysis_fifo #(uvm_common::model_item#(uvm_byte_array::sequence_item))                      dma_mfb_rx[DMA_STREAMS];
    uvm_analysis_port     #(uvm_common::model_item#(packet_header #(DMA_HDR_META_WIDTH, DMA_RX_CHANNELS, DMA_PKT_MTU))) dma_mvb_tx[DMA_STREAMS];
    uvm_analysis_port     #(uvm_common::model_item#(uvm_byte_array::sequence_item))                      dma_mfb_tx[DMA_STREAMS];

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        analysis_imp_reset = new("analysis_imp_reset", this);

        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            eth_mvb_rx[it] = new({"eth_mvb_rx_", it_num}, this);
            eth_mfb_rx[it] = new({"eth_mfb_rx_", it_num}, this);
            eth_mvb_tx[it] = new({"eth_mvb_tx_", it_num}, this);
            eth_mfb_tx[it] = new({"eth_mfb_tx_", it_num}, this);
        end

        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            dma_mvb_rx[it] = new({"dma_mvb_rx_", it_num}, this);
            dma_mfb_rx[it] = new({"dma_mfb_rx_", it_num}, this);
            dma_mvb_tx[it] = new({"dma_mvb_tx_", it_num}, this);
            dma_mfb_tx[it] = new({"dma_mfb_tx_", it_num}, this);
        end
    endfunction

    virtual function void regmodel_set(uvm_app_core::regmodel #(ETH_STREAMS, ETH_CHANNELS, DMA_RX_CHANNELS) m_regmodel_base);
    endfunction

    virtual function bit used();
        bit used = 0;

        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            used |= eth_mvb_rx[it].used() != 0;
            used |= eth_mfb_rx[it].used() != 0;
        end

        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            used |= dma_mvb_rx[it].used() != 0;
            used |= dma_mfb_rx[it].used() != 0;
        end
        return used;
    endfunction

    virtual function void write_reset(uvm_reset::sequence_item tr);
        if (tr.reset == 1'b1) begin
            for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
                eth_mvb_rx[it].flush();
                eth_mfb_rx[it].flush();
            end

            for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
                dma_mvb_rx[it].flush();
                dma_mfb_rx[it].flush();
            end
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
