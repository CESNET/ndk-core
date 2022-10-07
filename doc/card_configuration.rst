.. _ndk_card_configuration:

Parametrizing a specific card type
==================================
The final design of the NDK application depends on the underlying
platform, e.g., the card type on which the design should run.
As the card parameters have higher priority, their values overwrite those
in the `NDK-CORE` (section :ref:`ndk_core_configuration`).

File description
----------------
The file structure is similar to the one described in the configuration of the
`NDK-CORE` design.

card_conf.tcl
^^^^^^^^^^^^^
This file lists user-configurable parameters and their possible
values in the comments. The purpose of this file is the same as of the
``core_conf.tcl`` file in the `NDK-CORE` repository. The only difference is that it has a higher priority.

.. _card_conf_card_const_tcl:

card_const.tcl
^^^^^^^^^^^^^^
.. WARNING::
   This file contains features for development. It is not recommended for the user to change
   the parameters in this file.

This file contains card-specific parameters which mostly depend on the features
of the physical hardware (the target card). It should also implement a check for
the configuration parameters whether their values are valid and compatible with
the values of other parameters.

card.mk
^^^^^^^
.. WARNING::
   This file contains features for development. It is not recommended for the user to change
   the parameters in this file.

This part of the Makefile sources all environment variables used
during the initial stage of the build process. The majority of the variables contain
paths to various locations from which the design is sourced/built. There are also
build-specific variables that further parametrize the design. The purpose of
these is described in the :ref:`app_config_makefile` section.

Further work with parameters
----------------------------
.. WARNING::
   These features are for development and should not be used in regular
   application use.

Passing the parameter values to other parts of the design or build system is
very similar to the case of `NDK-CORE`.

Passing through Modules.tcl
^^^^^^^^^^^^^^^^^^^^^^^^^^^
The card-specific parameters are passed to the Modules.tcl file of the top-level
entity using the ``CARD_ARCHGRP`` associative array. This array is initialized in
the ``<card_root_directory>/src/Vivado.inc.tcl`` file for Xilinx-based cards and
in ``<card_root_directory>/src/Quartus.inc.tcl`` for Intel-based cards. The
``CARD_ARCHGRP`` array is concatenated with ``CORE_ARCHGRP`` so the top-level
Modules.tcl file shares parameters of them both. The parameters specified
in the :ref:`ndk_core_conf_core_conf_tcl`, :ref:`ndk_core_conf_core_const_tcl`,
`card_conf.tcl`, `card_const.tcl` and also :ref:`ndk_app_conf_app_conf_tcl`.
are visible in the `*.inc.tcl` files and can be added to the array.

Adding constants to the VHDL package
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
It is recommended to add constants to the ``combo_user_const`` VHDL package in
the ``core_const.tcl`` file which was described in the
:ref:`core_config_vhdl_pkg_const` section in the documentation of NDK-CORE
configuration.

Further reading
---------------
* Application configuration -> :ref:`ndk_app_configuration`
* CORE configuration -> :ref:`ndk_core_configuration`
