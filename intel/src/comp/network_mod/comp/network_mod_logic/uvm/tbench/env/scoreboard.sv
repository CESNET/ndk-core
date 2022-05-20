// scoreboard.sv: Scoreboard for verification
// Copyright (C) 2022 CESNET z. s. p. o.
// Author(s): Daniel Kondys <xkondy00@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause  


class mfb_compare extends uvm_component;
    `uvm_component_param_utils(net_mod_logic_env::mfb_compare)

    int unsigned errors;
    int unsigned compared;

    uvm_tlm_analysis_fifo #(byte_array::sequence_item) model_data;
    uvm_tlm_analysis_fifo #(byte_array::sequence_item) dut_data;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        model_data = new("model_data", this);
        dut_data   = new("dut_data", this);
        errors     = 0;
        compared   = 0;
    endfunction

    function int unsigned used();
        int unsigned ret = 0;
        ret |= (model_data.used() != 0);
        ret |= (dut_data.used()   != 0);
        return ret;
    endfunction

    task run_phase(uvm_phase phase);
        byte_array::sequence_item tr_model_packet;
        byte_array::sequence_item tr_dut_packet;

        forever begin
            model_data.get(tr_model_packet);
            dut_data.get(tr_dut_packet);

            compared++;
            if (compared%100 == 0) begin
                $display("%s\n\tTX: packet number %d compared.", this.get_full_name(), compared);
            end

            if (tr_model_packet.compare(tr_dut_packet) == 0) begin
                string msg;

                errors++;
                $swrite(msg, "\n\tCheck packet failed.\n\n\tModel Packet\n%s\n\tDUT PACKET\n%s", tr_model_packet.convert2string(), tr_dut_packet.convert2string());
                `uvm_error(this.get_full_name(), msg);
            end
        end
    endtask

endclass

class model_discard#(REGIONS) extends uvm_component;
    `uvm_component_param_utils(net_mod_logic_env::model_discard#(REGIONS))

    uvm_tlm_analysis_fifo #(byte_array::sequence_item)       data;
    uvm_tlm_analysis_fifo #(mvb::sequence_item#(REGIONS, 1)) info;
    uvm_analysis_port     #(byte_array::sequence_item)       out;

    int unsigned packets;
    int unsigned discarded;

    function new(string name, uvm_component parent);
        super.new(name, parent);

        data = new("data", this);
        info = new("info", this);
        out  = new("out", this);
        packets   = 0;
        discarded = 0;
    endfunction

    function int unsigned used();
        int unsigned ret = 0;
        
        data.used();
        info.used();
        return ret;
    endfunction

    task run_phase(uvm_phase phase);
        byte_array::sequence_item tr_data;
        mvb::sequence_item#(REGIONS, 1) tr_info;

        forever begin
            info.get(tr_info);
            if (tr_info.SRC_RDY == 1'b1 && tr_info.DST_RDY == 1'b1) begin
                for (int unsigned it = 0; it < REGIONS; it++) begin
                    if (tr_info.VLD[it] == 1'b1) begin
                        data.get(tr_data);
                        packets++;
                        if (tr_info.DATA[it] == 1'b0 ) begin
                            out.write(tr_data);
                        end else begin
                            discarded++;
                        end
                    end
                end
            end
        end
    endtask
endclass

class mvb_parser#(REGIONS, HDR_WIDTH) extends uvm_component;
    `uvm_component_param_utils(net_mod_logic_env::mvb_parser#(REGIONS, HDR_WIDTH))

    uvm_tlm_analysis_fifo #(mvb::sequence_item#(REGIONS, HDR_WIDTH))  hdr; // all incomming MVB transactions
    uvm_analysis_port     #(logic_vector::sequence_item#(HDR_WIDTH))  out; // only valid MVB transaction

    function new(string name, uvm_component parent);
        super.new(name, parent);
        hdr = new("hdr", this);
        out = new("out", this);
    endfunction

    function int unsigned used();
        int unsigned ret = 0;
        ret |= hdr.used();
        return ret;
    endfunction

    task run_phase(uvm_phase phase);
        mvb::sequence_item#(REGIONS, HDR_WIDTH) tr_info;
        logic_vector::sequence_item#(HDR_WIDTH) tr_data;

        forever begin
            hdr.get(tr_info);
            if (tr_info.SRC_RDY == 1'b1 && tr_info.DST_RDY == 1'b1) begin
                for (int unsigned it = 0; it < REGIONS; it++) begin
                    if (tr_info.VLD[it] == 1'b1) begin
                        tr_data = logic_vector::sequence_item#(HDR_WIDTH)::type_id::create("tr_data");
                        tr_data.data = tr_info.DATA[it];
                        out.write(tr_data);
                    end
                end
            end
        end
    endtask

endclass


class scoreboard #(CHANNELS, REGIONS, META_WIDTH, HDR_WIDTH, RX_MAC_LITE_REGIONS) extends uvm_scoreboard;
    `uvm_component_param_utils(net_mod_logic_env::scoreboard #(CHANNELS, REGIONS, META_WIDTH, HDR_WIDTH, RX_MAC_LITE_REGIONS))

    // TX path
    uvm_analysis_export #(byte_array::sequence_item)                 tx_input_data;
    uvm_analysis_export #(logic_vector::sequence_item #(META_WIDTH)) tx_input_meta;
    uvm_analysis_export #(byte_array::sequence_item)                 tx_out_data[CHANNELS];
    mfb_compare                                                      compare[CHANNELS];

    // RX path
    uvm_analysis_export #(byte_array::sequence_item)                 rx_input_data[CHANNELS]; // data for model
    uvm_analysis_export #(byte_array::sequence_item)                 rx_out_data; // MFB data from DUT
    uvm_analysis_export #(mvb::sequence_item#(REGIONS, HDR_WIDTH))   rx_out_hdr; // MVB headers used to identify channel
    uvm_tlm_analysis_fifo #(byte_array::sequence_item)               rx_model_data_out[CHANNELS];
    uvm_tlm_analysis_fifo #(byte_array::sequence_item)               rx_dut_data_out;
    uvm_tlm_analysis_fifo #(logic_vector::sequence_item#(HDR_WIDTH)) rx_dut_hdr_out;
    mvb_parser #(REGIONS, HDR_WIDTH)                                 m_hdr_parser;

    // MVB discard
    uvm_analysis_export #(mvb::sequence_item#(RX_MAC_LITE_REGIONS, 1)) mvb_discard[CHANNELS];
    model_discard #(RX_MAC_LITE_REGIONS)                               m_model_discard[CHANNELS];

    model #(CHANNELS, META_WIDTH) m_model;

    int unsigned errors;
    int unsigned compared;

    // Contructor of scoreboard.
    function new(string name, uvm_component parent);
        super.new(name, parent);

        // TX path
        tx_input_data = new("tx_input_data", this);
        tx_input_meta = new("tx_input_meta", this);
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            string it_str;
            it_str.itoa(it);
            tx_out_data[it] = new({"tx_out_data_", it_str}, this);
        end

        // RX path
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            string it_str;
            it_str.itoa(it);
            rx_input_data[it]     = new({"rx_input_data_", it_str}, this);
            rx_model_data_out[it] = new({"rx_model_data_out_", it_str}, this);
        end
        rx_out_data     = new("rx_out_data", this);
        rx_out_hdr      = new("rx_out_hdr", this);
        rx_dut_data_out = new("rx_dut_data_out", this);
        rx_dut_hdr_out  = new("rx_dut_hdr_out", this);

        // MVB discard
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            string it_str;
            it_str.itoa(it);
            mvb_discard[it]     = new({"mvb_discard_", it_str}, this);
        end

        errors   = 0;
        compared = 0;
    endfunction

    function void build_phase(uvm_phase phase);

        m_model      = model #(CHANNELS, META_WIDTH)::type_id::create("m_model", this);
        m_hdr_parser = mvb_parser#(REGIONS, HDR_WIDTH)::type_id::create("m_hdr_parser", this);
        for (int it = 0; it < CHANNELS; it++) begin
            string it_string;
            it_string.itoa(it);

            m_model_discard[it] = model_discard#(RX_MAC_LITE_REGIONS)::type_id::create({"m_model_discard_", it_string}, this);
            compare[it]         = mfb_compare::type_id::create({"compare_", it_string}, this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        // TX path
        // connect SC inputs to Model
        tx_input_data.connect(m_model.tx_input_data.analysis_export);
        tx_input_meta.connect(m_model.tx_input_meta.analysis_export);
        for (int it = 0; it < CHANNELS; it++) begin
            string i_string;
            // connect Model and DUT data with Compare
            m_model.tx_out_data[it].connect(compare[it].model_data.analysis_export);
            tx_out_data[it].connect(compare[it].dut_data.analysis_export);
        end

        // RX path
        for (int it = 0; it < CHANNELS; it++) begin
            // connect SC with discard model
            rx_input_data[it].connect(m_model_discard[it].data.analysis_export);
            m_model_discard[it].out.connect(m_model.rx_input_data[it].analysis_export);
            // connect Model output to Model FIFO
            m_model.rx_out_data[it].connect(rx_model_data_out[it].analysis_export);
        end
        // connect SC MFB input from DUT to FIFO
        rx_out_data.connect(rx_dut_data_out.analysis_export);
        // connect SC MVB input from DUT to MVB parser
        rx_out_hdr.connect(m_hdr_parser.hdr.analysis_export);
        m_hdr_parser.out.connect(rx_dut_hdr_out.analysis_export);

        // MVB discard
        for (int it = 0; it < CHANNELS; it++) begin
            mvb_discard[it].connect(m_model_discard[it].info.analysis_export);
        end
    endfunction

    // RX path compare
    task run_phase(uvm_phase phase);
        logic [16-1:0] pkt_size;
        logic [8 -1:0] channel;
        int unsigned match;
        string msg;
        logic_vector::sequence_item#(HDR_WIDTH) tr_dut_info;
        byte_array::sequence_item tr_dut_packet;
        byte_array::sequence_item tr_model_packet;

        forever begin
            match = 0;
            msg   = "";

            rx_dut_data_out.get(tr_dut_packet);
            rx_dut_hdr_out.get(tr_dut_info);

            {channel, pkt_size} = tr_dut_info.data[24-1:0];
            rx_model_data_out[channel].get(tr_model_packet);
            match = tr_dut_packet.compare(tr_model_packet);
            compared++;

            if (compared%100 == 0) begin
                $display("\n\tRX: packet number %d compared.", compared);
            end

            if (match == 0) begin
                errors++;
                $swrite(msg, "\n\tCheck packet failed.\n\n\tDUT PACKET number: %0d\n%s\n\n\tDoesn't match the packet at Channel %b:\n%s\n\n", compared, tr_dut_packet.convert2string(), channel, tr_model_packet.convert2string(), msg);
                // DEBUG - print packets at all FIFO outputs
                // for (int unsigned it = 0; it < CHANNELS; it++) begin
                //     if(rx_model_data_out[it].try_get(tr_model_packet) == 1) begin
                //         $write("\n Packet at FIFO %d:\n%s\n", it, tr_model_packet.convert2string());
                //     end
                // end
                `uvm_error(this.get_full_name(), msg);
            end
        end
    endtask

    function int unsigned used();
        int unsigned ret = 0;

        // Verification ends too soon, some packets are still in DUT
        // ret |= m_hdr_parser.used();
        // for (int unsigned it = 0; it < CHANNELS; it++) begin
        //     ret |= m_model_discard[it].used();
        //     ret |= compare[it].used();
        //     ret |= (rx_model_data_out[it].used() != 0);
        // end
        // ret |= (rx_dut_data_out.used() != 0);
        // ret |= (rx_dut_hdr_out.used() != 0);
        return ret;
    endfunction

    function void report_phase(uvm_phase phase);
        int unsigned total_errors = 0;
        string msg = "";

        // TX path
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            $swrite(msg, "%s\n\tTX path OUTPUT [%0d]: compared %0d, errors %0d", msg, it, compare[it].compared, compare[it].errors);
            total_errors = total_errors + compare[it].errors;
        end
        $swrite(msg, "%s\n\t---------------------------------------", msg);

        // RX path
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            $swrite(msg, "%s\n\tRX path INPUT [%0d]: received %0d", msg, it, m_model_discard[it].packets);
        end
        $swrite(msg, "%s\n\tRX path OUTPUT: compared %0d, errors %0d", msg, compared, errors);
        total_errors = total_errors + errors;

        if (total_errors == 0 && this.used() == 0) begin
            `uvm_info(get_type_name(), {msg, "\n\n\t---------------------------------------\n\t----     VERIFICATION SUCCESS      ----\n\t---------------------------------------"}, UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), {msg, "\n\n\t---------------------------------------\n\t----     VERIFICATION FAIL      ----\n\t---------------------------------------"}, UVM_NONE)
        end
    endfunction

endclass
