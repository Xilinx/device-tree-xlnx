#
# (C) Copyright 2014-2015 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

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
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,axi-traffic-gen"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	# the interrupt related setting is only required for AXI4 protocol only
	set atg_mode [get_property "CONFIG.C_ATG_MODE" [get_cells -hier $drv_handle]]
	if { ![string match -nocase $atg_mode "AXI4"] } {
		return 0
	}
	set proc_type [get_sw_proc_prop IP_NAME]
	# set up interrupt-names
	set intr_list "irq_out err_out"
	set interrupts ""
	set interrupt_names ""
	foreach irq ${intr_list} {
		set intr_info [get_intr_id $drv_handle $irq]
		if { [string match -nocase $intr_info "-1"] } {
			if {[string match -nocase $proc_type "psv_cortexa72"]} {
				continue
			} else {
				error "ERROR: ${drv_handle}: $irq port is not connected"
			}
		}
		if { [string match -nocase $interrupt_names ""] } {
			if {[string match -nocase $irq "irq_out"]} {
				set irq "irq-out"
			}
			if {[string match -nocase $irq "err_out"]} {
				set irq "err-out"
			}
			set interrupt_names "$irq"
			set interrupts "$intr_info"
		} else {
			if {[string match -nocase $irq "irq_out"]} {
				set irq "irq-out"
			}
			if {[string match -nocase $irq "err_out"]} {
				set irq "err-out"
			}
			append interrupt_names " " "$irq"
			append interrupts " " "$intr_info"
		}
	}
	hsi::utils::add_new_property $drv_handle "interrupts" int $interrupts
	hsi::utils::add_new_property $drv_handle "interrupt-names" stringlist $interrupt_names
}
