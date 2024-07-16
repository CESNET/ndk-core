


class sequence_eth#(int unsigned CHANNELS, int unsigned LENGTH_WIDTH, int unsigned ITEM_WIDTH)
        extends uvm_app_core_top_agent::uvm_sequence #(uvm_app_core_top_agent::sequence_eth_item#(CHANNELS, LENGTH_WIDTH, ITEM_WIDTH));
    `uvm_object_param_utils(uvm_app_core::sequence_eth#(CHANNELS, LENGTH_WIDTH, ITEM_WIDTH))

    int unsigned transaction_min = 100;
    int unsigned transaction_max = 300;

    rand int unsigned   transactions;

    constraint c_transactions {
        transactions inside {[transaction_min:transaction_max]};
    }

    // Constructor - creates new instance of this class
    function new(string name = "sequence");
        super.new(name);
    endfunction

    // -----------------------
    // Functions.
    // -----------------------
    task body;
        req = uvm_app_core_top_agent::sequence_eth_item#(CHANNELS, LENGTH_WIDTH, ITEM_WIDTH)::type_id::create("req", m_sequencer);

        for (int unsigned it = 0; it < transactions; it++) begin
            logic [64-1:0] timestamp;


            timestamp = $time()/1ns;
            //generat new packet
            start_item(req);
            req.randomize() with {
                req.data.size() inside {[60:1500]};
                timestamp_vld dist { 1'b1 :/ 80, 1'b0 :/20};
                timestamp_vld -> req.timestamp == timestamp;
            };
            finish_item(req);
        end
    endtask
endclass

