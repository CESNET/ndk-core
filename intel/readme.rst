.. _ndk_intel:

NDK architecture (Intel FPGA)
-----------------------------

The Network Development Kit (NDK) is available for the selected card based on Intel FPGA. The NDK allows users to quickly and easily develop new network appliances based on FPGA acceleration cards. The NDK is optimized for high throughput and scalable to support 10, 100 and 400 Gigabit Ethernet.

.. image:: doc/img/fpga_arch.svg
    :align: center
    :width: 100 %

As you can see in the image above, the top level architecture consists of several building blocks:

- MI bus interconnection (MI Splitter,...) allows access to Control and Status Register (CSR)
- Network module provides transmission and receiving of Ethernet packets
- The DMA module controls the high-speed packet data transfer to the guest PC's memory
- The PCIe module mediates communication via the PCIe interface for the DMA module and for MI transactions, it also contains a ROM with a description of the firmware
- The Application core is the place for the user application, it can receive and transmit data through the network module and DMA module, and can also access to external memory
- Time Stamp Unit (TSU) is used to generate accurate time stamps for Network module and Application core
- The Memory controller provides data transfer between the external memory and the FPGA
- The FPGA controller allows access to the QSPI flash memory and request a reboot of the FPGA

.. warning::

    The DMA module IP is not part of the open-source NDK. If the DMA module IP is disabled, then it is replaced by a loopback. `You can get NDK including DMA Module IP and professional support through our partner BrnoLogic <https://support.brnologic.com/>`_

.. note::

    Some blocks can be connected more than once in the NDK platform. For example, it is a Network module if the target card contains multiple Ethernet ports (QSFP slots) or a PCIe module if the used card allows connecting more than one PCIe connector.

.. toctree::
   :maxdepth: 2
   :hidden:

   doc/mi
   doc/app
   doc/eth
   doc/dma
   doc/pcie
   doc/mem
   doc/tsu
