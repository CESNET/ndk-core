-- convertor_rx.vhd: Converts std_logic_vector into slv_array_t
-- Copyright (C) 2024 CESNET z. s. p. o.
-- Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.type_pack.all;

-- ======
-- Entity
-- ======

entity CONVERTOR_RX is
    generic (
        ITEMS      : natural;
        ITEM_WIDTH : natural
    );
    port (
        LOGIC_VECTOR_IN : in  std_logic_vector(ITEMS*ITEM_WIDTH-1 downto 0);
        SLV_ARRAY_OUT   : out slv_array_t     (ITEMS-1 downto 0)(ITEM_WIDTH-1 downto 0)
    );
end entity;

-- ============
-- Architecture
-- ============

architecture FULL of CONVERTOR_RX is
begin

    SLV_ARRAY_OUT <= slv_array_deser(LOGIC_VECTOR_IN, ITEMS, ITEM_WIDTH);

end architecture;   
