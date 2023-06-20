//-- sync_tag.sv: Synchronization of tags
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class tag_manager #(PCIE_TAG_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH))

    logic [PCIE_TAG_WIDTH-1 : 0] list_of_tags [logic [PCIE_TAG_WIDTH-1 : 0]];
    int tag_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task add_element(logic[PCIE_TAG_WIDTH-1 : 0] tag);
        string msg;
        list_of_tags[tag] = tag;
        tag_cnt++;
    endtask

    task code(logic[PCIE_TAG_WIDTH-1 : 0] tag_p, logic[PCIE_TAG_WIDTH-1 : 0] tag);
        string msg;
        list_of_tags[tag_p] = tag;
        tag_cnt++;
    endtask

    task get_and_remove(logic[PCIE_TAG_WIDTH-1 : 0] tag, logic last, output logic[PCIE_TAG_WIDTH-1 : 0] out_tag);
        string msg;
        out_tag = list_of_tags[tag];
        if (last) begin
            list_of_tags.delete(tag);
        end
        tag_cnt--;
    endtask

endclass