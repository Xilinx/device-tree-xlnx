#
# (C) Copyright 2019-2022 Xilinx, Inc.
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
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set master_dts [get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]
	set_cur_working_dts $master_dts
	set parent_node [add_or_get_dt_node -n / -d ${master_dts}]

	set sw_proc [hsi::get_sw_processor]
	set periph [get_cells -hier $drv_handle]
	set interface_block_names [get_property ADDRESS_BLOCK [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph]]

	set Supported_channels { \
		"C*_DDR_LOW0*" "C*_DDR_LOW1*" "C*_DDR_LOW2*" "C*_DDR_LOW3*" "C*_DDR_CH0*" "C*_DDR_CH1*" "C*_DDR_CH2*"  "C*_DDR_CH3*" \
		"HBM0_*PC0*" "HBM0_*PC1*" "HBM1_*PC0*" "HBM1_*PC1*" "HBM2_*PC0*" "HBM2_*PC1*" "HBM3_*PC0*" "HBM3_*PC1*" "HBM4_*PC0*" \
		"HBM4_*PC1*" "HBM5_*PC0*" "HBM5_*PC1*" "HBM6_*PC0*" "HBM6_*PC1*" "HBM7_*PC0*" "HBM7_*PC1*" "HBM8_*PC0*" "HBM8_*PC1*" \
		"HBM9_*PC0*" "HBM9_*PC1*" "HBM10_*PC0*"  "HBM10_*PC1*" "HBM11_*PC0*" "HBM11_*PC1*" "HBM12_*PC0*" "HBM12_*PC1*" "HBM13_*PC0*" \
		"HBM13_*PC1*" "HBM14_*PC0*" "HBM14_*PC1*" "HBM15_*PC0*" "HBM15_*PC1*" \
	}
	set Configured_channels [dict create]

	set i 0
	foreach block_name $interface_block_names {
		foreach channel $Supported_channels {
			if {[string match $channel $block_name]} {
				# Remove C* for ddr case for unique dict key
				regsub -all {^C[0-9]_} $block_name {} trim_blockname
				set memlabel "ddr"
				if {[string match -nocase "*HBM*" $block_name]} {
					set memlabel "hbm"
				}
				set base_addr [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
				if {[dict exists $Configured_channels $memlabel] && [dict exists $Configured_channels $memlabel $trim_blockname]} {
					set base_addrtmp [dict get $Configured_channels $memlabel $trim_blockname "base_addr"]
					if {[string compare $base_addrtmp $base_addr] < 0 } {
						set base_addr $base_addrtmp
					}
				}
				set high_addr [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
				dict set Configured_channels $memlabel $trim_blockname "base_addr" $base_addr
				dict set Configured_channels $memlabel $trim_blockname "high_addr" $high_addr
			}
		}
		incr i
	}

	foreach memlabel [dict keys $Configured_channels] {
		set Reg_values ""
		foreach chkey [dict keys [dict get $Configured_channels $memlabel]] {
			set base_addr [dict get $Configured_channels $memlabel $chkey "base_addr"]
			set high_addr [dict get $Configured_channels $memlabel $chkey "high_addr"]
			set Reg_values [lappend Reg_values [generate_reg_property $base_addr $high_addr]]
		}
		if {[llength $Reg_values]} {
			set Reg_values [join $Reg_values ">, <"]
			generate_mem_node $Reg_values $parent_node $memlabel $drv_handle
		}
	}
}


proc generate_mem_node {reg_val parent_node mem_label drv_handle} {
	if {[llength $reg_val]} {
		set higheraddr [expr [lindex $reg_val 0] << 32]
		set loweraddr [lindex $reg_val 1]
		set baseaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
		regsub -all {^0x} $baseaddr {} baseaddr
		set memory_node [add_or_get_dt_node -n memory -l "memory$drv_handle\_$mem_label" -u $baseaddr -p $parent_node]
		if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		hsi::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string
		hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg_val inthexlist
	}
}
