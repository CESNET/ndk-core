/*
 * file       : sequence.sv
 * Copyright (C) 2022 CESNET z. s. p. o.
 * description: generatet packet with packet protocols
 * date       : 2022
 * author     : Radek Isa <isa@censet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/


// Reusable high level sequence. Contains transaction, which has only data part.
class sequence_pcap#(ITEM_WIDTH) extends uvm_common::sequence_base#(uvm_logic_vector_array::config_sequence, uvm_logic_vector_array::sequence_item#(ITEM_WIDTH));
    `uvm_object_param_utils(uvm_app_core_packet::sequence_pcap#(ITEM_WIDTH))
    `uvm_declare_p_sequencer(uvm_logic_vector_array::sequencer#(ITEM_WIDTH));

    rand int unsigned transaction_count;
    constraint c1 {transaction_count inside {[cfg.transaction_count_min : cfg.transaction_count_max]};}

    // Constructor - creates new instance of this class
    function new(string name = "sequence_pcap");
        super.new(name);
        cfg = new();

        //pkt_gen_file =  $system({"`dirname ", FILE_PATH, "../pkt_gen/pkt_gen.py"});
    endfunction

    // -----------------------
    // Functions.
    // -----------------------
    task body;
        uvm_pcap::reader reader;
        byte unsigned    data[];
        int unsigned     pkt_num = 0;

        string pcap_file = "test.pcap";
        string pkt_gen_params;

        if (!uvm_config_db #(string)::get(p_sequencer, "", "pcap_file", pcap_file)) begin
            pcap_file = {p_sequencer.get_full_name(), ".pcap"};
        end


        `uvm_info(get_full_name(), $sformatf("\n\tsequence_pcap is running\n\t\tpcap_name%s", pcap_file), UVM_DEBUG);

        reader = new();
        $swrite(pkt_gen_params, "-f \"%s\" -p %0d", pcap_file, transaction_count);
        if($system({PKT_GEN_PATH, " ", pkt_gen_params}) != 0) begin
            `uvm_fatal(p_sequencer.get_full_name(), $sformatf("\n\t Cannot run command %s", {PKT_GEN_PATH, " ", pkt_gen_params}))
        end

        void'(reader.open(pcap_file));
        req = uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)::type_id::create("req", p_sequencer);
        while(reader.read(data) == uvm_pcap::RET_OK)
        begin
            pkt_num++;
            // Generate random request, which must be in interval from min length to max length
            start_item(req);
            req.data = {>>{data}};
            finish_item(req);
        end
        reader.close();
    endtask

endclass



