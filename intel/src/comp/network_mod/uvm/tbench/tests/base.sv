//-- base.sv: basig test
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause


class base#(
    string       ETH_CORE_ARCH    ,
    int unsigned ETH_PORTS        ,
    int unsigned ETH_PORT_SPEED[ETH_PORTS-1:0],

    int unsigned ETH_PORT_CHAN[ETH_PORTS-1:0]    ,
    int unsigned EHIP_PORT_TYPE[ETH_PORTS-1:0]   ,
    int unsigned ETH_PORT_RX_MTU[ETH_PORTS-1:0]  ,
    int unsigned ETH_PORT_TX_MTU[ETH_PORTS-1:0]  ,
    int unsigned LANES            ,
    int unsigned QSFP_PORTS       ,
    int unsigned QSFP_I2C_PORTS   ,
    int unsigned QSFP_I2C_TRISTATE,

    int unsigned ETH_TX_HDR_WIDTH,
    int unsigned ETH_RX_HDR_WIDTH,

    int unsigned REGIONS          ,
    int unsigned REGION_SIZE      ,
    int unsigned BLOCK_SIZE       ,
    int unsigned ITEM_WIDTH       ,

    int unsigned MI_DATA_WIDTH    ,
    int unsigned MI_ADDR_WIDTH    ,

    int unsigned MI_DATA_WIDTH_PHY,
    int unsigned MI_ADDR_WIDTH_PHY,

    int unsigned LANE_RX_POLARITY ,
    int unsigned LANE_TX_POLARITY ,
    int unsigned RESET_WIDTH      ,
    string DEVICE           ,
    string BOARD
) extends uvm_test;
    typedef uvm_component_registry#(test::base#(ETH_CORE_ARCH, ETH_PORTS, ETH_PORT_SPEED, ETH_PORT_CHAN, EHIP_PORT_TYPE, ETH_PORT_RX_MTU, ETH_PORT_TX_MTU, LANES, QSFP_PORTS,
                            QSFP_I2C_PORTS, QSFP_I2C_TRISTATE, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, MI_DATA_WIDTH,
                            MI_ADDR_WIDTH, MI_DATA_WIDTH_PHY, MI_ADDR_WIDTH_PHY, LANE_RX_POLARITY, LANE_TX_POLARITY, RESET_WIDTH, DEVICE, BOARD), "test::base") type_id;

    uvm_network_mod_env::env#(ETH_CORE_ARCH, ETH_PORTS, ETH_PORT_SPEED, ETH_PORT_CHAN, EHIP_PORT_TYPE, ETH_PORT_RX_MTU, ETH_PORT_TX_MTU, LANES, QSFP_PORTS,
                            QSFP_I2C_PORTS, QSFP_I2C_TRISTATE, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, MI_DATA_WIDTH,
                            MI_ADDR_WIDTH, MI_DATA_WIDTH_PHY, MI_ADDR_WIDTH_PHY, LANE_RX_POLARITY, LANE_TX_POLARITY, RESET_WIDTH, DEVICE, BOARD) m_env;
    localparam time timeout_max = 200us;

    // ------------------------------------------------------------------------
    // Functions
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    static function type_id get_type();
        return type_id::get();
    endfunction

    function string get_type_name();
        return get_type().get_type_name();
    endfunction

    function void build_phase(uvm_phase phase);
        m_env = uvm_network_mod_env::env#(ETH_CORE_ARCH, ETH_PORTS, ETH_PORT_SPEED, ETH_PORT_CHAN, EHIP_PORT_TYPE, ETH_PORT_RX_MTU, ETH_PORT_TX_MTU, LANES, QSFP_PORTS,
                            QSFP_I2C_PORTS, QSFP_I2C_TRISTATE, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, MI_DATA_WIDTH,
                            MI_ADDR_WIDTH, MI_DATA_WIDTH_PHY, MI_ADDR_WIDTH_PHY, LANE_RX_POLARITY, LANE_TX_POLARITY, RESET_WIDTH, DEVICE, BOARD)::type_id::create("m_env", this);
    endfunction

    // ------------------------------------------------------------------------
    // Create environment and Run sequences o their sequencers
    virtual task run_phase(uvm_phase phase);
        time time_start;
        uvm_network_mod_env::virt_sequence_simple#(ETH_PORTS, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, ITEM_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ETH_PORT_CHAN, MI_DATA_WIDTH, MI_ADDR_WIDTH) seq;
        uvm_network_mod_env::virt_sequence_stop#(ETH_PORTS, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, ITEM_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ETH_PORT_CHAN, MI_DATA_WIDTH, MI_ADDR_WIDTH)   seq_stop;

        seq = uvm_network_mod_env::virt_sequence_simple#(ETH_PORTS, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, ITEM_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ETH_PORT_CHAN, MI_DATA_WIDTH, MI_ADDR_WIDTH)::type_id::create("sequence", m_env.m_sequencer);
        assert(seq.randomize());

        //RISE OBJECTION
        phase.raise_objection(this);

        seq.start(m_env.m_sequencer);

        seq_stop = uvm_network_mod_env::virt_sequence_stop#(ETH_PORTS, ETH_TX_HDR_WIDTH, ETH_RX_HDR_WIDTH, ITEM_WIDTH, REGIONS, REGION_SIZE, BLOCK_SIZE, ETH_PORT_CHAN, MI_DATA_WIDTH, MI_ADDR_WIDTH)::type_id::create("sequence", m_env.m_sequencer);
        assert(seq_stop.randomize());

        fork
            seq_stop.start(m_env.m_sequencer);
        join_none

        ///////////////////
        // Wait to end
        time_start = $time();
        while((time_start + timeout_max) > $time() && m_env.used()) begin
            #(300ns);
        end

        if ((time_start + timeout_max) < $time()) begin
            `uvm_warning(this.get_full_name(), $sformatf("TIMEOUT exeed %0dns ", ($time() - time_start)/1ns));
        end
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info(this.get_full_name(), {"\n\tTEST : ", this.get_type_name(), " END\n"}, UVM_NONE);
    endfunction

endclass

