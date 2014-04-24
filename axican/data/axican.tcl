proc add_zynq_clk_binding { drv_handle } {
    set proc_name [get_property HW_INSTANCE [get_sw_processor]]
    set hwproc [get_cells -filter " NAME==$proc_name"]
    set proctype [get_property IP_NAME $hwproc]
    if { [string match -nocase $proctype "ps7_cortexa9"] } {
        hsm::utils::add_new_property $drv_handle "clock-names" stringlist "ref_clk"
        hsm::utils::add_new_property $drv_handle "clocks" reference "clkc 0"
    }
}

proc generate {drv_handle} {
    # add zynq clk binding. This is not required for MB as it is handled in post process step
    add_zynq_clk_binding $drv_handle
}
