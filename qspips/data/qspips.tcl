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
	foreach i [get_sw_cores device_tree] {
	set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
	if {[file exists $common_tcl_file]} {
		source $common_tcl_file
		break
		}
	}

	set slave [get_cells -hier $drv_handle]
	set qspi_mode [hsi::utils::get_ip_param_value $slave "C_QSPI_MODE"]
	if { $qspi_mode == 2} {
		set is_dual 1
	} else {
		set is_dual 0
	}
	set_property CONFIG.is-dual $is_dual $drv_handle
	set bus_width [get_property CONFIG.C_QSPI_BUS_WIDTH [get_cells -hier $drv_handle]]

	switch $bus_width {
		"3" {
			hsi::utils::add_new_property $drv_handle "spi-tx-bus-width" int 8
			hsi::utils::add_new_property $drv_handle "spi-rx-bus-width" int 8
		}
		"2" {
			hsi::utils::add_new_property $drv_handle "spi-tx-bus-width" int 4
			hsi::utils::add_new_property $drv_handle "spi-rx-bus-width" int 4
		}
		"1" {
			hsi::utils::add_new_property $drv_handle "spi-tx-bus-width" int 2
			hsi::utils::add_new_property $drv_handle "spi-rx-bus-width" int 2
		}
		"0" {
			hsi::utils::add_new_property $drv_handle "spi-tx-bus-width" int 1
			hsi::utils::add_new_property $drv_handle "spi-rx-bus-width" int 1
		}
		default {
			dtg_warning "Unsupported bus_width:$bus_width"
		}
	}
    # these are board level information
    # set primary_flash [hsi::utils::add_new_child_node $drv_handle "primary_flash"]
    # hsi::utils::add_new_property $primary_flash "dts.device_type" string "ps7-qspi"
    # hsi::utils::add_new_property $primary_flash reg hexint 0
    # hsi::utils::add_new_property $primary_flash spi-max-frequency int 50000000
}
