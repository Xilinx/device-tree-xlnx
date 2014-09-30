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

    set hw_ver [get_hw_version]
    # Parameter name changed in 2014.4
    # TODO: check with 2014.3
    switch -exact $hw_ver {
        "2014.2" {
             set nand_par_prefix "C_NAND_CYCLE_"
        } "2014.4" -
        default {
            set nand_par_prefix "NAND-CYCLE-"
        }
    }

    set_drv_conf_prop $drv_handle "${nand_par_prefix}T0" "arm,nand-cycle-t0"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T1" "arm,nand-cycle-t1"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T2" "arm,nand-cycle-t2"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T3" "arm,nand-cycle-t3"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T4" "arm,nand-cycle-t4"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T5" "arm,nand-cycle-t5"
    set_drv_conf_prop $drv_handle "${nand_par_prefix}T6" "arm,nand-cycle-t6"
}
