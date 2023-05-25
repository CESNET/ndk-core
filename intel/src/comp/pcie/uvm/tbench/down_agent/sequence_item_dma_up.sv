//-- pkg.sv
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kriz <danielkriz@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause


// This class represents high level transaction, which can be reusable for other components.
class dma_up_sequence_item extends uvm_sequence_item;
    // Registration of object tools.
    `uvm_object_utils(uvm_down_hdr::dma_up_sequence_item)

    // -----------------------
    // Variables.
    // -----------------------

    rand logic [sv_dma_bus_pack::DMA_REQUEST_GLOBAL_W-1 : 0]  global_id;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_LENGTH_W-1 : 0]  packet_size;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_TYPE_W-1 : 0]    req_type;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : 0]     tag;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_FIRSTIB_W-1 : 0] firstib;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_LASTIB_W-1 : 0]  lastib;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_UNITID_W-1 : 0]  unitid;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_VFID_W-1 : 0]    vfid;
    rand logic                                                pasid;
    rand logic                                                pasidvld;
    rand logic [sv_dma_bus_pack::DMA_REQUEST_RELAXED_W-1 : 0] relaxed;
    // Constructor - creates new instance of this class
    function new(string name = "dma_up_sequence_item");
        super.new(name);
    endfunction

    // -----------------------
    // Common UVM functions.
    // -----------------------

    // Properly copy all transaction attributes.
    function void do_copy(uvm_object rhs);
        dma_up_sequence_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal( "do_copy:", "Failed to cast transaction object.")
            return;
        end
        // Now copy all attributes
        super.do_copy(rhs);
        global_id   = rhs_.global_id;
        packet_size = rhs_.packet_size;
        req_type    = rhs_.req_type;
        tag         = rhs_.tag;
        firstib     = rhs_.firstib;
        lastib      = rhs_.lastib;
        unitid      = rhs_.unitid;
        vfid        = rhs_.vfid;
        pasid       = rhs_.pasid;
        pasidvld    = rhs_.pasidvld;
        relaxed     = rhs_.relaxed;
    endfunction: do_copy

    // Properly compare all transaction attributes representing output pins.
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        bit ret;
        dma_up_sequence_item rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_fatal("do_compare:", "Failed to cast transaction object.")
            return 0;
        end

        ret  = super.do_compare(rhs, comparer);

        ret &= (global_id   === rhs_.global_id  );
        ret &= (packet_size === rhs_.packet_size);
        ret &= (req_type    === rhs_.req_type   );
        ret &= (tag         === rhs_.tag        );
        ret &= (firstib     === rhs_.firstib    );
        ret &= (lastib      === rhs_.lastib     );
        ret &= (unitid      === rhs_.unitid     );
        ret &= (vfid        === rhs_.vfid       );
        ret &= (pasid       === rhs_.pasid      );
        ret &= (pasidvld    === rhs_.pasidvld   );
        ret &= (relaxed     === rhs_.relaxed    );

        return ret;
    endfunction: do_compare

    // Convert transaction into human readable form.
    function string convert2string();
        string ret;

        $swrite(ret, "\tAddress : %h\n\tDword count : %h\n\tRequest_type : %h\n\tTag : %h\n\tFIRST_IB : %h\n\tLAST_IB : %h\n\tUnitid : %h\n\tVfid : %h\n\tPassid : %h\n\tpassidvld : %h\n\tRelaxed : %h\n", global_id, packet_size, req_type, tag, firstib, lastib, unitid,  vfid, pasid, pasidvld, relaxed);

        return ret;
    endfunction
endclass

