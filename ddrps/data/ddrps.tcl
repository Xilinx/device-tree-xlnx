# workaround for ps7 ddrc has none zero start address
proc gen_ps7_ddr_reg_property {drv_handle} {
    proc_called_by
    set reg ""
    set slave [get_cells ${drv_handle}]
    set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
    foreach mem_handle ${ip_mem_handles} {
        #set base [get_property BASE_VALUE $mem_handle]
        set base 0x0
        set high [get_property HIGH_VALUE $mem_handle]
        set size [format 0x%x [expr {${high} - ${base} + 1}]]
        if {[string_is_empty $reg]} {
            set reg "$base $size"
        } else {
            # ensure no duplication
            if {![regexp ".*${reg}.*" "$base $size" matched]} {
                set reg "$reg $base $size"
            }
        }
    }
    set_drv_prop_if_empty $drv_handle reg $reg intlist
}


proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    gen_ps7_ddr_reg_property $drv_handle
    add_memory_node $drv_handle
}
