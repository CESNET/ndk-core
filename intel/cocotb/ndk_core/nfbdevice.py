import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, Combine

from cocotbext.ofm.axi4stream.drivers import Axi4StreamMaster, Axi4StreamSlave
from cocotbext.ofm.axi4stream.monitors import Axi4Stream

from cocotbext.ofm.pcie import Axi4SCompleter
from cocotbext.ofm.pcie import Axi4SRequester

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


class NFBDevice(cocotbext.nfb.NfbDevice):
    @staticmethod
    def core_instance_from_top(dut):
        try:
            core = [getattr(dut, core) for core in ["usp_i", "fpga_i", "ag_i"] if hasattr(dut, core)][0]
        except:
            # No fpga_common instance in card, try fpga_common directly
            core = dut

        return core

    async def _init_clks(self):
        if hasattr(self._dut, 'REFCLK'):
            # Tivoli card
            await cocotb.start(Clock(self._dut.REFCLK, 20, 'ns').start())
        elif hasattr(self._dut, 'SYSCLK_P'):
            # NFB-200G2QL
            await cocotb.start(Clock(self._dut.SYSCLK_P, 8, 'ns').start())
            await cocotb.start(Clock(self._dut.SYSCLK_N, 8, 'ns').start(start_high=False))
        elif hasattr(self._dut, 'AG_SYSCLK0_P'):
            # AGI-400G
            # FIXME: Check freq
            await cocotb.start(Clock(self._dut.AG_SYSCLK0_P, 8, 'ns').start())
            await cocotb.start(Clock(self._dut.AG_SYSCLK1_P, 8, 'ns').start())
        else:
            # No card: fpga_common
            await cocotb.start(Clock(self._dut.SYSCLK, 10, 'ns').start())

        for pcie_clk in self._core.pcie_i.pcie_core_i.pcie_hip_clk:
            await cocotb.start(Clock(pcie_clk, 4, 'ns').start())

        for eth_core in self._core.network_mod_i.eth_core_g:
            if hasattr(eth_core.network_mod_core_i, 'cmac_clk_322m'):
                await cocotb.start(Clock(eth_core.network_mod_core_i.cmac_clk_322m, 3106, 'ps').start())

    def _init_pcie(self):
        try:
            self._core = NFBDevice.core_instance_from_top(self._dut)
        except:
            # No fpga_common instance in card, try fpga_common directly
            self._core = self._dut

        pcie_i = self._core.pcie_i.pcie_core_i
        self.mi = []
        self.pcie_req = []

        for i, clk in enumerate(pcie_i.pcie_hip_clk):
            clk = pcie_i.pcie_hip_clk[i]
            #rst = pcie_i.pcie_hip_rst[i]
            if hasattr(pcie_i, "pcie_cq_axi_data"):
                cq  = Axi4StreamMasterV(pcie_i, "pcie_cq_axi", clk, array_idx=i)
                cc  = Axi4StreamSlaveV(pcie_i, "pcie_cc_axi", clk, array_idx=i)
                ccm = Axi4StreamV(pcie_i, "pcie_cc_axi", clk, 0, aux_signals=True, array_idx=i)

                rq  = Axi4StreamSlaveV(pcie_i, "pcie_rq_axi", clk, array_idx=i)
                rc  = Axi4StreamMasterV(pcie_i, "pcie_rc_axi", clk, array_idx=i)
                rqm = Axi4StreamV(pcie_i, "pcie_rq_axi", clk, aux_signals=True, array_idx=i)

                req = Axi4SRequester(self.ram, rq, rc, rqm)
                mi  = Axi4SCompleter(cq, cc, ccm)
                self.mi.append(mi)
                self.pcie_req.append(req)

        self._eth_rx_driver = []
        self._eth_tx_monitor = []
        for i, eth_core in enumerate(self._core.network_mod_i.eth_core_g):
            if hasattr(eth_core.network_mod_core_i, 'cmac_tx_lbus_rdy'):
                eth_core.network_mod_core_i.cmac_tx_lbus_rdy.value = 1
                eth_core.network_mod_core_i.cmac_rx_local_fault.value = 0

                tx_monitor = LBusMonitor(eth_core.network_mod_core_i, "cmac_tx_lbus", eth_core.network_mod_core_i.cmac_clk_322m)
                rx_driver = LBusDriver(eth_core.network_mod_core_i, "cmac_rx_lbus", eth_core.network_mod_core_i.cmac_clk_322m)
                self._eth_tx_monitor.append(tx_monitor)
                self._eth_rx_driver.append(rx_driver)

        self.dtb = None

    async def _reset(self):
        pcie_i = self._core.pcie_i.pcie_core_i
        if hasattr(pcie_i, 'pcie_hip_rst'):
            for rst in pcie_i.pcie_hip_rst:
                rst.value = 1
            await Timer(40, units="ns")
            for rst in pcie_i.pcie_hip_rst:
                rst.value = 0

        await cocotb.triggers.FallingEdge(self._core.global_reset)

    async def _pcie_cfg_ext_reg_access(self, addr, index = 0, fn = 0, sync=True, data=None):
        pcie_i = self._core.pcie_i.pcie_core_i
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
