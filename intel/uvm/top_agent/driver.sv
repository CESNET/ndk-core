//-- driver.sv: Clone packet transaction to mfb and mvb
//-- Copyright (C) 2024 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 


class driver#(ITEM_WIDTH, META_WIDTH) extends uvm_driver #(sequence_item#(ITEM_WIDTH, META_WIDTH));
    `uvm_component_param_utils(uvm_app_core_top_agent::driver#(ITEM_WIDTH, META_WIDTH))

    //RESET reset_sync
    uvm_reset::sync_terminate reset_sync;

    typedef enum {
        STORE_MVB,
        STORE_MFB
    } store_diff_type;

    protected int unsigned diff_min;
    protected int unsigned diff_max;
    protected int unsigned diff_count_min;
    protected int unsigned diff_count_max;
    protected sequence_item#(ITEM_WIDTH, META_WIDTH) fifo_mvb_tmp[$];
    protected sequence_item#(ITEM_WIDTH, META_WIDTH) fifo_mfb_tmp[$];
    protected uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)) fifo_mvb;
    protected uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)) fifo_mfb;

    // Contructor, where analysis port is created.
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        reset_sync = new();
        diff_min = 1;
        diff_max = 100;
        //diff_max = 500;
        diff_count_min =  10;
        diff_count_max = 2000;
    endfunction: new


    function int unsigned used();
        int unsigned ret = 0;
        ret |= (fifo_mvb_tmp.size() != 0);
        ret |= (fifo_mfb_tmp.size() != 0);
        return ret;
    endfunction

    // -----------------------
    // Functions.
    // -----------------------
    task run_fifo_tmp();
        sequence_item#(ITEM_WIDTH, META_WIDTH) gen;
        forever begin

            //In case of RESET  delete all data from MVB and MFB
            wait((fifo_mvb_tmp.size() == 0   || fifo_mfb_tmp.size() == 0) || reset_sync.is_reset());
            if (reset_sync.has_been_reset()) begin

                fifo_mvb_tmp.delete();
                fifo_mfb_tmp.delete();

                while(reset_sync.has_been_reset() != 0) begin
                    #(40ns);
                end
            end

            // GET packet item and divide it
            // to MVB item and MFB item
            seq_item_port.get_next_item(req);
            $cast(gen, req.clone());

            fifo_mvb_tmp.push_back(gen);
            fifo_mfb_tmp.push_back(gen);
            seq_item_port.item_done();
        end
    endtask

    task run_fifo();
        sequence_item#(ITEM_WIDTH, META_WIDTH) gen;
        int unsigned diff;
        int unsigned diff_count;
        store_diff_type diff_type;
        time end_time;

        diff_count = 0;
        forever begin
            time end_time;

            if (diff_count == 0) begin
                diff_count = $urandom_range(diff_count_min, diff_count_max);
                diff       = $urandom_range(diff_min, diff_max);
                assert(std::randomize(diff_type) with { diff_type dist { STORE_MVB := 1'b1, STORE_MFB := 1'b1}; }) else begin `uvm_fatal(this.get_full_name(), "\n\tCannot randomize diff type"); end
            end else begin
                diff_count--;
            end

            // Diff and diff_count. Select randomly if MVB or MFB is going ot be ahed of the other.
            // There is timeout if application cannot received enough data on MVB interface or MFB interface
            wait(fifo_mvb_tmp.size() != 0 && fifo_mfb_tmp.size() != 0);
            if (diff_type == STORE_MVB) begin
                end_time = $time() + 100ns;
                wait(fifo_mfb.size() == 0 || (fifo_mvb.size() == 0 && end_time < $time()));
                if (diff < fifo_mvb_tmp.size() || fifo_mfb_tmp.size() > 0) begin
                    gen = fifo_mvb_tmp.pop_front();
                    fifo_mvb.push_back(gen);
                end
                gen = fifo_mfb_tmp.pop_front();
                fifo_mfb.push_back(gen);
            end else if (diff_type == STORE_MFB) begin
                end_time = $time() + 10ns;
                wait(fifo_mvb.size() == 0 || (fifo_mfb.size() == 0 && end_time < $time()));
                if (diff < fifo_mfb_tmp.size() || fifo_mvb_tmp.size() > 0) begin
                    gen = fifo_mfb_tmp.pop_front();
                    fifo_mfb.push_back(gen);
                end
                gen = fifo_mvb_tmp.pop_front();
                fifo_mvb.push_back(gen);
            end else begin
                `uvm_fatal(this.get_full_name(), $sformatf("\n\tUnknown diff type %s", diff_type));
            end
        end
    endtask

    task run_phase(uvm_phase phase);
        assert (uvm_config_db#(uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)))::get(this, "", "fifo_mvb", fifo_mvb)) else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot get mvb fifo");
        end

        assert (uvm_config_db#(uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)))::get(this, "", "fifo_mfb", fifo_mfb)) else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot get mfb fifo");
        end

        fork
            run_fifo_tmp();
            run_fifo();
        join
    endtask
endclass

