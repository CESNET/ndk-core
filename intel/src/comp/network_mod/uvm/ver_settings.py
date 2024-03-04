# ver_settings.py
# Copyright (C) 2023 CESNET z. s. p. o.
# Author(s): Daniel Kříž <danielkriz@cesnet.cz>

SETTINGS = {
    "default" : { # The default setting of verification is 512b and STRATIX with P_TILE
        "ETH_CORE_ARCH"                  :  "E_TILE",
        "ETH_PORTS"                      :  "2",
#        "ETH_PORT_SPEED[ETH_PORTS-1:0]"  : "'{ETH_PORTS{100}}",
#        "ETH_PORT_CHAN[ETH_PORTS-1:0]"   : "'{ETH_PORTS{1}}",
#        "EHIP_PORT_TYPE[ETH_PORTS-1:0]"  : "'{ETH_PORTS{0}}",
#        "ETH_PORT_RX_MTU[ETH_PORTS-1:0]" : "'{ETH_PORTS{16383}}",
#        "ETH_PORT_TX_MTU[ETH_PORTS-1:0]" : "'{ETH_PORTS{16383}}",
#        "LANES"                          : "4",
#        "QSFP_PORTS"                     : "2",
#        "QSFP_I2C_PORTS"                 : "1",
#        "QSFP_I2C_TRISTATE"              : "1'b1",
        "REGIONS"                        : "1",
        "REGION_SIZE"                    : "8",
        "BLOCK_SIZE"                     : "8",
        "ITEM_WIDTH"                     : "8",
        "DEVICE"                         : "\\\"AGILEX\\\"", # "STRATIX10";
        "BOARD"                          : "\\\"N6010\\\"",  # "DK-DEV-1SDX-P";

        "PACKET_SIZE_MIN"                : "64",
        "PACKET_SIZE_MAX"                : "1500",

        "__core_params__": {"UVM_TEST": "test::base"},
    },

    "test_speed" : {
        "__core_params__": {"UVM_TEST": "test::speed"},
    },

    "large_packets" : {
        "PACKET_SIZE_MIN"                : "12000",
        "PACKET_SIZE_MAX"                : "16384-1",
    },

    "small_packets" : {
        "PACKET_SIZE_MIN"                : "64",
        "PACKET_SIZE_MAX"                : "128",
    },

    "_combinations_" : {
        "test_default"    : (), # Works the same as '("default",),' as the "default" is applied in every combination
        "test_large_packet" : ("large_packets",),
        "test_small_packets" : ("small_packets",),

        "test_speed_large_packet"  : ("small_packets", "test_speed", ),
        "test_speed_small_packets" : ("test_speed", ),
    },
}

