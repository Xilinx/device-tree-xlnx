#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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
	set compatible [append compatible " " "xlnx,xps-spi-2.00.a"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "xlnx,num-ss-bits"
	set_drv_conf_prop $drv_handle "C_NUM_SS_BITS" "num-cs"
	set_drv_conf_prop $drv_handle "C_NUM_TRANSFER_BITS" "bits-per-word" int
	set_drv_conf_prop $drv_handle "C_FIFO_DEPTH" "fifo-size" int
	set_drv_conf_prop $drv_handle "C_SPI_MODE" "xlnx,spi-mode" int
	set_drv_conf_prop $drv_handle "C_USE_STARTUP" "xlnx,startup-block" boolean
}
