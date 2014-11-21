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

    hsi::utils::add_new_dts_param "${clkc_node}" "fclk-enable" "0xf" int
    if {[catch {set ps_clk_freq [get_property CONFIG.C_INPUT_CRYSTAL_FREQ_HZ [get_cells ps7_clockc_0]]} msg]} {
        set ps_clk_freq ""
    }
    if {[string_is_empty ${ps_clk_freq}]} {
        puts "WARNING: DTG failed to detect the ps-clk-frequency, Using default value - 33333333"
        set ps_clk_freq 33333333
    }
    hsi::utils::add_new_dts_param "${clkc_node}" "ps-clk-frequency" ${ps_clk_freq} int
    return $clkc_node
}
