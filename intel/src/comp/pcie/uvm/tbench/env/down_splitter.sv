//-- monitor.sv: Monitor for MVB environment
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class down_splitter #(ITEM_WIDTH, META_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie::down_splitter #(ITEM_WIDTH, META_WIDTH))

    // Analysis port
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                      cq_data_port;
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item#(sv_pcie_meta_pack::PCIE_CQ_META_WIDTH))) cq_meta_port;

    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))                      rc_data_port;
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item#(sv_pcie_meta_pack::PCIE_RC_META_WIDTH))) rc_meta_port;
    uvm_common::fifo#(uvm_pcie::down_tr #(ITEM_WIDTH, META_WIDTH)) model_down;

    function new (string name, uvm_component parent = null);
        super.new(name, parent);
        cq_data_port = new("cq_data_port", this);
        cq_meta_port = new("cq_meta_port", this);
        rc_data_port = new("rc_data_port", this);
        rc_meta_port = new("rc_meta_port", this);
        model_down   = null;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function logic solve_type(logic [8-1 : 0] tlp_type);
        logic ret;

        case (tlp_type)
            8'b01001010 :
            begin
                ret  = 1'b1;
            end
            default : ret = 1'b0;
        endcase

        return ret;
    endfunction

    task run_phase(uvm_phase phase);

        uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))                      tr_mfb_cq_data_out;
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_CQ_META_WIDTH)) tr_mfb_cq_meta_out;
        uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))                      tr_mfb_rc_data_out;
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_RC_META_WIDTH)) tr_mfb_rc_meta_out;
        logic [8-1 : 0] tlp_type;
        logic rw;

        forever begin
            down_tr #(ITEM_WIDTH, META_WIDTH) tr;
            string msg = "\n";

            model_down.get(tr);

            tlp_type = tr.meta.item.data[128-1 : 120];

            rw = solve_type(tlp_type);

            if (rw == 1'b0) begin 
                tr_mfb_cq_meta_out      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_CQ_META_WIDTH))::type_id::create("tr_mfb_cq_meta_out", this);
                tr_mfb_cq_meta_out.item = uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_CQ_META_WIDTH)::type_id::create("tr_mfb_cq_meta_out_item", this);

                tr_mfb_cq_data_out      = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))::type_id::create("tr_mfb_cq_data_out", this);
                tr_mfb_cq_data_out.item = uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)::type_id::create("tr_mfb_cq_data_out_item", this);

                tr_mfb_cq_data_out.copy(tr.data);
                // tr_mfb_cq_meta_out.copy(tr.meta);

                tr_mfb_cq_meta_out.item.data = {tr.meta.item.data[163-1 : 160], tr.meta.item.data[160-1 : 128], tr.meta.item.data[32-1 : 0], tr.meta.item.data[64-1 : 32], tr.meta.item.data[96-1 : 64], tr.meta.item.data[128-1 : 96]};

                $swrite(msg, "%s--------------------------\n", msg);
                $swrite(msg, "%s\tCQ transaction\n", msg);
                $swrite(msg, "%s--------------------------\n", msg);

                $swrite(msg, "%s\tMFB CQ OUTPUT META %s Time %t\n", msg, tr_mfb_cq_meta_out.convert2string(), $time());
                $swrite(msg, "%s\tMFB CQ OUTPUT DATA %s Time %t\n", msg, tr_mfb_cq_data_out.convert2string(), $time());

                cq_data_port.write(tr_mfb_cq_data_out);
                cq_meta_port.write(tr_mfb_cq_meta_out);
            end
            else begin
                tr_mfb_rc_meta_out      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_RC_META_WIDTH))::type_id::create("tr_mfb_rc_meta_out", this);
                tr_mfb_rc_meta_out.item = uvm_logic_vector::sequence_item #(sv_pcie_meta_pack::PCIE_RC_META_WIDTH)::type_id::create("tr_mfb_rc_meta_out_item", this);

                tr_mfb_rc_data_out      = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))::type_id::create("tr_mfb_rc_data_out", this);
                tr_mfb_rc_data_out.item = uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)::type_id::create("tr_mfb_rc_data_out_item", this);

                tr_mfb_rc_data_out.copy(tr.data);
                // tr_mfb_rc_meta_out.copy(tr.meta);

                tr_mfb_rc_meta_out.item.data = {tr.meta.item.data[32-1 : 0], tr.meta.item.data[64-1 : 32], tr.meta.item.data[96-1 : 64], tr.meta.item.data[128-1 : 96]};

                $swrite(msg, "%s--------------------------\n", msg);
                $swrite(msg, "%s\tRC transaction\n", msg);
                $swrite(msg, "%s--------------------------\n", msg);

                $swrite(msg, "%s\tMFB RC OUTPUT DATA %s Time %t\n", msg, tr_mfb_rc_data_out.convert2string(), $time());
                $swrite(msg, "%s\tMFB RC OUTPUT META %s Time %t\n", msg, tr_mfb_rc_meta_out.convert2string(), $time());

                rc_data_port.write(tr_mfb_rc_data_out);
                rc_meta_port.write(tr_mfb_rc_meta_out);
            end

            `uvm_info(get_type_name(), msg, UVM_HIGH)
        end

    endtask
endclass

class cc_meta_convertor #(META_WIDTH, META_WIDTH_NEW) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie::cc_meta_convertor #(META_WIDTH, META_WIDTH_NEW))

    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH_NEW))) out_meta_port;

    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)))       in_meta;

    function new (string name, uvm_component parent = null);
        super.new(name, parent);
        out_meta_port = new("out_meta_port", this);
        in_meta       = new("in_meta", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH_NEW)) tr_out_meta;
        uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH))      tr;
        forever begin
            in_meta.get(tr);

            tr_out_meta      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH_NEW))::type_id::create("tr_out_meta", this);
            tr_out_meta.item = uvm_logic_vector::sequence_item #(META_WIDTH_NEW)::type_id::create("tr_out_meta_item", this);

            tr_out_meta.item.data = {32'bx, tr.item.data[32-1 : 0], tr.item.data[64-1 : 32], tr.item.data[96-1 : 64], tr.item.data[128-1 : 96]};

            out_meta_port.write(tr_out_meta);
        end
    endtask

endclass

class cq_mtc_meta_convertor #(META_WIDTH, ITEM_WIDTH, META_WIDTH_NEW, REGIONS) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie::cq_mtc_meta_convertor #(META_WIDTH, ITEM_WIDTH, META_WIDTH_NEW, REGIONS))

    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH_NEW))) out_meta_port;

    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)))       in_meta;
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))) in_data;

    function new (string name, uvm_component parent = null);
        super.new(name, parent);
        out_meta_port = new("out_meta_port", this);
        in_meta       = new("in_meta", this);
        in_data       = new("in_data", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH_NEW))  tr_out_meta;
        uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH))       tr_meta;
        uvm_common::model_item #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) tr_data;
        logic[128-1 : 0] hdr;
        logic[32-1 : 0]  prefix = '0;
        logic[3-1 : 0]   bar    = '0;
        logic[4-1 : 0]   lbe    = '1;
        logic[4-1 : 0]   fbe    = '1;
        logic[11-1 : 0]  tph    = '0;
        forever begin
            in_data.get(tr_data);
            in_meta.get(tr_meta);

            // TODO: Now for Xilinx there is LBE and FBE '1 and TPH '0
            // for (int unsigned region = 0; region < REGIONS; region++) begin
            //     // lbe
            //     // fbe
            //     $write("tr_meta.item %s\n", tr_meta.item.convert2string());
            //     $write("tr_meta.item.data[region*1 + 80] %b\n", tr_meta.item.data[region*1 + 80]);
            //     $write("region %d\n", region);
            //     if (tr_meta.item.data[region*1 + 80]) begin
            //         tph[0]        = tr_meta.item.data[region*1 + 97];
            //         tph[3-1 : 1]  = tr_meta.item.data[(region*2 + 100) -: 2];
            //         tph[11-1 : 3] = tr_meta.item.data[(region*8 + 110) -: 8];
            //     end
            // end

            tr_out_meta      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH_NEW))::type_id::create("tr_out_meta", this);
            tr_out_meta.item = uvm_logic_vector::sequence_item #(META_WIDTH_NEW)::type_id::create("tr_out_meta_item", this);

            tr_out_meta.item.data = {tph, fbe, lbe, bar, prefix, tr_data.item.data[0], tr_data.item.data[1], tr_data.item.data[2],tr_data.item.data[3]};

            out_meta_port.write(tr_out_meta);
        end
    endtask

endclass
