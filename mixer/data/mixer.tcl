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
	set compatible [append compatible " " "xlnx,mixer-3.0 xlnx,mixer-4.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set mixer_ip [get_cells -hier $drv_handle]
	set num_layers [get_property CONFIG.NR_LAYERS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,num-layers" $num_layers int
	set samples_per_clock [get_property CONFIG.SAMPLES_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,ppc" $samples_per_clock int
	set dma_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dma-addr-width" $dma_addr_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,bpc" $max_data_width int
	set logo_layer [get_property CONFIG.LOGO_LAYER [get_cells -hier $drv_handle]]
	if {[string match -nocase $logo_layer "true"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,logo-layer" ""  boolean
	}
}

