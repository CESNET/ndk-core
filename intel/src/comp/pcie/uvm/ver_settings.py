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
    "intel_p_tyle" : {
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
    "intel_p_tyle_bifur" : {
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
    "intel_p_tyle_bifur2" : {
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


    "ultrascale" : {
        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,

        "RC_MFB_REGIONS"       : "4"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "4"                 ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,

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
        "INTEL_P_TILE"        : ("intel_p_tyle",                  ),
        "INTEL_P_TILE_DMA_16" : ("intel_p_tyle", "dma_ports_16",  ),
        "INTEL_P_TILE_BIFUR"  : ("intel_p_tyle_bifur",            ),
        "INTEL_P_TILE_BIFUR2" : ("intel_p_tyle_bifur2",           ),
        "XILINX"              : ("ultrascale",                    ) ,
        "XILINX_DMA_16"       : ("ultrascale", "dma_ports_16",    ) ,
    },
}

# TODO: combination
#bifur_r_tile{
#    endpoint_mode 1;
#    dma_port      1;
#    endpoind      2;
#    connections   1;
#    endpoint_type R_TILE
#    device        AGILEX
#}

#r_tile{
#    endpoint_mode 0;
#    dma_port      4;
#    endpoind      1;
#    connections   1;
#    endpoint_type R_TILE
#    device        AGILEX
#}
