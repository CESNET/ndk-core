// env.sv: Environment for Intel R-Tile device
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class env #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, AVST_DOWN_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, AVST_UP_META_W) extends uvm_pcie_intel::env #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, AVST_DOWN_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, AVST_UP_META_W);
    `uvm_component_param_utils(uvm_pcie_intel_r_tile::env #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, AVST_DOWN_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, AVST_UP_META_W));

    uvm_avst_crdt::agent_rx m_avst_crdt_up;
    uvm_avst_crdt::agent_tx m_avst_crdt_down;

    transaction_approver m_transaction_approver;
    transaction_checker #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, ITEM_WIDTH, AVST_UP_META_W, 3) m_transaction_checker;
    valuer #(AVST_UP_META_W) m_valuer;

    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        uvm_pcie::config_item m_config;

        uvm_avst_crdt::config_item m_avst_crdt_up_cfg;
        uvm_avst_crdt::config_item m_avst_crdt_down_cfg;

        if(!uvm_config_db #(uvm_pcie::config_item)::get(this, "", "m_config", m_config)) begin
            `uvm_fatal(this.get_full_name(), "\n\tUnable to get configuration object");
        end

        uvm_pcie_intel::driver::type_id::set_inst_override(uvm_pcie_intel_r_tile::driver::get_type(), "m_driver", this);
        uvm_avst_crdt::sequencer::type_id::set_inst_override(uvm_pcie_intel_r_tile::sequencer::get_type(), "m_avst_crdt_up.m_sequencer", this);

        super.build_phase(phase);

        m_avst_crdt_up_cfg = new();
        m_avst_crdt_up_cfg.active = UVM_ACTIVE;
        m_avst_crdt_up_cfg.interface_name = {m_config.interface_name, "_crdt_up"};
        uvm_config_db #(uvm_avst_crdt::config_item)::set(this, "m_avst_crdt_up", "m_config", m_avst_crdt_up_cfg);
        m_avst_crdt_up = uvm_avst_crdt::agent_rx::type_id::create("m_avst_crdt_up", this);

        m_avst_crdt_down_cfg = new();
        m_avst_crdt_down_cfg.active = UVM_ACTIVE;
        m_avst_crdt_down_cfg.interface_name = {m_config.interface_name, "_crdt_down"};
        uvm_config_db #(uvm_avst_crdt::config_item)::set(this, "m_avst_crdt_down", "m_config", m_avst_crdt_down_cfg);
        m_avst_crdt_down = uvm_avst_crdt::agent_tx::type_id::create("m_avst_crdt_down", this);

        m_transaction_approver = transaction_approver::type_id::create("m_transaction_approver", this);
        m_valuer = valuer #(AVST_UP_META_W)::type_id::create("m_valuer", this);
        
        // THE CURRENT IMPLEMENTATION OF PCIE-TOP DOES NOT TAKE INTO ACCOUNT UP-SIDE CREDITS SENT FROM VERIFICATION
        // UNCOMMENT BELOW IF YOU WANT TO ENABLE CHECKING OF THIS FEATURE
        // m_transaction_checker = transaction_checker #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, ITEM_WIDTH, AVST_UP_META_W, 3)::type_id::create("m_transaction_checker", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        sequencer cast_sequencer;

        super.connect_phase(phase);

        reset_sync.push_back(m_avst_crdt_up.reset_sync);

        // Approver on DOWN
        m_avst_crdt_down.analysis_port.connect(m_transaction_approver.avst_crdt_in.analysis_export);
        uvm_config_db #(mailbox #(credit_item))::set(this, "m_driver", "mailbox", m_transaction_approver.m_mailbox);
        uvm_config_db #(event)                 ::set(this, "m_driver", "approve", m_transaction_approver.approve);

        // THE CURRENT IMPLEMENTATION OF PCIE-TOP DOES NOT TAKE INTO ACCOUNT UP-SIDE CREDITS SENT FROM VERIFICATION
        // UNCOMMENT BELOW IF YOU WANT TO ENABLE CHECKING OF THIS FEATURE
        // // Checker on UP
        // m_avst_up.m_avst_agent.analysis_port.connect(m_transaction_checker.avst_in.analysis_export);
        // m_avst_crdt_up.analysis_port.connect(m_transaction_checker.avst_crdt_in.analysis_export);

        // Sequence returning the credits on UP
        m_avst_up.analysis_port_meta.connect(m_valuer.analysis_export);
        assert($cast(cast_sequencer, m_avst_crdt_up.m_sequencer))
        else begin
            `uvm_fatal(this.get_full_name(), "\n\tCast failed")
        end
        m_valuer.analysis_port.connect(cast_sequencer.credit_fifo_in.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        // Credit initialization sequences
        uvm_avst_crdt::sequence_stop m_crdt_up_sequence_init;
        uvm_avst_crdt::sequence_stop m_crdt_down_sequence_init;

        // Credit transaction sequences
        //uvm_avst_crdt::sequence_simple m_crdt_up_sequence;
        sequence_returning m_crdt_up_sequence_returning;
        uvm_avst_crdt::sequence_simple m_crdt_down_sequence;

        // AVST sequences
        uvm_pcie_intel::sequence_data                     seq_data;
        uvm_pcie_intel::sequence_meta #(AVST_DOWN_META_W) seq_meta;
        uvm_avst::sequence_lib_tx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, ITEM_WIDTH, AVST_UP_META_W) seq_up_rdy;
        
        m_crdt_up_sequence_init   = uvm_avst_crdt::sequence_stop::type_id::create("m_crdt_up_sequence_init");
        m_crdt_down_sequence_init = uvm_avst_crdt::sequence_stop::type_id::create("m_crdt_down_sequence_init");

        //m_crdt_up_sequence = uvm_avst_crdt::sequence_simple::type_id::create("m_crdt_up_sequence",);
        m_crdt_up_sequence_returning = sequence_returning::type_id::create("m_crdt_up_sequence_returning");
        m_crdt_down_sequence = uvm_avst_crdt::sequence_simple::type_id::create("m_crdt_down_sequence");

        seq_data = uvm_pcie_intel::sequence_data::type_id::create("seq_data");
        assert(seq_data.randomize())
        else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot randomize data sequence")
        end

        seq_meta = uvm_pcie_intel::sequence_meta #(AVST_DOWN_META_W)::type_id::create("seq_meta");
        assert(seq_meta.randomize())
        else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot randomize meta sequence")
        end

        seq_up_rdy = uvm_avst::sequence_lib_tx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, ITEM_WIDTH, AVST_UP_META_W)::type_id::create("seq_up_rdy");
        seq_up_rdy.init_sequence();
        seq_up_rdy.min_random_count = 100;
        seq_up_rdy.max_random_count = 200;

        // Credit initialization
        fork
            begin
                assert(m_crdt_up_sequence_init.randomize());
                m_crdt_up_sequence_init.start(m_avst_crdt_up.m_sequencer);
            end
            begin
                assert(m_crdt_down_sequence_init.randomize());
                m_crdt_down_sequence_init.start(m_avst_crdt_down.m_sequencer);
            end
        join

        // Credit transactions
        fork
            forever begin
                assert(m_crdt_up_sequence_returning.randomize());
                m_crdt_up_sequence_returning.start(m_avst_crdt_up.m_sequencer);
            end
            forever begin
                assert(m_crdt_down_sequence.randomize());
                m_crdt_down_sequence.start(m_avst_crdt_down.m_sequencer);
            end
        join_none;

        // AVST data/meta transactions
        fork
            seq_data.start(m_avst_down.m_sequencer.m_data);
            seq_meta.start(m_avst_down.m_sequencer.m_meta);

            forever begin
                assert(seq_up_rdy.randomize());
                seq_up_rdy.start(m_avst_up.m_sequencer);
            end
        join;
    endtask

endclass
