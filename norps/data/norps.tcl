proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }

    # TODO: if addr25 is used, should we consider set the reg size to 64MB?
    # enable reg generation for ps ip
    gen_reg_property $drv_handle "enable_ps_ip"
}
