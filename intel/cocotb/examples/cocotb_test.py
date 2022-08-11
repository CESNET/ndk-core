import cocotb
from cocotb.triggers import Timer, RisingEdge, Combine

from ndk_core.intel import NFBDevice

@cocotb.test()
async def cocotb_test_read_from_macs(dut):
    nfb = NFBDevice(dut)
    await nfb.init()
    mi, dma = nfb.mi[0], nfb.dma
    #fdt_offset = nfb.fdt.path_offset("/firmware/mi_bus0/boot_controller")

    print(await mi.read32(0x8020))
    print(await mi.read32(0x8220))
    print(await mi.read32(0xa020))
    print(await mi.read32(0xa220))
