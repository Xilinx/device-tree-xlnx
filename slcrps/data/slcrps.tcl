#
# (C) Copyright 2014-2015 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    set node [gen_peripheral_nodes $drv_handle]
    gen_clocks_node $node
}

proc gen_clocks_node {parent_node} {
    set clocks_child_name "clkc"
    set clkc_node [add_or_get_dt_node -l $clocks_child_name -n $clocks_child_name -u 100 -p $parent_node]

    if {[catch {set ps_clk_freq [get_property CONFIG.C_INPUT_CRYSTAL_FREQ_HZ [get_cells -hier ps7_clockc_0]]} msg]} {
        set ps_clk_freq ""
    }
    if {[string_is_empty ${ps_clk_freq}]} {
        puts "WARNING: DTG failed to detect the ps-clk-frequency, Using default value - 33333333"
        set ps_clk_freq 33333333
    }
    hsi::utils::add_new_dts_param "${clkc_node}" "ps-clk-frequency" ${ps_clk_freq} int

    set fclk_val "0"
    set clk_pin_list [get_pins [get_cells -hier ps7_clockc_0] -regexp FCLK_CLK[0-3]]
    foreach clk_pin ${clk_pin_list} {
        dtg_debug "clk_pin: $clk_pin"
        set clk_net [get_nets -of_objects $clk_pin]
        set connected_pin_names [get_pins -of_objects $clk_net]
        foreach target_pin ${connected_pin_names} {
            dtg_debug " target_pin: $target_pin"
            set connected_ip [get_cells -of_objects $target_pin]
            if {[is_pl_ip $connected_ip]} {
                regsub -all {FCLK_CLK} $clk_pin {} fclk_pin
                set fclk_val [expr [expr 1 << $fclk_pin] | $fclk_val]
                dtg_debug "  PL IP: $connected_ip, CLK_PIN: $clk_pin, FCLK_PIN: $fclk_pin, FCLK_VAL: [format %x $fclk_val]"
                # Here could be break
            } elseif {![string match "ps7_clockc_0" $connected_ip]} {
                dtg_debug "  PS IP: $connected_ip"
            }
        }
    }
    hsi::utils::add_new_dts_param "${clkc_node}" "fclk-enable" "0x[format %x $fclk_val]" int
    return $clkc_node
}
