//-- reg_sequnece.sv: Virtual sequence
//-- Copyright (C) 2024 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

class read_rx_counters#(RX_MAC_COUNT) extends uvm_sequence;
    `uvm_object_param_utils(uvm_network_mod_env::read_rx_counters#(RX_MAC_COUNT))

    uvm_rx_mac_lite::regmodel#(RX_MAC_COUNT) regmodel;
    logic [64-1:0] trfc;
    logic [64-1:0] cfc;
    logic [64-1:0] dfc;
    logic [64-1:0] bodfc;
    logic [64-1:0] oroc;

    function new(string name = "mi_sequence");
        super.new(name);
    endfunction


    virtual task reset();
        uvm_status_e  status_cmd;
        regmodel.command.write(status_cmd, 'h2);
    endtask


    virtual task body();
        uvm_status_e   status_cmd;
        regmodel.command.write(status_cmd, 'h1);

        fork
            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.trfcl.read(status, data);
                trfc[32-1:0] = data;
                regmodel.trfch.read(status, data);
                trfc[64-1:32] = data;
            end
            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.cfcl.read(status, data);
                cfc[32-1:0] = data;
                regmodel.cfch.read(status, data);
                cfc[64-1:32] = data;
            end

            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.dfcl.read(status, data);
                dfc[32-1:0] = data;
                regmodel.dfch.read(status, data);
                dfc[64-1:32] = data;
            end

            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.bodfcl.read(status, data);
                bodfc[32-1:0] = data;
                regmodel.bodfch.read(status, data);
                bodfc[64-1:32] = data;
            end

            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.orocl.read(status, data);
                oroc[32-1:0] = data;
                regmodel.oroch.read(status, data);
                oroc[64-1:32] = data;
            end
        join
    endtask

    function void set_regmodel(uvm_rx_mac_lite::regmodel#(RX_MAC_COUNT) model);
        regmodel = model;
    endfunction
endclass


class read_tx_counters extends uvm_sequence;
    `uvm_object_param_utils(uvm_network_mod_env::read_tx_counters)

    uvm_tx_mac_lite::regmodel regmodel;
    logic [64-1:0] tfc;
    logic [64-1:0] soc;
    logic [64-1:0] dfc;
    logic [64-1:0] sfc;

    function new(string name = "mi_sequence");
        super.new(name);
    endfunction

    virtual task reset();
        uvm_status_e  status_cmd;
        regmodel.command.write(status_cmd, 'h2);
    endtask

    virtual task body();
        uvm_status_e   status_cmd;
        regmodel.command.write(status_cmd, 'h1);

        fork
            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.tfcl.read(status, data);
                tfc[32-1:0] = data;
                regmodel.tfch.read(status, data);
                tfc[64-1:32] = data;
            end
            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.socl.read(status, data);
                soc[32-1:0] = data;
                regmodel.soch.read(status, data);
                soc[64-1:32] = data;
            end

            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.dfcl.read(status, data);
                dfc[32-1:0] = data;
                regmodel.dfch.read(status, data);
                dfc[64-1:32] = data;
            end

            begin
                uvm_status_e   status;
                uvm_reg_data_t data;
                regmodel.sfcl.read(status, data);
                sfc[32-1:0] = data;
                regmodel.sfch.read(status, data);
                sfc[64-1:32] = data;
            end
        join
    endtask

    function void set_regmodel(uvm_tx_mac_lite::regmodel model);
        regmodel = model;
    endfunction
endclass

