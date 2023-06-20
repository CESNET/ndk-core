//-- sequence.sv
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kriz <danielkriz@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class byte_array_sequence#(PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RQ_TUSER_WIDTH, RCB_SIZE, CLK_PERIOD, string DEVICE) extends uvm_sequence #(uvm_logic_vector_array::sequence_item #(32));
    `uvm_object_utils(uvm_pcie::byte_array_sequence#(PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RQ_TUSER_WIDTH, RCB_SIZE, CLK_PERIOD, DEVICE))

    localparam LOW_ADDR_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? 7 : 12; // 7 for INTEL 12 XILINX
    localparam BYTE_CNT_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? 12 : 13; // 12 for INTEL 13 XILINX
    localparam HDR_USER_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? PCIE_UPHDR_WIDTH : PCIE_UPHDR_WIDTH+RQ_TUSER_WIDTH;

    uvm_pcie_rc::tr_planner #(HDR_USER_WIDTH, RQ_TUSER_WIDTH, PCIE_DOWNHDR_WIDTH, RCB_SIZE, CLK_PERIOD, DEVICE) tr_plan;
    int unsigned mfb_cnt = 0;

    function new(string name = "sequence_simple_rx_base");
        super.new(name);
    endfunction

    task body;
        req = uvm_logic_vector_array::sequence_item #(32)::type_id::create("req");

        forever begin
            wait(tr_plan.byte_array.size() != 0);
            req = tr_plan.byte_array.pop_front();
            start_item(req);
            finish_item(req);
        end

    endtask
endclass

class logic_vector_sequence #(PCIE_DOWNHDR_WIDTH, PCIE_UPHDR_WIDTH, RQ_TUSER_WIDTH, RCB_SIZE, CLK_PERIOD, string DEVICE) extends uvm_sequence #(uvm_logic_vector::sequence_item#(PCIE_DOWNHDR_WIDTH));
    `uvm_object_param_utils(uvm_pcie::logic_vector_sequence #(PCIE_DOWNHDR_WIDTH, PCIE_UPHDR_WIDTH, RQ_TUSER_WIDTH, RCB_SIZE, CLK_PERIOD, DEVICE))

    localparam LOW_ADDR_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? 7 : 12; // 7 for INTEL 12 XILINX
    localparam BYTE_CNT_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? 12 : 13; // 12 for INTEL 13 XILINX
    localparam HDR_USER_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? PCIE_UPHDR_WIDTH : PCIE_UPHDR_WIDTH+RQ_TUSER_WIDTH;

    uvm_pcie_rc::tr_planner #(HDR_USER_WIDTH, RQ_TUSER_WIDTH, PCIE_DOWNHDR_WIDTH, RCB_SIZE, CLK_PERIOD, DEVICE) tr_plan;
    int unsigned mvb_cnt = 0;

    function new(string name = "logic_vector_sequence");
        super.new(name);
    endfunction

    task body;
        req = uvm_logic_vector::sequence_item#(PCIE_DOWNHDR_WIDTH)::type_id::create("req");

        forever begin
            wait(tr_plan.logic_array.size() != 0);
            req = tr_plan.logic_array.pop_front();
            req.data = {req.data[31 : 0], req.data[63 : 32], req.data[95 : 64], req.data[127 : 96]};
            start_item(req);
            finish_item(req);
        end

    endtask
endclass


// class crdt_sequence#(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, PCIE_MPS_DW) extends uvm_sequence #(uvm_avst_crdt::sequence_item);
//     `uvm_object_param_utils(uvm_pcie_adapter::crdt_sequence#(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, PCIE_MPS_DW))

//     uvm_pcie_adapter::tr_planner #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W) tr_plan;
//     uvm_logic_vector::sequence_item #(AVST_UP_META_W) meta;

//     function new(string name = "logic_vector_array_sequence");
//         super.new(name);
//     endfunction

//     task body;
//         localparam SEED_MIN = (PCIE_MPS_DW/4)/15 + 1;
//         localparam SEED_MAX = (PCIE_MPS_DW/4);
//         logic [11-1 : 0] pcie_len;
//         logic [8-1 : 0] pcie_type;
//         logic [4-1 : 0] credits = '0;
//         int unsigned cnt = 0;
//         int unsigned credit_cnt = 0;
//         logic hdr_valid = 1'b0;
//         logic init = 1'b0;

//         req = uvm_avst_crdt::sequence_item::type_id::create("req");
//         void'(std::randomize(cnt) with {cnt inside {[SEED_MIN : SEED_MAX]}; });

//         forever begin
//             if (tr_plan.tr_array.size() != 0 && init == 1'b1) begin
//                 credit_cnt = 0;
//                 meta = tr_plan.tr_array.pop_front();

//                 if (meta.data[106-1 : 96] == 0)
//                     pcie_len  = 1024;
//                 else
//                     pcie_len  = meta.data[106-1 : 96];

//                 if (pcie_len % 4 != 0) begin
//                     pcie_len += 4 - (pcie_len % 4);
//                 end

//                 pcie_type = meta.data[128-1 : 120];

//                 hdr_valid = 1'b1;

//                 while (pcie_len/4 != credit_cnt) begin
//                     start_item(req);

//                     req.init_done = 1'b1;
//                     req.update    = '0;
//                     req.cnt_ph    = '0;
//                     req.cnt_nph   = '0;
//                     req.cnt_cplh  = '0;
//                     req.cnt_pd    = '0;
//                     req.cnt_npd   = '0;
//                     req.cnt_cpld  = '0;

//                     if (((pcie_len/4) - credit_cnt) >= 15) begin
//                         void'(std::randomize(credits) with {credits inside {[1 : 15]}; });
//                     end else begin
//                         credits = (pcie_len/4) - credit_cnt;
//                     end

//                     credit_cnt += credits;

//                     if (credit_cnt > pcie_len/4) begin
//                         $write("Credit cnt %d\n", credit_cnt);
//                         $write("pcie_len/4 %d\n", pcie_len/4);
//                         `uvm_fatal(this.get_full_name(), "credit_cnt is bigger than pcie_len/4");
//                     end

//                     case (pcie_type)
//                         8'b00000000 :
//                         begin
//                             if (hdr_valid == 1'b1) begin
//                                 req.update[1] = 1'b1;
//                                 req.cnt_nph   = 1'b1;
//                                 hdr_valid     = 1'b0;
//                             end
//                         end
//                         8'b00100000 :
//                         begin
//                             if (hdr_valid == 1'b1) begin
//                                 req.update[1] = 1'b1;
//                                 req.cnt_nph   = 1'b1;
//                                 hdr_valid     = 1'b0;
//                             end
//                         end
//                         8'b01001010 :
//                         begin
//                             req.update[5] = 1'b1;
//                             if (hdr_valid == 1'b1) begin
//                                 req.update[2] = 1'b1;
//                                 req.cnt_cplh  = 1'b1;
//                                 hdr_valid     = 1'b0;
//                             end
//                             req.cnt_cpld = credits;
//                         end
//                         8'b01000000 :
//                         begin
//                             req.update[3] = 1'b1;
//                             if (hdr_valid == 1'b1) begin
//                                 req.update[0] = 1'b1;
//                                 req.cnt_ph    = 1'b1;
//                                 hdr_valid     = 1'b0;
//                             end
//                             req.cnt_pd = credits;
//                         end
//                         8'b01100000 :
//                         begin
//                             req.update[3] = 1'b1;
//                             if (hdr_valid == 1'b1) begin
//                                 req.update[0] = 1'b1;
//                                 req.cnt_ph    = 1'b1;
//                                 hdr_valid     = 1'b0;
//                             end
//                             req.cnt_pd = credits;
//                         end
//                     endcase

//                     finish_item(req);
//                     get_response(rsp);
//                 end

//             end else begin
//                 // Init phase
//                 start_item(req);
//                 req.init_done = 1'b1;
//                 req.update = '0;
//                 req.cnt_cpld = '0;
//                 req.cnt_cplh = '0;
//                 req.cnt_pd = '0;
//                 req.cnt_npd = '0;
//                 req.cnt_ph = '0;
//                 req.cnt_nph = '0;

//                 if (cnt > 0) begin
//                     req.init_done = 1'b0;
//                     req.update[0] = 1'b1;
//                     req.cnt_ph = '1;
//                     req.update[1] = 1'b1;
//                     req.cnt_nph = '1;
//                     req.update[2] = 1'b1;
//                     req.cnt_cplh = '1;
//                     req.update[3] = 1'b1;
//                     req.cnt_pd = '1;
//                     req.update[4] = 1'b1;
//                     req.cnt_npd = '1;
//                     req.update[5] = 1'b1;
//                     req.cnt_cpld = '1;
//                     cnt--;
//                 end else begin
//                     req.init_done = 1'b1;
//                     req.update = '0;
//                     req.cnt_cpld = '0;
//                     req.cnt_cplh = '0;
//                     req.cnt_pd = '0;
//                     req.cnt_npd = '0;
//                     req.cnt_ph = '0;
//                     req.cnt_nph = '0;
//                     init = 1'b1;
//                 end
//                 finish_item(req);
//                 get_response(rsp);
//             end
//         end
//     endtask
// endclass