# ver_settings.py
# Copyright (C) 2023 CESNET z. s. p. o.
# Author(s): Daniel Kříž <danielkriz@cesnet.cz>

SETTINGS = {
    "default" : { # The default setting of verification is 512b and STRATIX with P_TILE
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,

        "CQ_MFB_REGIONS"       : "2"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "CC_MFB_REGIONS"       : "2"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,

        "AXI_CQUSER_WIDTH"     : "183"               ,
        "AXI_CCUSER_WIDTH"     : "81"                ,
        "AXI_RQUSER_WIDTH"     : "137"               ,
        "AXI_RCUSER_WIDTH"     : "161"               ,
        "AXI_STRADDLING"       : "0"                 ,

        "DMA_PORTS"            : 1,
        "PCIE_ENDPOINT_MODE"   : 0,
        "PCIE_ENDPOINTS"       : 1,
        "PCIE_CONS"            : 1,

        "DEVICE"               : "\\\"AGILEX\\\"" ,
        "PCIE_ENDPOINT_TYPE"   : "\\\"P_TILE\\\""    ,
        "__core_params__"          : {"PCIE_TYPE" : "P_TILE"},
    },
    "intel_p_tile" : {
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,

        "CQ_MFB_REGIONS"       : "2"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "CC_MFB_REGIONS"       : "2"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,

        "PCIE_ENDPOINT_MODE"   : 0,
        "PCIE_ENDPOINTS"       : 1,
        "PCIE_CONS"            : 1,

        "DEVICE"               : "\\\"AGILEX\\\"" ,
        "PCIE_ENDPOINT_TYPE"   : "\\\"P_TILE\\\""    ,
        "__core_params__"          : {"PCIE_TYPE" : "P_TILE"},
    },
    "intel_p_tile_bifur" : {
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,

        "CQ_MFB_REGIONS"       : "1"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "CC_MFB_REGIONS"       : "1"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,

        "PCIE_ENDPOINT_MODE"   : 1,
        "PCIE_ENDPOINTS"       : 2,
        "PCIE_CONS"            : 1,

        "DEVICE"               : "\\\"AGILEX\\\"" ,
        "PCIE_ENDPOINT_TYPE"   : "\\\"P_TILE\\\""    ,
        "__core_params__"          : {"PCIE_TYPE" : "P_TILE"},
    },
    "intel_p_tile_bifur2" : {
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,

        "CQ_MFB_REGIONS"       : "1"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "CC_MFB_REGIONS"       : "1"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,

        "PCIE_ENDPOINT_MODE"   : 1,
        "PCIE_ENDPOINTS"       : 4,
        "PCIE_CONS"            : 2,

        "DEVICE"               : "\\\"AGILEX\\\"" ,
        "PCIE_ENDPOINT_TYPE"   : "\\\"P_TILE\\\""    ,
        "__core_params__"          : {"PCIE_TYPE" : "P_TILE"},
    },

    "intel_r_tile" : {
        "RQ_MFB_REGIONS"       : "2",
        "RQ_MFB_REGION_SIZE"   : "1",
        "RQ_MFB_BLOCK_SIZE"    : "8",

        "RC_MFB_REGIONS"       : "2",
        "RC_MFB_REGION_SIZE"   : "1",
        "RC_MFB_BLOCK_SIZE"    : "8",

        "CQ_MFB_REGIONS"       : "4",
        "CQ_MFB_REGION_SIZE"   : "1",
        "CQ_MFB_BLOCK_SIZE"    : "8",

        "CC_MFB_REGIONS"       : "4",
        "CC_MFB_REGION_SIZE"   : "1",
        "CC_MFB_BLOCK_SIZE"    : "8",

        "PCIE_ENDPOINT_MODE"   : 0,
        "PCIE_ENDPOINTS"       : 1,
        "PCIE_CONS"            : 1,

        "DEVICE"               : "\\\"AGILEX\\\"",
        "PCIE_ENDPOINT_TYPE"   : "\\\"R_TILE\\\"",
        "__core_params__"      : {"PCIE_TYPE" : "R_TILE"},
    },
    "intel_r_tile_bifur" : {
        "RQ_MFB_REGIONS"       : "4",
        "RQ_MFB_REGION_SIZE"   : "1",
        "RQ_MFB_BLOCK_SIZE"    : "8",

        "RC_MFB_REGIONS"       : "4",
        "RC_MFB_REGION_SIZE"   : "1",
        "RC_MFB_BLOCK_SIZE"    : "8",

        "CQ_MFB_REGIONS"       : "4",
        "CQ_MFB_REGION_SIZE"   : "1",
        "CQ_MFB_BLOCK_SIZE"    : "8",

        "CC_MFB_REGIONS"       : "4",
        "CC_MFB_REGION_SIZE"   : "1",
        "CC_MFB_BLOCK_SIZE"    : "8",

        "PCIE_ENDPOINT_MODE"   : 1,
        "PCIE_ENDPOINTS"       : 2,
        "PCIE_CONS"            : 1,

        "DEVICE"               : "\\\"AGILEX\\\"",
        "PCIE_ENDPOINT_TYPE"   : "\\\"R_TILE\\\"",
        "__core_params__"      : {"PCIE_TYPE" : "R_TILE"},
    },
    "intel_r_tile_bifur2" : {
        "RQ_MFB_REGIONS"       : "4",
        "RQ_MFB_REGION_SIZE"   : "1",
        "RQ_MFB_BLOCK_SIZE"    : "8",

        "RC_MFB_REGIONS"       : "4",
        "RC_MFB_REGION_SIZE"   : "1",
        "RC_MFB_BLOCK_SIZE"    : "8",

        "CQ_MFB_REGIONS"       : "4",
        "CQ_MFB_REGION_SIZE"   : "1",
        "CQ_MFB_BLOCK_SIZE"    : "8",

        "CC_MFB_REGIONS"       : "4",
        "CC_MFB_REGION_SIZE"   : "1",
        "CC_MFB_BLOCK_SIZE"    : "8",

        "PCIE_ENDPOINT_MODE"   : 1,
        "PCIE_ENDPOINTS"       : 4,
        "PCIE_CONS"            : 2,

        "DEVICE"               : "\\\"AGILEX\\\"",
        "PCIE_ENDPOINT_TYPE"   : "\\\"R_TILE\\\"",
        "__core_params__"      : {"PCIE_TYPE" : "R_TILE"},
    },

    "ultrascale" : {
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "4"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "4"                 ,

        "CQ_MFB_REGIONS"       : "2"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "CC_MFB_REGIONS"       : "2"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,


        "AXI_CQUSER_WIDTH"     : "183"               ,
        "AXI_CCUSER_WIDTH"     : "81"                ,
        "AXI_RQUSER_WIDTH"     : "137"               ,
        "AXI_RCUSER_WIDTH"     : "161"               ,
        "AXI_STRADDLING"       : "0"                 ,

        "DEVICE"               : "\\\"ULTRASCALE\\\"",
        "PCIE_ENDPOINT_TYPE"   : "\\\"DUMMY\\\""     ,
        "__core_params__"          : {"PCIE_TYPE" : "USP"}     ,
    },

    "dma_ports_16" : {
        "DMA_PORTS"            : 16,
    },
    "_combinations_" : {
        "INTEL_P_TILE"        : ("intel_p_tile",                ),
        "INTEL_P_TILE_DMA_16" : ("intel_p_tile", "dma_ports_16",),
        "INTEL_P_TILE_BIFUR"  : ("intel_p_tile_bifur",          ),
        "INTEL_P_TILE_BIFUR2" : ("intel_p_tile_bifur2",         ),
        "INTEL_R_TILE"        : ("intel_r_tile",                ),
        "INTEL_R_TILE_DMA_16" : ("intel_r_tile", "dma_ports_16",),
        "INTEL_R_TILE_BIFUR"  : ("intel_r_tile_bifur",          ),
        "INTEL_R_TILE_BIFUR2" : ("intel_r_tile_bifur2",         ),
        "XILINX"              : ("ultrascale",                  ),
        "XILINX_DMA_16"       : ("ultrascale", "dma_ports_16",  ),
    },
}
