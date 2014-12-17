proc ns_to_cycle {drv_handle prop_name nand_cycle_time} {
    set extra_cycle 1
    if {${nand_cycle_time} == 1} { set extra_cycle 0}
    return [expr [get_property CONFIG.$prop_name [get_cells $drv_handle]]/${nand_cycle_time} + ${extra_cycle}]
}

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
             set nand_cycle_time 1
        } "2014.4" -
        default {
            set nand_par_prefix "NAND-CYCLE-"
            set nand_cycle_time [expr "1000000000/[get_property CONFIG.C_NAND_CLK_FREQ_HZ [get_cells $drv_handle]]"]
        }
    }

    set_drv_prop $drv_handle "arm,nand-cycle-t0" [ns_to_cycle $drv_handle "${nand_par_prefix}T0" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t1" [ns_to_cycle $drv_handle "${nand_par_prefix}T1" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t2" [ns_to_cycle $drv_handle "${nand_par_prefix}T2" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t3" [ns_to_cycle $drv_handle "${nand_par_prefix}T3" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t4" [ns_to_cycle $drv_handle "${nand_par_prefix}T4" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t5" [ns_to_cycle $drv_handle "${nand_par_prefix}T5" $nand_cycle_time]
    set_drv_prop $drv_handle "arm,nand-cycle-t6" [ns_to_cycle $drv_handle "${nand_par_prefix}T6" $nand_cycle_time]

}
