// sequence_set.sv Sequence generating user defined MI and data transactions
// Copyright (C) 2022 CESNET z. s. p. o.
// Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class fifo;
    int unsigned fifo[$];
    logic [128-1 : 0] hdr_fifo[$];
endclass

class sequence_mfb_data #(ITEM_WIDTH, TRANSACTION_COUNT, IS_XILINX_DEV) extends uvm_sequence #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH));

    `uvm_object_param_utils(uvm_pcie::sequence_mfb_data#(ITEM_WIDTH, TRANSACTION_COUNT, IS_XILINX_DEV))
    uvm_pcie::fifo size_fifo;
    uvm_pcie::fifo mvb_size_fifo;
    int unsigned len;
    logic [128-1 : 0] hdr;
    logic [ITEM_WIDTH-1 : 0] data [];

    // Constructor - creates new instance of this class
    function new(string name = "sequence_mfb_data");
        super.new(name);
    endfunction

    // In body you have to define how the MFB data will looks like
    task body;

        req = uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)::type_id::create("req");

        forever begin
            if (IS_XILINX_DEV) begin
                wait(size_fifo.fifo.size != 0 && size_fifo.hdr_fifo.size != 0);

                hdr = size_fifo.hdr_fifo.pop_front();

                void'(std::randomize(data) with 
                {
                    data.size == size_fifo.fifo.pop_front();
                });

                if (int'(hdr[75-1 : 64]) != data.size()) begin
                    `uvm_error(this.get_full_name(), $sformatf("Size in HDR %d does not match size of packet %d\n", int'(hdr[75-1 : 64]), data.size()));
                end

                req.data = new [data.size + 128/ITEM_WIDTH];
                req.data = {hdr[31 : 0], hdr[63 : 32], hdr[95 : 64], hdr[127 : 96], data};

                start_item(req);
                finish_item(req);
            end else begin
                wait(size_fifo.fifo.size != 0);
                `uvm_do_with(req, {data.size == size_fifo.fifo.pop_front(); });
            end
        end

    endtask

endclass

class sequence_meta #(META_WIDTH, TRANSACTION_COUNT) extends uvm_sequence #(uvm_logic_vector::sequence_item #(META_WIDTH));

    `uvm_object_param_utils(uvm_pcie::sequence_meta#(META_WIDTH, TRANSACTION_COUNT))
    uvm_pcie::fifo size_fifo;
    localparam IS_XILINX_DEV = 0;

    // Constructor - creates new instance of this class
    function new(string name = "sequence_meta");
        super.new(name);
    endfunction

    function uvm_logic_vector::sequence_item#(META_WIDTH) hdr_gen(logic[8-1 : 0] tag, logic[10-1 :0] len);

        uvm_down_hdr::sequence_item pcie_rq_hdr;
        uvm_logic_vector::sequence_item#(META_WIDTH) ret;

        ret = uvm_logic_vector::sequence_item#(META_WIDTH)::type_id::create("ret");
        ret.data = '0;
        pcie_rq_hdr = uvm_down_hdr::sequence_item::type_id::create("pcie_rq_hdr");

        void'(std::randomize(pcie_rq_hdr) with 
        {
            pcie_rq_hdr.dw_count == len;
            if (pcie_rq_hdr.dw_count == 1) {
                pcie_rq_hdr.fbe inside {4'b1001, 4'b0101, 4'b1010, 4'b0011, 4'b0110, 4'b1100, 4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0000};
                pcie_rq_hdr.lbe == 4'b0000;
            } else {
                pcie_rq_hdr.fbe inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
                pcie_rq_hdr.lbe inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            }
            if (IS_XILINX_DEV) {
                //                           MEM_READ     MEM_WRITE
                pcie_rq_hdr.req_type dist {8'b00000000 :/ 50, 8'b00000001 :/ 50};
            }
            else {
                // 4 DW Address
                if (|pcie_rq_hdr.addr[64-1 : 32]) {
                    //                           MEM_READ     MEM_WRITE
                    pcie_rq_hdr.req_type dist {8'b00100000 :/ 50, 8'b01100000 :/ 50};
                }
                // 3 DW Address
                else {
                    //               MEM_READ     MEM_WRITE
                    pcie_rq_hdr.req_type dist {8'b00000000 :/ 50, 8'b01000000 :/ 50};
                }
            }
            pcie_rq_hdr.addr[2-1 : 0] == 2'b00;
            pcie_rq_hdr.tag == tag;
        });

        // DW count
        ret.data[10-1 : 0]   = pcie_rq_hdr.dw_count;
        // $write("LEN %d\n", ret.data[10-1 : 0]);
        // ADDR TYPE
        ret.data[12-1 : 10]  = pcie_rq_hdr.addr[2-1 : 0];
        // ATTR[1 : 0] - {No Snoop, Relax}
        ret.data[14-1 : 12] = '0;
        // {EP, TD, TH, LN}
        ret.data[18-1 : 14] = '0;
        // ATTR[2] - ID-Based Ordering
        ret.data[19-1 : 18] = '0;
        // TAG 8
        ret.data[20-1 : 19] = '0;
        // TC
        ret.data[23-1 : 20] = pcie_rq_hdr.tc;
        // TAG 9
        ret.data[24-1 : 23] = '0;
        // TYPE
        ret.data[32-1 : 24] = pcie_rq_hdr.req_type;
        // FBE
        ret.data[36-1 : 32] = pcie_rq_hdr.fbe;
        // LBE
        ret.data[40-1 : 36] = pcie_rq_hdr.lbe;
        // TAG
        ret.data[48-1 : 40] = pcie_rq_hdr.tag;
        // REQ ID
        ret.data[64-1 : 48] = pcie_rq_hdr.req_id;
        if (|pcie_rq_hdr.addr[64-1 : 32]) begin
            ret.data[128-1 : 64] = {pcie_rq_hdr.addr[32-1 : 2], pcie_rq_hdr.addr[2-1 : 0], pcie_rq_hdr.addr[64-1 : 32]};
        end else
            ret.data[128-1 : 64] = {32'h0000, pcie_rq_hdr.addr[2-1 : 0], pcie_rq_hdr.addr[32-1 : 2]};

        return ret;

    endfunction

    // -----------------------
    // Functions.
    // -----------------------

    // Generates transactions
    task body;

        logic [8-1 : 0] tag = 0;

        req = uvm_logic_vector::sequence_item#(META_WIDTH)::type_id::create("req");

        repeat(TRANSACTION_COUNT) begin
            // wait(size_fifo.fifo.size != 0);

            req = hdr_gen(tag, 1);
            start_item(req);
            finish_item(req);
            tag++;
        end

    endtask

endclass

class sequence_mvb #(META_WIDTH, DMA_PORTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH) extends uvm_sequence #(uvm_logic_vector::sequence_item #(META_WIDTH));

    `uvm_object_param_utils(uvm_pcie::sequence_mvb#(META_WIDTH, DMA_PORTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH))
    uvm_pcie::fifo size_fifo;
    localparam PORTS_W_FIX = (DMA_PORTS > 1) ? $clog2(DMA_PORTS) : 1;
    logic [PORTS_W_FIX-1 : 0] port;
    uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man;

    // Constructor - creates new instance of this class
    function new(string name = "sequence_mvb");
        super.new(name);
    endfunction

    function uvm_logic_vector::sequence_item#(META_WIDTH) hdr_gen(logic [8-1 : 0] tag, logic[sv_dma_bus_pack::DMA_REQUEST_LENGTH_W-1 :0] len);

        uvm_down_hdr::dma_up_sequence_item dma_up_hdr;
        uvm_logic_vector::sequence_item#(META_WIDTH) ret;

        ret        = uvm_logic_vector::sequence_item#(META_WIDTH)::type_id::create("ret");
        dma_up_hdr = uvm_down_hdr::dma_up_sequence_item::type_id::create("dma_up_hdr");
        ret.data = '0;

        void'(std::randomize(dma_up_hdr) with {
            dma_up_hdr.req_type dist {1'b0 :/ 50, 1'b1 :/ 50};
            dma_up_hdr.unitid == 8'b00000000;
            dma_up_hdr.tag         == tag;
            dma_up_hdr.packet_size inside {[1 : 128]};
            if (DMA_PORTS > 1) {
                dma_up_hdr.tag[sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : sv_dma_bus_pack::DMA_REQUEST_TAG_W-PORTS_W_FIX] == port;
            }
        });

        if (dma_up_hdr.req_type == 1'b1) begin
            size_fifo.fifo.push_back(dma_up_hdr.packet_size);
        end else
            tag_man.add_element(dma_up_hdr.tag);

        if (DMA_PORTS > 1) begin
            dma_up_hdr.vfid = {dma_up_hdr.vfid[8-1 : PORTS_W_FIX], port};
        end


        ret.data = {dma_up_hdr.relaxed, dma_up_hdr.pasidvld, dma_up_hdr.pasid, dma_up_hdr.vfid, dma_up_hdr.global_id, dma_up_hdr.unitid, dma_up_hdr.tag, dma_up_hdr.lastib, dma_up_hdr.firstib, dma_up_hdr.req_type, dma_up_hdr.packet_size};

        return ret;

    endfunction

    // -----------------------
    // Functions.
    // -----------------------

    // Generates transactions
    task body;

        logic [8-1 : 0] tag = 0;
        int unsigned delay;

        req = uvm_logic_vector::sequence_item#(META_WIDTH)::type_id::create("req");

        repeat(TRANSACTION_COUNT) begin
            void'(std::randomize(delay) with {
                delay inside {[0 : 50]};
            });

            req = hdr_gen(tag, 0);
            start_item(req);
            finish_item(req);
            #(delay * 1ns);
            tag++;
        end
    endtask

endclass


class sequence_avst_down_meta #(META_WIDTH, TRANSACTION_COUNT, IS_XILINX_DEV, PCIE_TAG_WIDTH) extends uvm_sequence #(uvm_logic_vector::sequence_item #(META_WIDTH));

    `uvm_object_param_utils(uvm_pcie::sequence_avst_down_meta#(META_WIDTH, TRANSACTION_COUNT, IS_XILINX_DEV, PCIE_TAG_WIDTH))
    int unsigned write_cnt;
    int unsigned read_cnt;
    uvm_down_hdr::sequence_item avst_down_hdr;
    uvm_pcie::fifo size_fifo;

    // Constructor - creates new instance of this class
    function new(string name = "sequence_avst_down_meta");
        super.new(name);
        write_cnt = 0;
        read_cnt  = 0;
    endfunction


    typedef struct {
        uvm_logic_vector::sequence_item#(128) hdr;
        logic[META_WIDTH-1 : 0]               user;
    } pcie;

    // -----------------------
    // Functions.
    // -----------------------
    function pcie hdr_gen(logic[8-1 : 0] tag, logic[11-1 :0] len);

        pcie             ret;
        logic [32-1 : 0] prefix;
        logic [3-1 : 0]  encoded_type;

        ret.hdr       = uvm_logic_vector::sequence_item#(128)::type_id::create("ret");
        avst_down_hdr = uvm_down_hdr::sequence_item::type_id::create("avst_down_hdr");
        void'(std::randomize(avst_down_hdr) with 
        {
            // avst_down_hdr.dw_count == len;
            if (avst_down_hdr.dw_count == 1) {
                avst_down_hdr.fbe inside {4'b1001, 4'b0101, 4'b1010, 4'b0011, 4'b0110, 4'b1100, 4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0000};
                avst_down_hdr.lbe == 4'b0000;
            } else {
                avst_down_hdr.fbe inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
                avst_down_hdr.lbe inside {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            }
            if (IS_XILINX_DEV) {
                //                           MEM_READ     MEM_WRITE
                avst_down_hdr.req_type dist {8'b00000000 :/ 90, 8'b00000001 :/ 90,
                // Others (errors)
                8'b00000010 :/ 10, 8'b00000011 :/ 10, 8'b00000100 :/ 10, 8'b00000101 :/ 10, 8'b00000110 :/ 10, 8'b00000111 :/ 10, 8'b00001000 :/ 10, 8'b00001001 :/ 10, 8'b00001010 :/ 10, 8'b00001011 :/ 10, 8'b00001100 :/ 10, 8'b00001101 :/ 10, 8'b00001110 :/ 10};
            }
            else {
                // 4 DW Address
                if (|avst_down_hdr.addr[64-1 : 32]) {
                    //                           MEM_READ     MEM_WRITE
                    avst_down_hdr.req_type dist {8'b00100000 :/ 90, 8'b01100000 :/ 90,
                    // MSG
                    8'b00110000 :/ 10, 8'b00110001 :/ 10, 8'b00110010 :/ 10, 8'b00110011 :/ 10, 8'b00110100 :/ 10, 8'b00110101 :/ 10,
                    // MSGd
                    8'b01110000 :/ 10, 8'b01110001 :/ 10, 8'b01110010 :/ 10, 8'b01110011 :/ 10, 8'b01110100 :/ 10, 8'b01110101 :/ 10 };
                }
                // 3 DW Address
                else {
                    //               MEM_READ     MEM_WRITE
                    avst_down_hdr.req_type dist {8'b00000000 :/ 90, 8'b01000000 :/ 90};
                }
            }

            if (avst_down_hdr.req_type == 8'b00100000 || avst_down_hdr.req_type == 8'b00000000) {
                avst_down_hdr.dw_count inside {[1 : 32]};
            } else {
                avst_down_hdr.dw_count inside {[1 : 128]};
            }
            avst_down_hdr.bar == 3'b000;
            avst_down_hdr.bar_ap == 6'd24;
            avst_down_hdr.addr[2-1 : 0] == 2'b00;
            avst_down_hdr.tag == tag;
        });

        encoded_type = uvm_down_hdr::encode_type(avst_down_hdr.req_type, 1'b1);

        if (IS_XILINX_DEV) begin
            size_fifo.fifo.push_back(avst_down_hdr.dw_count);
        end else begin
            if (encoded_type == 3'b000) begin
                size_fifo.fifo.push_back(1);
            end else begin
                size_fifo.fifo.push_back(avst_down_hdr.dw_count);
            end
        end

        void'(std::randomize(prefix));

        ret.hdr.data = '0;
        ret.user     = '0;
        if (IS_XILINX_DEV) begin
            // In case of Xilinx
            // ADDR
            ret.hdr.data[63 : 0] = avst_down_hdr.addr;
            // pcie length in DWORDS
            ret.hdr.data[74 : 64]   = avst_down_hdr.dw_count; 
            // REQ TYPE
            ret.hdr.data[78 : 75]   = avst_down_hdr.req_type[4-1 : 0];
            // REQ ID
            ret.hdr.data[95 : 80]   = avst_down_hdr.req_id;
            // TAG
            ret.hdr.data[103 : 96]  = avst_down_hdr.tag;
            // Target Function
            ret.hdr.data[111 : 104] = '0;
            // BAR ID
            ret.hdr.data[114 : 112] = avst_down_hdr.bar;
            // BAR Aperure
            ret.hdr.data[120 : 115] = avst_down_hdr.bar_ap;
            // TC
            ret.hdr.data[123 : 121] = avst_down_hdr.tc;
            // ATTR
            ret.hdr.data[126 : 124] = '0;

            // // FBE
            // ret.user[39-1 : 35] = avst_down_hdr.fbe;
            // // LBE
            // ret.user[43-1 : 39] = avst_down_hdr.lbe;
            // // TPH_PRESENT
            // ret.user[44-1 : 43] = '0;
            // // TPH TYPE
            // ret.user[46-1 : 44] = '0;
            // // TPH_ST_TAG
            // ret.user[54-1 : 46] = '0;
        end else begin
            // DW count
            ret.hdr.data[10-1 : 0]  = avst_down_hdr.dw_count;
            // $write("LEN %d\n", ret.data[10-1 : 0]);
            // ADDR TYPE
            ret.hdr.data[12-1 : 10] = avst_down_hdr.addr[2-1 : 0];
            // ATTR[1 : 0] - {No Snoop, Relax}
            ret.hdr.data[14-1 : 12] = '0;
            // {EP, TD, TH, LN}
            ret.hdr.data[18-1 : 14] = '0;
            // ATTR[2] - ID-Based Ordering
            ret.hdr.data[19-1 : 18] = '0;
            // TAG 8
            ret.hdr.data[20-1 : 19] = '0;
            // TC
            ret.hdr.data[23-1 : 20] = avst_down_hdr.tc;
            // TAG 9
            ret.hdr.data[24-1 : 23] = '0;
            // TYPE
            ret.hdr.data[32-1 : 24] = avst_down_hdr.req_type;
            // FBE
            ret.hdr.data[36-1 : 32] = avst_down_hdr.fbe;
            // LBE
            ret.hdr.data[40-1 : 36] = avst_down_hdr.lbe;
            // TAG
            ret.hdr.data[48-1 : 40] = avst_down_hdr.tag;
            // REQ ID
            ret.hdr.data[64-1 : 48] = avst_down_hdr.req_id;
            if (|avst_down_hdr.addr[64-1 : 32]) begin
                ret.hdr.data[128-1 : 64] = {avst_down_hdr.addr[32-1 : 2], avst_down_hdr.addr[2-1 : 0], avst_down_hdr.addr[64-1 : 32]};
            end else
                ret.hdr.data[128-1 : 64] = {32'h0000, avst_down_hdr.addr[2-1 : 0], avst_down_hdr.addr[32-1 : 2]};

            ret.hdr.data = {ret.hdr.data[31 : 0], ret.hdr.data[63 : 32], ret.hdr.data[95 : 64], ret.hdr.data[127 : 96]};
        end

        return ret;

    endfunction

    // -----------------------
    // Functions.
    // -----------------------

    // Generates transactions
    task body;

        logic [PCIE_TAG_WIDTH-1 : 0] tag = 0;
        int unsigned                 delay;
        pcie                         s_pcie;

        req = uvm_logic_vector::sequence_item#(META_WIDTH)::type_id::create("req");

        repeat(TRANSACTION_COUNT) begin
            s_pcie = hdr_gen(tag, 0);
            if (IS_XILINX_DEV) begin
                size_fifo.hdr_fifo.push_back(s_pcie.hdr.data);
                // req.data = s_pcie.user;
                // $write("req.data %h\n", req.data);
                // start_item(req);
                // finish_item(req);
            end else begin
                void'(std::randomize(delay) with {
                    delay inside {[0 : 50]};
                });
                req.data = s_pcie.hdr.data;

                start_item(req);
                finish_item(req);
                #(delay * 1ns);
            end
            tag++;
        end

    endtask

endclass