


class sequence_eth#(int unsigned CHANNELS, int unsigned LENGTH_WIDTH, int unsigned ITEM_WIDTH)
        extends uvm_app_core_top_agent::uvm_sequence #(uvm_app_core_top_agent::sequence_eth_item#(CHANNELS, LENGTH_WIDTH, ITEM_WIDTH));
    `uvm_object_param_utils(uvm_app_core::sequence_eth#(CHANNELS, LENGTH_WIDTH, ITEM_WIDTH))

    typedef struct{
        rand logic [32-1:0] sec;
        rand logic [32-1:0] nano_sec;
    } timestamp_t;

    int unsigned transaction_min = 100;
    int unsigned transaction_max = 300;

    rand int unsigned   transactions;
    rand timestamp_t    time_start;

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
            timestamp_t     time_act;
            logic [64-1:0]  time_sim = $time()/1ns;

            time_act.nano_sec = (time_start.nano_sec + time_sim)%1000000000;
            time_act.sec      = time_start.sec       + (time_start.nano_sec + time_sim)/1000000000;

            //generat new packet
            start_item(req);
            req.randomize() with {
                req.data.size() inside {[60:1500]};
                timestamp_vld dist { 1'b1 :/ 80, 1'b0 :/20};
                timestamp_vld -> req.timestamp == {time_act.sec, time_act.nano_sec};
            };
            finish_item(req);
        end
    endtask
endclass

