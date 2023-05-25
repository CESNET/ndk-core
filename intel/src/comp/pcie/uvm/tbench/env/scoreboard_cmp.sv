//-- scoreboard.sv: Scoreboard for verification
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author:   Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class scoreboard_mfb #(MFB_ITEM_WIDTH, MFB_BLOCK_SIZE) extends uvm_common::comparer_base_disordered#(uvm_mtc::cc_mtc_item#(MFB_ITEM_WIDTH), uvm_logic_vector_array::sequence_item#(MFB_ITEM_WIDTH));
    `uvm_component_param_utils(uvm_pcie::scoreboard_mfb #(MFB_ITEM_WIDTH, MFB_BLOCK_SIZE))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        int unsigned model_len   = 0;
        int unsigned model_align = 0;
        int unsigned dut_len     = 0;
        int unsigned ret         = 1;

        model_len = tr_model.data_tr.size();
        dut_len   = tr_dut.size();
        model_align = ((model_len % MFB_BLOCK_SIZE) != 0) ? (MFB_BLOCK_SIZE - model_len % MFB_BLOCK_SIZE) : 0;
        `uvm_info(get_type_name(), this.message(tr_model, tr_dut), UVM_MEDIUM)

        if (tr_model.error == '0) begin
            if (dut_len >= model_len && dut_len <= (model_len + model_align)) begin
                for (int unsigned it = 0; it < model_len; it++) begin
                    if (!$isunknown(tr_model.data_tr.data[it]) && tr_model.data_tr.data[it] !== tr_dut.data[it]) begin
                        ret = 0;
                    end
                end
            end
        end
        return ret;
    endfunction

    virtual function string message(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        string msg = "";
        $swrite(msg, "%s\n\tDUT PACKET %s\n\n",   msg, tr_dut.convert2string());
        $swrite(msg, "%s\n\tMODEL PACKET%s\n\n",  msg, tr_model.convert2string());
        return msg;
    endfunction

endclass

class scoreboard_mfb_xilinx #(MFB_ITEM_WIDTH, MFB_BLOCK_SIZE, PCIE_TAG_WIDTH) extends uvm_common::comparer_base_ordered#(uvm_mtc::cc_mtc_item#(MFB_ITEM_WIDTH), uvm_logic_vector_array::sequence_item#(MFB_ITEM_WIDTH));
    `uvm_component_param_utils(uvm_pcie::scoreboard_mfb_xilinx #(MFB_ITEM_WIDTH, MFB_BLOCK_SIZE, PCIE_TAG_WIDTH))

    uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        int unsigned ret = 0;

        if (tr_model.data_tr.data[2][15-1 : 11]) begin
            ret = tr_model.data_tr.compare(tr_dut);
        end else begin
            if (tr_model.data_tr.data[0] !== tr_dut.data[0] || tr_model.data_tr.data[1] !== tr_dut.data[1] || tr_model.data_tr.data[2] !== tr_dut.data[2] || tr_model.data_tr.data[3][32-1 : 8] !== tr_dut.data[3][32-1 : 8]) begin
                $write("tr_model.data_tr.data[0] %h tr_dut.data[0] %h\n", tr_model.data_tr.data[0], tr_dut.data[0]);
                $write("tr_model.data_tr.data[1] %h tr_dut.data[1] %h\n", tr_model.data_tr.data[1], tr_dut.data[1]);
                $write("tr_model.data_tr.data[2] %h tr_dut.data[2] %h\n", tr_model.data_tr.data[2], tr_dut.data[2]);
                $write("tr_model.data_tr.data[3][32-1 : 8] %h tr_dut.data[3][32-1 : 8] %h\n", tr_model.data_tr.data[3][32-1 : 8], tr_dut.data[3][32-1 : 8]);
                ret = 0;
            end else begin
                ret = 1;
            end
            tag_man.code(tr_dut.data[3][8-1 : 0], tr_model.data_tr.data[3][8-1 : 0]);
        end
        return ret;
    endfunction

    virtual function string message(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        string msg = "";
        $swrite(msg, "%s\n\tDUT PACKET %s\n\n",   msg, tr_dut.convert2string());
        $swrite(msg, "%s\n\tMODEL PACKET%s\n\n",  msg, tr_model.convert2string());
        return msg;
    endfunction

endclass

class scoreboard_mvb #(AVST_UP_META_W, PCIE_TAG_WIDTH, type CLASS_TYPE) extends uvm_common::comparer_disordered#(CLASS_TYPE);
    `uvm_component_param_utils(uvm_pcie::scoreboard_mvb #(AVST_UP_META_W, PCIE_TAG_WIDTH, CLASS_TYPE))

    uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        int unsigned ret = 1;
        if (tr_model.data[126]) begin
            ret = tr_model.compare(tr_dut);
        end else begin
            // TODO: in model add support for tag translation
            if (tr_model.data[72-1 : 0] !== tr_dut.data[72-1 : 0] || tr_model.data[AVST_UP_META_W-1 : 80] !== tr_dut.data[AVST_UP_META_W-1 : 80]) begin
                ret = 0;
            end
            tag_man.code(tr_dut.data[80-1 : 72], tr_model.data[80-1 : 72]);
        end
        return ret;
    endfunction

    virtual function string message(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        string msg = "";
        $swrite(msg, "%s\n\tDUT PACKET %s\n\n",   msg, tr_dut.convert2string());
        $swrite(msg, "%s\n\tMODEL PACKET%s\n\n",  msg, tr_model.convert2string());
        return msg;
    endfunction

endclass

class scoreboard_mtc_mfb_xilinx #(MFB_ITEM_WIDTH) extends uvm_common::comparer_base_ordered#(uvm_mtc::cc_mtc_item#(MFB_ITEM_WIDTH), uvm_logic_vector_array::sequence_item#(MFB_ITEM_WIDTH));
    `uvm_component_param_utils(uvm_pcie::scoreboard_mtc_mfb_xilinx #(MFB_ITEM_WIDTH))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        int unsigned ret         = 1;

        ret = tr_model.data_tr.compare(tr_dut);

        return ret;
    endfunction

    virtual function string message(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        string msg = "";
        $swrite(msg, "%s\n\tDUT PACKET %s\n\n",   msg, tr_dut.convert2string());
        $swrite(msg, "%s\n\tMODEL PACKET%s\n\n",  msg, tr_model.convert2string());
        return msg;
    endfunction

endclass