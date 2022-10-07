.. _ndk_app_configuration:

Parametrizing the user application
==================================
The user application can also be parametrized using specific configuration
files. Configuration parameters are handed to the subcomponents of the
``APPLICATION_CORE`` design entity. It also allows the user to choose one of,
sometimes, multiple configurations for a specific card before launching the
build process. This page further extends :ref:`ndk_core_configuration` and
:ref:`ndk_card_configuration` sections. The sourcing of configuration parameter
files has its own hierarchy shown in the :ref:`fig_const_hierarchy`.

Configuration files
-------------------
The configuration of the application is less constrained than `NDK-CORE` and
card configuration. The `NDK-APP-MINIMAL` provides three files in which the user
application is or can be configured.

.. _app_config_makefile:

build/<card_name>/Makefile
^^^^^^^^^^^^^^^^^^^^^^^^^^
.. WARNING::
   This file contains features for development. It is not recommended for the user to change
   the parameters in this file.


This is the top-level file that launches the building of the design. The
configuration(s) given in this file depend on the card type and they allow to build the
design with different parameters, for example, when there are multiple Ethernet configurations.
For more information about the modes of each
card, visit the "Build instructions" section provided in the documentation for each of the
card types.

The configuration parameters are handed as environment variables which are
converted into TCL variables. These are used in the `*_const.tcl*` and
`*_conf.tcl` files throughout the design. There are more Makefile configuration
parameters in use than just Ethernet configuration. They are declared in the
:ref:`core_mk_include` and can be changed when issuing the ``make`` command.
The example of this goes as follows:

.. code-block:: bash

    # default build configuration
    make DMA_TYPE=4

    # choosing to build specific Ethernet configuration
    make 100g4 DMA_TYPE=3

build/<card_name>/{Vivado,Quartus}.tcl
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This file adds the ``APPLICATION_CORE`` entity where the
user application is. The `APP_ARCHGRP` associative array is
initialized in this file and allows the user to pass one or more user-specified
parameter(s) to Modules.tcl files of the ``APPLICATION_CORE`` and its underlying
components. All configuration parameters in the :ref:`fig_const_hierarchy`
are visible here and can be added to the array as well.

.. _ndk_app_conf_app_conf_tcl:

build/<card_name>/app_conf.tcl
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This file has the highest priority of all user-configurable
constants (for more details, refer to the :ref:`fig_const_hierarchy`). The user
can change the parameters specified in this file or add others according to
their needs.

Further reading
---------------
* CORE configuration -> :ref:`ndk_core_configuration`
* Card configuration -> :ref:`ndk_card_configuration`
