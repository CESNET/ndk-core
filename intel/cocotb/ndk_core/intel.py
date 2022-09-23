import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, Combine

from cocotbext.axi4stream.drivers import Axi4StreamMaster, Axi4StreamSlave
from cocotbext.axi4stream.monitors import Axi4Stream

from cocotbext.ofm.axi4sibpcie import Axi4SCMiRoot
from cocotbext.ofm.axi4sibpcie import Axi4SRequester

import cocotbext.nfb
from cocotbext.ofm.lbus.monitors import LBusMonitor
from cocotbext.ofm.lbus.drivers import LBusDriver

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
        cocotb.start_soon(Clock(self._dut.REFCLK, 20, 'ns').start())

        for pcie_clk in self._dut.usp_i.pcie_i.pcie_core_i.pcie_hip_clk:
            cocotb.start_soon(Clock(pcie_clk, 4, 'ns').start())
        for eth_core in self._dut.usp_i.network_mod_i.eth_core_g:
            cocotb.start_soon(Clock(eth_core.network_mod_core_i.cmac_clk_322m, 3106, 'ps').start())

    def _init_pcie(self):
        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i
        self.mi = []

        for i, clk in enumerate(pcie_i.pcie_hip_clk):
            clk = pcie_i.pcie_hip_clk[i]
            rst = pcie_i.pcie_hip_rst[i]

            cq  = Axi4StreamMasterV(pcie_i, "CQ_AXI", clk, array_idx=i)
            cc  = Axi4StreamSlaveV(pcie_i, "CC_AXI", clk, array_idx=i)
            ccm = Axi4StreamV(pcie_i, "CC_AXI", clk, 0, aux_signals=True, array_idx=i)

            rq  = Axi4StreamSlaveV(pcie_i, "RQ_AXI", clk, array_idx=i)
            rc  = Axi4StreamMasterV(pcie_i, "RC_AXI", clk, array_idx=i)
            rqm = Axi4StreamV(pcie_i, "RQ_AXI", clk, aux_signals=True, array_idx=i)

            req = Axi4SRequester(self.ram, rq, rc, rqm)
            mi  = Axi4SCMiRoot(cq, cc, ccm)
            self.mi.append(mi)

        self._eth_rx_driver = []
        self._eth_tx_monitor = []
        for i, eth_core in enumerate(self._dut.usp_i.network_mod_i.eth_core_g):
            eth_core.network_mod_core_i.cmac_tx_lbus_rdy.value = 1
            eth_core.network_mod_core_i.cmac_rx_local_fault.value = 0

            tx_monitor = LBusMonitor(eth_core.network_mod_core_i, "cmac_tx_lbus", eth_core.network_mod_core_i.cmac_clk_322m)
            rx_driver = LBusDriver(eth_core.network_mod_core_i, "cmac_rx_lbus", eth_core.network_mod_core_i.cmac_clk_322m)
            self._eth_tx_monitor.append(tx_monitor)
            self._eth_rx_driver.append(rx_driver)

        self.dtb = None

    async def _reset(self):
        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i

        for rst in pcie_i.pcie_hip_rst:
            rst.value = 1
        await Timer(40, units="ns")
        for rst in pcie_i.pcie_hip_rst:
            rst.value = 0
        await Timer(2, units="us")

    async def _pcie_cfg_ext_reg_access(self, addr, index = 0, fn = 0, sync=True, data=None):
        pcie_i = self._dut.usp_i.pcie_i.pcie_core_i
        clk = pcie_i.pcie_hip_clk[index]

        if sync:
            await RisingEdge(clk)

        pcie_i.cfg_ext_function[index].value = fn
        pcie_i.cfg_ext_register[index].value = addr >> 2
        pcie_i.cfg_ext_read[index].value = 1 if data == None else 0
        pcie_i.cfg_ext_write[index].value = 0 if data == None else 1
        if data:
            pcie_i.cfg_ext_write_data[index].value = data
        await RisingEdge(clk)
        pcie_i.cfg_ext_read[index].value = 0
        pcie_i.cfg_ext_write[index].value = 0
        if data == None:
            return pcie_i.cfg_ext_read_data[index].value.integer

    async def _pcie_cfg_ext_reg_read(self, addr, index = 0, fn = 0, sync=True):
        return await self._pcie_cfg_ext_reg_access(addr, index, fn, sync)

    async def _pcie_cfg_ext_reg_write(self, addr, data, index = 0, fn = 0, sync=True):
        await self._pcie_cfg_ext_reg_access(addr, index, fn, sync, data)

    async def _read_dtb_raw(self, cap_dtb = 0x480):
        dtb_length = await self._pcie_cfg_ext_reg_read(cap_dtb + 0x0c)
        data = []
        for i in range(dtb_length // 4):
            await self._pcie_cfg_ext_reg_write(cap_dtb + 0x10, i, sync=False)
            data.append(await self._pcie_cfg_ext_reg_read(cap_dtb + 0x14, sync=True))

        return bytes(sum([[(x >> 0) & 0xFF, (x >> 8) & 0xFF, (x >> 16) & 0xFF, (x >> 24) & 0xFF] for x in data], []))
