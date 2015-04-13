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

	# the interrupt related setting is only required for AXI4 protocol only
	set atg_mode [get_property "CONFIG.C_ATG_MODE" [get_cells $drv_handle]]
	if { ![string match -nocase $atg_mode "AXI4"] } {
		return 0
	}

	# set up interrupt-names
	set intr_list "irq_out err_out"
	set interrupts ""
	set interrupt_names ""
	foreach irq ${intr_list} {
		set intr_info [get_intr_id $drv_handle $irq]
		if { [string match -nocase $intr_info "-1"] } {
			error "ERROR:${drv_handle}: $irq port is not connected"
		}
		if { [string match -nocase $interrupt_names ""] } {
			set interrupt_names "$irq"
			set interrupts "$intr_info"
		} else {
			append interrupt_names " " "$irq"
			append interrupts " " "$intr_info"
		}
	}
	hsi::utils::add_new_property $drv_handle "interrupts" int $interrupts
	hsi::utils::add_new_property $drv_handle "interrupt-names" stringlist $interrupt_names
}
