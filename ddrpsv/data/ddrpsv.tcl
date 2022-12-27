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
	set slave [get_cells -hier ${drv_handle}]
	set master_dts [get_property CONFIG.master_dts [get_os]]
	set cur_dts [current_dt_tree]
	set master_dts_obj [get_dt_trees ${master_dts}]
	set_cur_working_dts $master_dts
	set parent_node [add_or_get_dt_node -n / -d ${master_dts}]
	set is_ddr_low_0 0
	set is_ddr_low_1 0
	set is_ddr_low_2 0
	set is_ddr_low_3 0
	set is_ddr_ch_0 0
	set is_ddr_ch_1 0
	set is_ddr_ch_2 0
	set is_ddr_ch_3 0
	set is_hbm_0 0
	set is_hbm_1 0
	set is_hbm_2 0
	set is_hbm_3 0

	set sw_proc [hsi::get_sw_processor]
	set periph [get_cells -hier $drv_handle]
	set interface_block_names [get_property ADDRESS_BLOCK [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph]]

	set i 0
	foreach block_name $interface_block_names {
		if {[string match "C*_DDR_LOW0*" $block_name]} {
			if {$is_ddr_low_0 == 0} {
				set base_value_0 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_0 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_low_0 1
		} elseif {[string match "C*_DDR_LOW1*" $block_name]} {
			if {$is_ddr_low_1 == 0} {
				set base_value_1 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_1 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_low_1 1
		} elseif {[string match "C*_DDR_LOW2*" $block_name]} {
			if {$is_ddr_low_2 == 0} {
				set base_value_2 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_2 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_low_2 1
		} elseif {[string match "C*_DDR_LOW3*" $block_name]} {
			if {$is_ddr_low_3 == "0"} {
				set base_value_3 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_3 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_low_3 1
		} elseif {[string match "C*_DDR_CH0*" $block_name]} {
			if {$is_ddr_ch_0 == "0"} {
				set base_value_4 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_4 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_ch_0 1
		} elseif {[string match "C*_DDR_CH1*" $block_name]} {
			if {$is_ddr_ch_1 == "0"} {
				set base_value_5 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_5 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_ch_1 1
		} elseif {[string match "C*_DDR_CH2*" $block_name]} {
			if {$is_ddr_ch_2 == "0"} {
				set base_value_6 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_6 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_ch_2 1
		} elseif {[string match "C*_DDR_CH3*" $block_name]} {
			if {$is_ddr_ch_3 == "0"} {
				set base_value_7 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_7 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_ddr_ch_3 1
		} elseif {[string match "HBM0*" $block_name]} {
			if {$is_hbm_0 == 0} {
				set hbm_base_value_0 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm_high_value_0 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_hbm_0 1
		} elseif {[string match "HBM1*" $block_name]} {
			if {$is_hbm_1 == 0} {
				set hbm_base_value_1 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm_high_value_1 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_hbm_1 1
		} elseif {[string match "HBM2*" $block_name]} {
			if {$is_hbm_2 == 0} {
				set hbm_base_value_2 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm_high_value_2 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_hbm_2 1
		} elseif {[string match "HBM3*" $block_name]} {
			if {$is_hbm_3 == 0} {
				set hbm_base_value_3 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm_high_value_3 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			set is_hbm_3 1
		}
		incr i
	}
	set updat ""
	if {$is_ddr_low_0 == 1} {
		set reg_val_0 [generate_reg_property $base_value_0 $high_value_0]
		set updat [lappend updat $reg_val_0]
	}
	if {$is_ddr_low_1 == 1} {
		set reg_val_1 [generate_reg_property $base_value_1 $high_value_1]
		set updat [lappend updat $reg_val_1]
	}
	if {$is_ddr_low_2 == 1} {
		set reg_val_2 [generate_reg_property $base_value_2 $high_value_2]
		set updat [lappend updat $reg_val_2]
	}
	if {$is_ddr_low_3 == 1} {
		set reg_val_3 [generate_reg_property $base_value_3 $high_value_3]
		set updat [lappend updat $reg_val_3]
	}
	if {$is_ddr_ch_0 == 1} {
		set reg_val_4 [generate_reg_property $base_value_4 $high_value_4]
		set updat [lappend updat $reg_val_4]
	}
	if {$is_ddr_ch_1 == 1} {
		set reg_val_5 [generate_reg_property $base_value_5 $high_value_5]
		set updat [lappend updat $reg_val_5]
	}
	if {$is_ddr_ch_2 == 1} {
		set reg_val_6 [generate_reg_property $base_value_6 $high_value_6]
		set updat [lappend updat $reg_val_6]
	}
	if {$is_ddr_ch_3 == 1} {
		set reg_val_7 [generate_reg_property $base_value_7 $high_value_7]
		set updat [lappend updat $reg_val_7]
	}
	if {$is_hbm_0 == 1} {
		set hbm_reg_val_0 [generate_reg_property $hbm_base_value_0 $hbm_high_value_0]
		set updat [lappend updat $hbm_reg_val_0]
	}
	if {$is_hbm_1 == 1} {
		set hbm_reg_val_1 [generate_reg_property $hbm_base_value_1 $hbm_high_value_1]
		set updat [lappend updat $hbm_reg_val_1]
	}
	if {$is_hbm_2 == 1} {
		set hbm_reg_val_2 [generate_reg_property $hbm_base_value_2 $hbm_high_value_2]
		set updat [lappend updat $hbm_reg_val_2]
	}
	if {$is_hbm_3 == 1} {
		set hbm_reg_val_3 [generate_reg_property $hbm_base_value_3 $hbm_high_value_3]
		set updat [lappend updat $hbm_reg_val_3]
	}
	set len [llength $updat]
	set reg_val ""
	switch $len {
		"1" {
			set reg_val [lindex $updat 0]
		}
		"2" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]"
		}
		"3" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]"
		}
		"4" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]"
		}
		"5" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]"
		}
		"6" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]"
		}
		"7" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]"
		}
		"8" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]>, <[lindex $updat 7]"
		}
		"9" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]>, <[lindex $updat 7]>, <[lindex $updat 8]"
		}
		"10" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]>, <[lindex $updat 7]>, <[lindex $updat 8]>, <[lindex $updat 9]"
		}
		"11" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]>, <[lindex $updat 7]>, <[lindex $updat 8]>, <[lindex $updat 9]>, <[lindex $updat 10]"
		}
		"12" {
			set reg_val [lindex $updat 0]
			append reg_val ">, <[lindex $updat 1]>, <[lindex $updat 2]>, <[lindex $updat 3]>, <[lindex $updat 4]>, <[lindex $updat 5]>, <[lindex $updat 6]>, <[lindex $updat 7]>, <[lindex $updat 8]>, <[lindex $updat 9]>, <[lindex $updat 10]>, <[lindex $updat 11]"
		}
	}

	if {[llength $reg_val]} {
		set higheraddr [expr [lindex $reg_val 0] << 32]
		set loweraddr [lindex $reg_val 1]
		set baseaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
		regsub -all {^0x} $baseaddr {} baseaddr
		set memory_node [add_or_get_dt_node -n memory -l "memory$drv_handle" -u $baseaddr -p $parent_node]
		if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		hsi::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string
		hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg_val inthexlist
	}
}

proc generate_reg_property {base high} {
	set size [format 0x%x [expr {${high} - ${base} + 1}]]

	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psv_cortexa72"]} {
		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
			set temp $base
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_base "0x[string range $temp $rem $len]"
			set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_base [format 0x%08x $low_base]
		} else {
			set high_base $base
			set low_base 0x0
		}
		if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
			set temp $size
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_size "0x[string range $temp $rem $len]"
			set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_size [format 0x%08x $low_size]
		} else {
			set high_size $size
			set low_size 0x0
		}
		set reg "$low_base $high_base $low_size $high_size"
	} else {
		set reg "0x0 $base 0x0 $size"
	}
	return $reg
}
