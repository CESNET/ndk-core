#!/bin/sh
# Example script for preparing ndk-app repository to run top-level cocotb simulation
# Run it once in the build/CARD folder !

# Check base folder
ls ../../ndk/core/intel/cocotb/examples/cocotb_test.py > /dev/null
if [ $! ]; then
	echo "Run this script in the build/CARD folder!"
	exit 1
fi

CARD=$(basename $(pwd))

# These commands already done on preklad machines:
# pip3 install cocotb
# pip3 install cocotb-bus
# pip3 install fdt
# git clone https://github.com/dgibson/dtc.git --branch v1.6.0
# (cd dtc; make; cd pylibfdt; python3.9 setup.py install --user)

# Install cocotbext-ofm and its cocotbext.axi4stream dependency
pip3 install git+https://github.com/martinspinler/cocotbext-axi4stream.git#egg=cocotbext.axi4stream -U
pip3 install git+ssh://git@gitlab.liberouter.org/ndk/cocotbext.git#egg=cocotbext-ofm -U

# Use example test
cp ../../ndk/core/intel/cocotb/examples/cocotb_test* ./

# Workaround some issues:
# a) with overriden OUTPUT_NAME variable: generate the temporary folder (for DT & nc.vhd) with correct name:
sed -i '/OUTPUT_NAME:=/d' Makefile
# b) fix missing FIRMWARE_BASE variable
sed -i '1i set FIRMWARE_BASE $env(COMBO_BASE)' ../../ndk/ofm/build/scripts/cocotb/cocotb.fdo
# c) Disable generation of simulation files from XCI IP (for faster simulation start)
sed -i '/xci/d' ../../ndk/cards/$CARD/src/Modules.tcl
# d) Disable emulation file for SYSMON
sed -i 's=SIM_MONITOR_FILE.*=SIM_MONITOR_FILE \=> "/dev/null"=' ../../ndk/ofm/comp/base/misc/id32/sysmon_usp.vhd

# Create generated files (DeviceTree.* & netcope_const.vhd)
sed -i 's/SYNTH_FLAGS(PROJ_ONLY) "0"/SYNTH_FLAGS(PROJ_ONLY) "1"/' Vivado.tcl; make
# Run simulation
#make cocotb
echo "Now run simulation with command: make cocotb"
