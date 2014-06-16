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

    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T0" "arm,nand-cycle-t0"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T1" "arm,nand-cycle-t1"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T2" "arm,nand-cycle-t2"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T3" "arm,nand-cycle-t3"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T4" "arm,nand-cycle-t4"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T5" "arm,nand-cycle-t5"
    set_drv_conf_prop $drv_handle "C_NAND_CYCLE_T6" "arm,nand-cycle-t6"
}
