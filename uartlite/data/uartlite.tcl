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
    set consoleip [get_property CONFIG.console_device [get_os]]
    if { [string match -nocase $consoleip $ip] } {
        set ip_type [get_property IP_NAME $ip]
        if { [string match -nocase $ip_type] } {
            hsi::utils::set_os_parameter_value "console" "ttyUL0,115200"
        } else {
            hsi::utils::set_os_parameter_value "console" "ttyUL0,[hsi::utils::get_ip_param_value $ip C_BAUDRATE]"
        }
    }

    gen_dev_ccf_binding $drv_handle "s_axi_aclk"
}
