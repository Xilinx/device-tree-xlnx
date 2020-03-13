#
# (C) Copyright 2018 Xilinx, Inc.
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
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,ai_engine"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set intr_names "interrupt1"
	lappend intr_names "interrupt2"
	lappend intr_names "interrupt3"
	set intr_num "0x0 0x94 0x1>, <0x0 0x95 0x1>, <0x0 0x96 0x1"
	hsi::utils::add_new_dts_param "${node}" "interrupt-names" $intr_names stringlist
	hsi::utils::add_new_dts_param ${node} "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${node}" "interrupt-parent" gic reference

	set bus_node "amba_pl"
	set dts_file [current_dt_tree]
	set aie_npi_node [add_or_get_dt_node -n "aie-npi" -l aie_npi -u f70a0000 -d $dts_file -p $bus_node]
	hsi::utils::add_new_dts_param "${aie_npi_node}" "compatible" "xlnx,ai-engine-npi" stringlist
	set aie_npi_reg "0x0 0xf70a0000 0x0 0x1000"
	hsi::utils::add_new_dts_param "${aie_npi_node}" "reg" $aie_npi_reg intlist
}
