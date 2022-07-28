import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, Combine

from cocotbext.axi4stream.drivers import Axi4StreamMaster, Axi4StreamSlave
from cocotbext.axi4stream.monitors import Axi4Stream

from cocotbext.ofm.axi4sibpcie import Axi4SCMiRoot
from cocotbext.ofm.axi4sibpcie import Axi4SRequester

import cocotbext.nfb

class Axi4StreamMasterV(Axi4StreamMaster):
    _signals = {"TVALID": "VALID"}
    _optional_signals = {"TREADY": "READY", "TDATA": "DATA", "TLAST": "LAST", "TKEEP" :"KEEP", "TUSER": "USER"}
class Axi4StreamSlaveV(Axi4StreamSlave):
    _signals = {"TVALID": "VALID"}
    _optional_signals = {"TREADY": "READY", "TDATA": "DATA", "TLAST": "LAST", "TKEEP" :"KEEP", "TUSER": "USER"}
class Axi4StreamV(Axi4Stream):
    _signals = {"TVALID": "VALID"}
    _optional_signals = {"TREADY": "READY", "TDATA": "DATA", "TLAST": "LAST", "TKEEP" :"KEEP", "TUSER": "USER"}


class NFBDevice(cocotbext.nfb.NFBDevice):
    def _init_clks(self):
        cocotb.fork(Clock(self._dut.REFCLK, 20, 'ns').start())

        for pcie_clk in self._dut.usp_i.pcie_i.pcie_core_i.pcie_hip_clk:
            cocotb.fork(Clock(pcie_clk, 4, 'ns').start())
        for eth_core in self._dut.usp_i.network_mod_i.eth_core_g:
            cocotb.fork(Clock(eth_core.network_mod_core_i.cmac_clk_322m, 3106, 'ps').start())

    def _init_pcie(self):
        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i
        self.mi = []

        for i, clk in enumerate(pcie_i.pcie_hip_clk):
            clk = pcie_i.pcie_hip_clk[i]
            rst = pcie_i.pcie_hip_rst[i]

            cq  = Axi4StreamMasterV(pcie_i, "CQ_AXI", clk, array_idx=i)
            cc  = Axi4StreamSlaveV(pcie_i, "CC_AXI", clk, array_idx=i)
            ccm = Axi4StreamV(pcie_i, "CC_AXI", clk, 0, array_idx=i)

            rq  = Axi4StreamSlaveV(pcie_i, "RQ_AXI", clk, array_idx=i)
            rc  = Axi4StreamMasterV(pcie_i, "RC_AXI", clk, array_idx=i)
            rqm = Axi4StreamV(pcie_i, "RQ_AXI", clk, aux_signals=True, array_idx=i)

            req = Axi4SRequester(self.ram, rq, rc, rqm)
            mi  = Axi4SCMiRoot(cq, cc, ccm)
            self.mi.append(mi)

        self.dtb = None

    async def _reset(self):
        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i

        for rst in pcie_i.pcie_hip_rst:
            rst.value = 1
        await Timer(40, units="ns")
        for rst in pcie_i.pcie_hip_rst:
            rst.value = 0
        await Timer(2, units="us")

    async def _read_dtb_raw(self):
        r = 0
        cap_dtb = 0x480

        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i
        clk = pcie_i.pcie_hip_clk[r]

        await RisingEdge(clk)
        pcie_i.cfg_ext_function[r].value = 0
        pcie_i.cfg_ext_register[r].value = (cap_dtb + 0x0C) >> 2
        pcie_i.cfg_ext_write[r].value = 0
        pcie_i.cfg_ext_read[r].value = 1
        await RisingEdge(clk)

        dtb_length = pcie_i.cfg_ext_read_data[r].value.integer
        data = [] 
        for i in range(dtb_length // 4):
            pcie_i.cfg_ext_register[r].value = (cap_dtb + 0x10) >> 2
            pcie_i.cfg_ext_write_data[r].value = i
            pcie_i.cfg_ext_read[r].value = 0
            pcie_i.cfg_ext_write[r].value = 1
            await RisingEdge(clk)

            pcie_i.cfg_ext_register[r].value = 0x494 >> 2
            pcie_i.cfg_ext_write[r].value = 0
            pcie_i.cfg_ext_read[r].value = 1
            await RisingEdge(clk)
            await RisingEdge(clk)
            data.append(pcie_i.cfg_ext_read_data[r].value.integer)
        pcie_i.cfg_ext_read[r].value = 0

        return bytes(sum([[(x >> 0) & 0xFF, (x >> 8) & 0xFF, (x >> 16) & 0xFF, (x >> 24) & 0xFF] for x in data], []))
