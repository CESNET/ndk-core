# ver_settings.py
# Copyright (C) 2023 CESNET z. s. p. o.
# Author(s): Daniel Kříž <danielkriz@cesnet.cz>

SETTINGS = {
    "default" : { # The default setting of verification is 512b and STRATIX with P_TILE
        "CQ_MFB_REGIONS"       : "2"                 ,
        "CQ_MFB_REGION_SIZE"   : "1"                 ,
        "CQ_MFB_BLOCK_SIZE"    : "8"                 ,
        "CQ_MFB_ITEM_WIDTH"    : "32"                ,

        "RC_MFB_REGIONS"       : "2"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "8"                 ,
        "RC_MFB_ITEM_WIDTH"    : "32"                ,

        "CC_MFB_REGIONS"       : "2"                 ,
        "CC_MFB_REGION_SIZE"   : "1"                 ,
        "CC_MFB_BLOCK_SIZE"    : "8"                 ,
        "CC_MFB_ITEM_WIDTH"    : "32"                ,

        "RQ_MFB_REGIONS"       : "2"                 ,
        "RQ_MFB_REGION_SIZE"   : "1"                 ,
        "RQ_MFB_BLOCK_SIZE"    : "8"                 ,
        "RQ_MFB_ITEM_WIDTH"    : "32"                ,

        "AXI_CQUSER_WIDTH"     : "183"               ,
        "AXI_CCUSER_WIDTH"     : "81"                ,
        "AXI_RQUSER_WIDTH"     : "137"               ,
        "AXI_RCUSER_WIDTH"     : "161"               ,
        "AXI_STRADDLING"       : "0"                 ,

        "DEVICE"               : "\\\"STRATIX10\\\"" ,
        "PCIE_ENDPOINT_TYPE"   : "\\\"P_TILE\\\""    ,
        "__archgrp__"          : {"DUT" : "P_TILE"}  ,
    },
    "ultrascale" : {
        "RC_MFB_REGIONS"       : "4"                 ,
        "RC_MFB_REGION_SIZE"   : "1"                 ,
        "RC_MFB_BLOCK_SIZE"    : "4"                 ,
        "RC_MFB_ITEM_WIDTH"    : "32"                ,

        "DEVICE"               : "\\\"ULTRASCALE\\\"",
        "PCIE_ENDPOINT_TYPE"   : "\\\"DUMMY\\\""     ,
        "__archgrp__"          : {"DUT" : "USP"}     ,
    },
    "_combinations_" : (  
    (), # Works the same as '("default",),' as the "default" is applied in every combination
    ("ultrascale",),
    ),
}