//-- pkg.sv
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kriz <danielkriz@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause


// This class represents high level transaction, which can be reusable for other components.
class rq_sequence_item extends uvm_sequence_item;
    // Registration of object tools.
    `uvm_object_utils(uvm_down_hdr::rq_sequence_item)

    // -----------------------
    // Variables.
    // -----------------------

    rand logic [sv_dma_bus_pack::DMA_REQUEST_GLOBAL_W-1 : 0]    global_id;
    rand logic [2-1 : 0]                                        padd_1;
    rand logic [(sv_dma_bus_pack::DMA_REQUEST_TAG_W + 8)-1 : 0] req_id;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : 0]       tag;
    rand logic [4-1 : 0]                                        fbe;
    rand logic [4-1 : 0]                                        lbe;
    rand logic [3-1 : 0]                                        fmt;
    rand logic [5-1 : 0]                                        type_n;
    rand logic [1-1 : 0]                                        tag_9;
    rand logic [3-1 : 0]                                        tc;
    rand logic [1-1 : 0]                                        tag_8;
    rand logic [3-1 : 0]                                        padd_0;
    rand logic [1-1 : 0]                                        td;
    rand logic [1-1 : 0]                                        ep;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_RELAXED_W-1 : 0]   relaxed;
    rand logic [1-1 : 0]                                        snoop;
    rand logic [2-1 : 0]                                        at;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_LENGTH_W-1 : 0]    len;
    // Constructor - creates new instance of this class
    function new(string name = "rq_sequence_item");
        super.new(name);
    endfunction

    // -----------------------
    // Common UVM functions.
    // -----------------------

    // Properly copy all transaction attributes.
    function void do_copy(uvm_object rhs);
        rq_sequence_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal( "do_copy:", "Failed to cast transaction object.")
            return;
        end
        // Now copy all attributes
        super.do_copy(rhs);
        global_id = rhs_.global_id;
        padd_1    = rhs_.padd_1;
        req_id    = rhs_.req_id;
        tag       = rhs_.tag;
        fbe       = rhs_.fbe;
        lbe       = rhs_.lbe;
        fmt       = rhs_.fmt;
        type_n    = rhs_.type_n;
        tag_9     = rhs_.tag_9;
        tc        = rhs_.tc;
        tag_8     = rhs_.tag_8;
        padd_0    = rhs_.padd_0;
        td        = rhs_.td;
        ep        = rhs_.ep;
        relaxed   = rhs_.relaxed;
        snoop     = rhs_.snoop;
        at        = rhs_.at;
        len       = rhs_.len;
    endfunction: do_copy

    // Properly compare all transaction attributes representing output pins.
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        bit ret;
        rq_sequence_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal("do_compare:", "Failed to cast transaction object.")
            return 0;
        end

        ret  = super.do_compare(rhs, comparer);

        ret &= (global_id === rhs_.global_id);
        ret &= (padd_1    === rhs_.padd_1   );
        ret &= (req_id    === rhs_.req_id   );
        ret &= (tag       === rhs_.tag      );
        ret &= (fbe       === rhs_.fbe      );
        ret &= (lbe       === rhs_.lbe      );
        ret &= (fmt       === rhs_.fmt      );
        ret &= (type_n    === rhs_.type_n   );
        ret &= (tag_9     === rhs_.tag_9    );
        ret &= (tc        === rhs_.tc       );
        ret &= (tag_8     === rhs_.tag_8    );
        ret &= (padd_0    === rhs_.padd_0   );
        ret &= (td        === rhs_.td       );
        ret &= (ep        === rhs_.ep       );
        ret &= (relaxed   === rhs_.relaxed  );
        ret &= (snoop     === rhs_.snoop    );
        ret &= (at        === rhs_.at       );
        ret &= (len       === rhs_.len      );

        return ret;
    endfunction: do_compare

    // Convert transaction into human readable form.
    function string convert2string();
        string ret;

        $swrite(ret, "\tglobal_id : %h\n\tpadd_1 : %h\n\treq_id : %h\n\ttag : %h\n\tfbe : %h\n\tlbe : %h\n\tfmt : %h\n\ttype_n : %h\n\ttag_9 : %h\n\ttc : %h\n\ttag_8 : %h\n\tpadd_0 : %h\n\ttd : %h\n\tep : %h\n\trelaxed : %h\n\tsnoop : %h\n\tat : %h\n\tlen : %h\n",global_id,padd_1,req_id,tag,fbe,lbe,fmt,type_n,tag_9,tc,tag_8,padd_0,td,ep,relaxed,snoop,at,len);

        return ret;
    endfunction
endclass

