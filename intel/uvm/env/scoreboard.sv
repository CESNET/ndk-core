/*
 * file       : scoreboard.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: scoreboard compare transactions from DUT and MODEL 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class scoreboard #(ETH_STREAMS, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH) extends uvm_env;
    `uvm_component_param_utils(uvm_app_core::scoreboard#(ETH_STREAMS, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH))

    //RESET --
    typedef scoreboard #(ETH_STREAMS, ETH_RX_HDR_WIDTH, ETH_TX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH) this_type;
    uvm_analysis_imp_reset#(uvm_reset::sequence_item, this_type) analysis_imp_reset;
 
    //// ETH I/O
    localparam ETH_TX_LENGTH_WIDTH  = 16;
    localparam ETH_TX_CHANNEL_WIDTH = 8;
    uvm_common::fifo_model_input#(uvm_logic_vector::sequence_item#(ETH_RX_HDR_WIDTH)) eth_mvb_rx[ETH_STREAMS];
    uvm_common::fifo_model_input#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) eth_mfb_rx[ETH_STREAMS];
    uvm_analysis_export #(uvm_logic_vector::sequence_item#(ETH_TX_HDR_WIDTH))   eth_mvb_tx[ETH_STREAMS];
    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))   eth_mfb_tx[ETH_STREAMS];
    // DMA I/O
    localparam DMA_RX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_TX_CHANNELS);
    localparam DMA_TX_MVB_WIDTH = $clog2(DMA_PKT_MTU+1)+DMA_HDR_META_WIDTH+$clog2(DMA_RX_CHANNELS) + 1;
    uvm_common::fifo_model_input#(uvm_logic_vector::sequence_item#(DMA_RX_MVB_WIDTH)) dma_mvb_rx[DMA_STREAMS];
    uvm_common::fifo_model_input#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) dma_mfb_rx[DMA_STREAMS];
    uvm_analysis_export #(uvm_logic_vector::sequence_item#(DMA_TX_MVB_WIDTH))   dma_mvb_tx[DMA_STREAMS];
    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))   dma_mfb_tx[DMA_STREAMS];

    //////////////////////////
    // CONNECTION to internal fifos
    protected scoreboard_channel_header#(ETH_TX_HDR_WIDTH, 0, 2**ETH_TX_CHANNEL_WIDTH, 2**ETH_TX_LENGTH_WIDTH-1) eth_mvb_cmp[ETH_STREAMS];
    protected scoreboard_channel_mfb #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))                       eth_mfb_cmp[ETH_STREAMS];
    protected scoreboard_channel_header#(DMA_TX_MVB_WIDTH, DMA_HDR_META_WIDTH, DMA_RX_CHANNELS, DMA_PKT_MTU)     dma_mvb_cmp[DMA_STREAMS];
    protected scoreboard_channel_mfb #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))                       dma_mfb_cmp[DMA_STREAMS];

    /////////////////////////
    // MODEL
    protected model #(ETH_STREAMS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH) m_model;

    ////////////////////////
    // LOCAL VARIABLES
    local int unsigned errors = 0;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        analysis_imp_reset = new("analysis_imp_reset", this);
    endfunction

    function void build_phase(uvm_phase phase);
        ///////////////
        // ETH BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            eth_mvb_rx[it] = uvm_common::fifo_model_input#(uvm_logic_vector::sequence_item#(ETH_RX_HDR_WIDTH))::type_id::create({"eth_mvb_rx_", it_num}, this);
            eth_mfb_rx[it] = uvm_common::fifo_model_input#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))::type_id::create({"eth_mfb_rx_", it_num}, this);
            eth_mvb_tx[it] = new({"eth_mvb_tx_", it_num}, this);
            eth_mfb_tx[it] = new({"eth_mfb_tx_", it_num}, this);

            eth_mvb_cmp[it] = scoreboard_channel_header#(ETH_TX_HDR_WIDTH, 0, 2**ETH_TX_CHANNEL_WIDTH, 2**ETH_TX_LENGTH_WIDTH-1)::type_id::create({"eth_mvb_cmp_", it_num}, this);
            //eth_mvb_cmp[it].prefix_set({"ETH [", it_num, "] header "});

            eth_mfb_cmp[it] = scoreboard_channel_mfb #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))::type_id::create({"eth_mfb_cmp_", it_num}, this);
            //eth_mfb_cmp[it].prefix_set({"ETH [", it_num, "] packet "});
        end

        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);

            dma_mvb_rx[it] = uvm_common::fifo_model_input#(uvm_logic_vector::sequence_item#(DMA_RX_MVB_WIDTH))::type_id::create({"dma_mvb_rx_", it_num}, this);
            dma_mfb_rx[it] = uvm_common::fifo_model_input#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))::type_id::create({"dma_mfb_rx_", it_num}, this);
            dma_mvb_tx[it] = new({"dma_mvb_tx_", it_num}, this);
            dma_mfb_tx[it] = new({"dma_mfb_tx_", it_num}, this);

            dma_mvb_cmp[it] = uvm_app_core::scoreboard_channel_header#(DMA_TX_MVB_WIDTH, DMA_HDR_META_WIDTH, DMA_RX_CHANNELS, DMA_PKT_MTU)::type_id::create({"dma_mvb_cmp_", it_num}, this);
            //dma_mvb_cmp[it].prefix_set({"DMA [", it_num, "] header "});

            dma_mfb_cmp[it] = scoreboard_channel_mfb #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH))::type_id::create({"dma_mfb_cmp_", it_num}, this);
            //dma_mfb_cmp[it].prefix_set({"DMA [", it_num, "] packet "});
        end

        m_model = model#(ETH_STREAMS, ETH_RX_HDR_WIDTH, DMA_STREAMS, DMA_RX_CHANNELS, DMA_TX_CHANNELS, DMA_HDR_META_WIDTH, DMA_PKT_MTU, ITEM_WIDTH)::type_id::create("m_model", this);
    endfunction

    virtual function void regmodel_set(uvm_app_core::regmodel m_regmodel_base);
        m_model.regmodel_set(m_regmodel_base);
    endfunction

    function void timeout_set(time delay_max, time model_timeout = 0ns);
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            eth_mvb_cmp[it].dut_tr_timeout_set(delay_max);
            eth_mvb_cmp[it].model_tr_timeout_set(model_timeout);
            eth_mfb_cmp[it].dut_tr_timeout_set(delay_max);
            eth_mfb_cmp[it].model_tr_timeout_set(model_timeout);
        end

        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            dma_mvb_cmp[it].dut_tr_timeout_set(delay_max);
            dma_mvb_cmp[it].model_tr_timeout_set(model_timeout);
            dma_mfb_cmp[it].dut_tr_timeout_set(delay_max);
            dma_mfb_cmp[it].model_tr_timeout_set(model_timeout);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        ///////////////
        // ETH BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);
            //INPUT TO MODEL
            m_model.eth_mvb_rx[it] = eth_mvb_rx[it];
            m_model.eth_mfb_rx[it] = eth_mfb_rx[it];
            //INPUT TO SC
            eth_mvb_tx[it].connect(eth_mvb_cmp[it].analysis_imp_dut);
            eth_mfb_tx[it].connect(eth_mfb_cmp[it].analysis_imp_dut);
            m_model.eth_mvb_tx[it].connect(eth_mvb_cmp[it].analysis_imp_model);
            m_model.eth_mfb_tx[it].connect(eth_mfb_cmp[it].analysis_imp_model);
        end

        ///////////////
        // DMA BUILD ANALYSIS EXPORTS
        for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
            string it_num;
            it_num.itoa(it);
            // INPUT TO MODEL
            m_model.dma_mvb_rx[it] = dma_mvb_rx[it];
            m_model.dma_mfb_rx[it] = dma_mfb_rx[it];
            // INPUT TO SCOREBOARD
            dma_mvb_tx[it].connect(dma_mvb_cmp[it].analysis_imp_dut);
            dma_mfb_tx[it].connect(dma_mfb_cmp[it].analysis_imp_dut);
            m_model.dma_mvb_tx[it].connect(dma_mvb_cmp[it].analysis_imp_model);
            m_model.dma_mfb_tx[it].connect(dma_mfb_cmp[it].analysis_imp_model);
        end
    endfunction

    function void write_reset(uvm_reset::sequence_item tr);
        static bit previs = 1;
        if (tr.reset === 1'b1) begin
            m_model.reset();
            //print info
            if (previs == 0) begin
                string msg = "";
                $sformat(msg, "\n\tRESET DESIGN scoreboard compared data before reset");
                for(int it = 0; it < ETH_STREAMS; it++) begin
                    $swrite(msg, "%s\n\tETH[%0d] MFB %s", msg, it, eth_mfb_cmp[it].info());
                    $swrite(msg, "%s\n\tETH[%0d] MVB %s", msg, it, eth_mvb_cmp[it].info());
                end

                for(int it = 0; it < DMA_STREAMS; it++) begin
                    $swrite(msg, "%s\n\tDMA[%0d] MFB %s", msg, it, dma_mvb_cmp[it].info());
                    $swrite(msg, "%s\n\tDMA[%0d] MVB %s", msg, it, dma_mvb_cmp[it].info());
                end
                `uvm_info(this.get_full_name(), msg, UVM_LOW);
            end

            //RESET
            for (int unsigned it = 0; it < ETH_STREAMS; it++) begin
                eth_mvb_cmp[it].flush();
                eth_mfb_cmp[it].flush();
            end

            for (int unsigned it = 0; it < DMA_STREAMS; it++) begin
                dma_mvb_cmp[it].flush();
                dma_mfb_cmp[it].flush();
            end
        end
        previs = tr.reset;
    endfunction

    virtual function int unsigned success();
        int unsigned ret = 1;

        for(int it = 0; it < ETH_STREAMS; it++) begin
            ret |= eth_mvb_cmp[it].success();
            ret |= eth_mfb_cmp[it].success();
        end

        for(int it = 0; it < DMA_STREAMS; it++) begin
            ret |= dma_mvb_cmp[it].success();
            ret |= dma_mfb_cmp[it].success();
        end
        ret &= (errors == 0);

        return ret;
    endfunction


    function int unsigned used();
        int unsigned ret = 0;

        for(int it = 0; it < ETH_STREAMS; it++) begin
            ret |= eth_mvb_cmp[it].used();
            ret |= eth_mfb_cmp[it].used();
        end

        for(int it = 0; it < DMA_STREAMS; it++) begin
            ret |= dma_mvb_cmp[it].used();
            ret |= dma_mfb_cmp[it].used();
        end
        ret |= m_model.used();

        return ret;
    endfunction

    function void report_phase(uvm_phase phase);
        string str = "";

        for(int it = 0; it < ETH_STREAMS; it++) begin
            $swrite(str, "%s\n\tETH[%0d] MFB %s", str, it, eth_mfb_cmp[it].info());
            $swrite(str, "%s\n\tETH[%0d] MVB %s", str, it, eth_mvb_cmp[it].info());
        end

        for(int it = 0; it < DMA_STREAMS; it++) begin
            $swrite(str, "%s\n\tDMA[%0d] MFB %s", str, it, dma_mvb_cmp[it].info());
            $swrite(str, "%s\n\tDMA[%0d] MVB %s", str, it, dma_mvb_cmp[it].info());
        end

        $swrite(str, "%s\n\tother errors %0d\n\tModel working %b", str, errors, m_model.used());
        if (this.used() == 0 && this.success()) begin
            `uvm_info(get_type_name(), {str, "\n\n\t---------------------------------------\n\t----     VERIFICATION SUCCESS      ----\n\t---------------------------------------"}, UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), {str, "\n\n\t---------------------------------------\n\t----     VERIFICATION FAIL      ----\n\t---------------------------------------"}, UVM_NONE)
        end
    endfunction

    //DEPRECAITED
    function void delay_max_set(time delay_max, time model_timeout = 10us);
        this.timeout_set(delay_max, model_timeout);
    endfunction
endclass
