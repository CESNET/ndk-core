// credit_item.sv: Item of AVST credits
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class credit_item extends uvm_sequence_item;
    `uvm_object_utils(uvm_pcie_intel_r_tile::credit_item)

    // ---------- //
    // Properties //
    // ---------- //

    typedef struct {
        rand int unsigned p;
        rand int unsigned np;
        rand int unsigned cpl;
    } credit_element_t;

    rand credit_element_t header;
    rand credit_element_t data;

    // Constructor
    function new(string name = "credit_item");
        super.new(name);

        reset();
    endfunction

    function void reset();
        header.p   = 0;
        header.np  = 0;
        header.cpl = 0;
        data.p     = 0;
        data.np    = 0;
        data.cpl   = 0;
    endfunction

    function logic is_zero();
        return (header.p   == 0 &&
                header.np  == 0 &&
                header.cpl == 0 &&
                data.p     == 0 &&
                data.np    == 0 &&
                data.cpl   == 0);
    endfunction

    // -------------------- //
    // Common UVM functions //
    // -------------------- //

    function void do_copy(uvm_object rhs);
        credit_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal(this.get_full_name(), "Failed to cast transaction object")
            return;
        end

        super.do_copy(rhs);
        header = rhs_.header;
        data   = rhs_.data;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        credit_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal(this.get_full_name(), "Failed to cast transaction object")
            return 0;
        end

        return (
            super.do_compare(rhs, comparer) &&
            (data   == rhs_.data)           &&
            (header == rhs_.header)
        );
    endfunction

    function string convert2string();
        string output_string = "";

        $sformat(output_string, "\n\tHEADER:\n\t\tP: %0d\n\t\tNP: %0d\n\t\tCPL: %0d\n\tDATA\n\t\tP: %0d\n\t\tNP: %0d\n\t\tCPL: %0d\n",
            header.p,
            header.np,
            header.cpl,
            data.p,
            data.np,
            data.cpl
        );

        return output_string;
    endfunction

endclass
