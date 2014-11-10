proc generate {drv_handle} {
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    set ip [get_cells $drv_handle]
    set has_xin [hsi::utils::get_ip_param_value $ip C_HAS_EXTERNAL_XIN]
    set clock_port "S_AXI_ACLK"
    if { [string match -nocase "$has_xin" "1"] } {
        set_drv_conf_prop $drv_handle C_EXTERNAL_XIN_CLK_HZ clock-frequency
        # TODO: update the clock-names and clocks properties and create a
        # fixed clock node. Currently this is causing any issue as the
        # driver only uses clock-frequency property

    } else {
        set freq [hsi::utils::get_clk_pin_freq $ip "$clock_port"]
        set_property clock-frequency $freq $drv_handle
    }

    set consoleip [get_property CONFIG.console_device [get_os]]
    if { [string match -nocase $consoleip $ip] } {
        hsi::utils::set_os_parameter_value "console" "ttyS0,115200"
    }
}
