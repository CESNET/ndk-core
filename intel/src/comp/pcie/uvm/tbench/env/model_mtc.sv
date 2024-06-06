// model_mtc.sv: Model of mtc 
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Radek Iša <isa@cesnet.cz> 

// SPDX-License-Identifier: BSD-3-Clause


class model_mtc #(MI_DATA_WIDTH, MI_ADDR_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie_top::model_mtc #(MI_DATA_WIDTH, MI_ADDR_WIDTH))

    //REQUEST (PCIE -> MI)
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_pcie::request_header)) pcie_cq;
    uvm_analysis_port     #(uvm_common::model_item #(uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0))) mi_req;

    //RESPONSE (MI -> PCIE)
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_mi::sequence_item_response #(MI_DATA_WIDTH)))  mi_rsp;
    uvm_analysis_port     #(uvm_common::model_item #(uvm_pcie::completer_header))                       pcie_cc;

    protected int unsigned pcie_cq_cnt;
    protected int unsigned pcie_cc_cnt;

    //Store request
    protected uvm_common::model_item #(uvm_pcie::request_header) request_rd[$];

    function new (string name, uvm_component parent = null);
        super.new(name, parent);
        pcie_cq = new("pcie_cq", this);
        mi_req = new("mi_req", this);

        mi_rsp    = new("mi_rsp", this);
        pcie_cc   = new("pcie_cc", this);

        pcie_cq_cnt = 0;
        pcie_cc_cnt = 0;
    endfunction

    function int unsigned used();
        int unsigned ret = 0;
        ret |= (pcie_cq.used() != 0);
        //ret |= (mi_rsp.used()  != 0);
        return ret;
    endfunction

    function int unsigned success();
        int unsigned ret = 1;
        return ret;
    endfunction

    function uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0) gen_mi_read(input logic[32-1 : 0] addr, input logic[(32/8)-1 : 0] be);
        uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0) mi_tr;

        mi_tr = uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0)::type_id::create("mi_tr");
        mi_tr.dwr  = '0;
        mi_tr.addr = addr;
        mi_tr.be   = be;
        mi_tr.wr   = 1'b0;
        mi_tr.rd   = 1'b1;
        mi_tr.ardy = 1'b1;
        mi_tr.meta = 'z;
        return mi_tr;
    endfunction

    function uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0) gen_mi_write(input logic[32-1 : 0] addr, input logic[32-1 : 0] data, input logic[(MI_DATA_WIDTH/8)-1 : 0] be);
        uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0) mi_tr;

        mi_tr = uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0)::type_id::create("mi_tr");
        mi_tr.dwr  = data;
        mi_tr.addr = addr;
        mi_tr.be   = be;
        mi_tr.wr   = 1'b1;
        mi_tr.rd   = 1'b0;
        mi_tr.ardy = 1'b1;
        mi_tr.meta = 'z;

        return mi_tr;
    endfunction

    //pure virtual task get_pcie_request(output pcie_info info, logic [MFB_ITEM_WIDTH-1:0] data[]);

    task run_request();
        uvm_common::model_item #(uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0))        mi_tr;
        logic [(MI_DATA_WIDTH/8)-1 : 0] be;
        logic wr;
        logic rd;
        logic [MI_ADDR_WIDTH-1:0] mi_addr;
        logic [64-1:0] tlp_addr_mask;

        logic[sv_pcie_meta_pack::PCIE_META_REQ_HDR_W-1 : 0] hdr;
        logic[(sv_pcie_meta_pack::PCIE_CQ_META_WIDTH-sv_pcie_meta_pack::PCIE_META_REQ_HDR_W)-1 : 0] meta;

        forever begin
            logic  [MI_ADDR_WIDTH-1:0] mi_addr;
            uvm_pcie_extend::request_header                    info_item;
            uvm_common::model_item #(uvm_pcie::request_header) info;

            pcie_cq.get(info);
            pcie_cq_cnt++;
            `uvm_info(this.get_full_name(), $sformatf("\nMI Request %0d%s\n", pcie_cq_cnt, info.convert2string()), UVM_MEDIUM);

            if ($cast(info_item, info.item) ) begin
                tlp_addr_mask = '0;
                for (int unsigned it = 0; it < info_item.bar_aperture; it++) begin
                    tlp_addr_mask[it] = 1'b1;
                end

                case (info_item.bar)
                    3'b000  : mi_addr = 'h01000000;
                    3'b001  : mi_addr = 'h02000000;
                    3'b010  : mi_addr = 'h03000000;
                    3'b011  : mi_addr = 'h04000000;
                    3'b100  : mi_addr = 'h05000000;
                    3'b101  : mi_addr = 'h06000000;
                    3'b110  : mi_addr = 'h0A000000;
                    default : mi_addr = 'h0;
                endcase
            end else begin
                `uvm_fatal(this.get_full_name(), "\nUnsupported header");
                tlp_addr_mask = 26'h3ffffff;
                mi_addr       = 'h0;
            end

            //Write request || READ request
             case ({info.item.fmt[3-1:1], info.item.pcie_type})
                 {2'b00, 5'b00000}  : begin rd = 1; wr = 0; end
                 {2'b01, 5'b00000}  : begin rd = 0; wr = 1; end
                default             : begin rd = 0; wr = 0; end
            endcase

            if (wr == 1'b1 || rd == 1'b1) begin
                mi_addr += ({info.item.address, 2'b00} & tlp_addr_mask);

                for (int unsigned it = 0; it < info.item.length_get(); it++) begin
                    logic read;
                    mi_tr      = uvm_common::model_item #(uvm_mi::sequence_item_request #(MI_DATA_WIDTH, MI_ADDR_WIDTH, 0))::type_id::create("mi_tr");
                    mi_tr.start = info.start;

                    if (it == 0) begin
                        be = info.item.fbe;
                    end else if (it == (info.item.length_get() - 1)) begin
                        be = info.item.lbe;
                    end else begin
                        be = '1;
                    end

                    if (wr == 1'b1) begin
                        mi_tr.item = gen_mi_write(mi_addr + it*4, info.item.data[it], be);
                    end else if (rd == 1'b1) begin
                        mi_tr.item = gen_mi_read(mi_addr + it*4, be);
                    end else begin
                        mi_tr.item = null;
                    end
                    mi_req.write(mi_tr);
                end
            end

            request_rd.push_back(info);
        end
    endtask

    task run_responses();
        logic [32-1:0] data_fifo[$];

        forever begin
            logic wr, rd;

            uvm_common::model_item #(uvm_mi::sequence_item_response #(MI_DATA_WIDTH)) mi_cc_tr;
            uvm_common::model_item #(uvm_pcie::request_header)   info;
            uvm_common::model_item #(uvm_pcie::completer_header) rsp;

            wait(request_rd.size() != 0);
            info = request_rd.pop_front();
             case ({info.item.fmt[3-1:1], info.item.pcie_type})
                 {2'b00, 5'b00000}  : begin rd = 1; wr = 0; end
                 {2'b01, 5'b00000}  : begin rd = 0; wr = 1; end
                default             : begin rd = 0; wr = 0; end
            endcase

            data_fifo = {};

            if (rd == 1'b1) begin
                if (rd == 1'b1 || wr == 1'b1) begin
                    for (int unsigned it = 0; it < info.item.length_get(); it++) begin
                        do begin
                            mi_rsp.get(mi_cc_tr);
                        end while(mi_cc_tr.item.drdy !== 1);
                        data_fifo.push_back(mi_cc_tr.item.drd);
                    end
                end
            end

            if (rd == 1'b1) begin
                logic [4-1:0] lbe = info.item.length != 1 ? info.item.lbe : info.item.fbe;

                rsp = uvm_common::model_item #(uvm_pcie::completer_header)::type_id::create("rsp", this);
                rsp.start = info.start;
                rsp.item = uvm_pcie::completer_header::type_id::create("rsp", this);
                rsp.item.fmt               = 3'b010;
                rsp.item.pcie_type         = 5'b01010;
                rsp.item.traffic_class     = info.item.traffic_class;
                rsp.item.id_based_ordering = info.item.id_based_ordering;
                rsp.item.relaxed_ordering  = info.item.relaxed_ordering;
                rsp.item.no_snoop          = info.item.no_snoop;
                rsp.item.th                = info.item.th;
                rsp.item.td                = info.item.td;
                rsp.item.ep                = info.item.ep;
                rsp.item.at                = info.item.at;
                rsp.item.length            = data_fifo.size() != 1024 ? data_fifo.size() : 0;
                rsp.item.data              = data_fifo;
                rsp.item.completer_id      = 0;
                rsp.item.bcm               = 0;
                rsp.item.byte_count        =  unsigned'(data_fifo.size() * 4) - unsigned'(uvm_pcie::encode_fbe(info.item.fbe)) - (4-unsigned'(uvm_pcie::encode_lbe(lbe)));
                rsp.item.requester_id      = info.item.requester_id;
                rsp.item.tag               = info.item.tag;
                rsp.item.compl_status  = 3'b000;
                rsp.item.lower_address = {info.item.address[7-1 : 2], 2'b0} + uvm_pcie::encode_fbe(info.item.fbe);

                pcie_cc_cnt++;
                pcie_cc.write(rsp);
            end else if (wr == 1'b1) begin
                // dont respons to write transactions
            end else begin //error not supported transaction
                logic [4-1:0] lbe = info.item.length != 1 ? info.item.lbe : info.item.fbe;

                rsp = uvm_common::model_item #(uvm_pcie::completer_header)::type_id::create("rsp", this);
                rsp.start = info.start;
                rsp.item = uvm_pcie::completer_header::type_id::create("rsp", this);
                rsp.item.fmt               = 0;
                rsp.item.pcie_type         = 5'b01010;
                rsp.item.traffic_class     = info.item.traffic_class;
                rsp.item.id_based_ordering = info.item.id_based_ordering;
                rsp.item.relaxed_ordering  = info.item.relaxed_ordering;
                rsp.item.no_snoop          = info.item.no_snoop;
                rsp.item.th                = info.item.th;
                rsp.item.td                = info.item.td;
                rsp.item.ep                = info.item.ep;
                rsp.item.at                = info.item.at;
                rsp.item.length            = 'x;
                rsp.item.data              = {}; //data_fifo;
                rsp.item.completer_id      = 0;
                rsp.item.bcm               = 0;
                rsp.item.byte_count        = unsigned'(data_fifo.size() * 4) - unsigned'(uvm_pcie::encode_fbe(info.item.fbe)) - (4-unsigned'(uvm_pcie::encode_lbe(lbe)));
                rsp.item.requester_id      = info.item.requester_id;
                rsp.item.tag               = info.item.tag;
                rsp.item.compl_status  = 3'b001;
                rsp.item.lower_address = '0;

                pcie_cc_cnt++;
                pcie_cc.write(rsp);
            end
        end
    endtask


    task run_phase(uvm_phase phase);
        fork
            run_request();
            run_responses();
        join
    endtask

    function void check_phase(uvm_phase phase);
        if (this.success() == 0 || this.used()) begin
            `uvm_error(this.get_full_name(), $sformatf("\n\tSuccess %0d Transaction in\n\t\tPcie CQ : %0d\n\t\tRsp : %0d", this.success(), pcie_cq.used(), mi_rsp.used()));
        end
    endfunction
endclass


