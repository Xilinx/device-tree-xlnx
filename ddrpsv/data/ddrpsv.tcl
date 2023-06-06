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
	set ddr [dict create is_ddr_low_0 0 is_ddr_low_1 0 is_ddr_low_2 0 is_ddr_low_3 0 is_ddr_ch_0 0 is_ddr_ch_1 0 is_ddr_ch_2 0 is_ddr_ch_3 0]
	set hbm [dict create is_hbm0_pc0 0 is_hbm0_pc1 0 is_hbm1_pc0 0 is_hbm1_pc1 0 is_hbm2_pc0 0 is_hbm2_pc1 0 is_hbm3_pc0 0 is_hbm3_pc1 0 is_hbm4_pc0 0 is_hbm4_pc1 0 is_hbm5_pc0 0 is_hbm5_pc1 0 is_hbm6_pc0 0 is_hbm6_pc1 0 is_hbm7_pc0 0 is_hbm7_pc1 0 is_hbm8_pc0 0 is_hbm8_pc1 0 is_hbm9_pc0 0 is_hbm9_pc1 0 is_hbm10_pc0 0 is_hbm10_pc1 0 is_hbm11_pc0 0 is_hbm11_pc1 0 is_hbm12_pc0 0 is_hbm12_pc1 0 is_hbm13_pc0 0 is_hbm13_pc1 0 is_hbm14_pc0 0 is_hbm14_pc1 0 is_hbm15_pc0 0 is_hbm15_pc1 0]

	set sw_proc [hsi::get_sw_processor]
	set periph [get_cells -hier $drv_handle]
	set interface_block_names [get_property ADDRESS_BLOCK [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph]]

	set i 0
	foreach block_name $interface_block_names {
		if {[string match "C*_DDR_LOW0*" $block_name]} {
			if {[dict get $ddr is_ddr_low_0] == 0} {
				set base_value_0 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_0 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_low_0 1
		} elseif {[string match "C*_DDR_LOW1*" $block_name]} {
			if {[dict get $ddr is_ddr_low_1] == 0} {
				set base_value_1 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_1 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_low_1 1
		} elseif {[string match "C*_DDR_LOW2*" $block_name]} {
			if {[dict get $ddr is_ddr_low_2] == 0} {
				set base_value_2 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_2 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_low_2 1
		} elseif {[string match "C*_DDR_LOW3*" $block_name]} {
			if {[dict get $ddr is_ddr_low_3] == "0"} {
				set base_value_3 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_3 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_low_3 1
		} elseif {[string match "C*_DDR_CH0*" $block_name]} {
			if {[dict get $ddr is_ddr_ch_0] == "0"} {
				set base_value_4 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_4 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_ch_0 1
		} elseif {[string match "C*_DDR_CH1*" $block_name]} {
			if {[dict get $ddr is_ddr_ch_1] == "0"} {
				set base_value_5 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_5 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_ch_1 1
		} elseif {[string match "C*_DDR_CH2*" $block_name]} {
			if {[dict get $ddr is_ddr_ch_2] == "0"} {
				set base_value_6 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_6 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_ch_2 1
		} elseif {[string match "C*_DDR_CH3*" $block_name]} {
			if {[dict get $ddr is_ddr_ch_3] == "0"} {
				set base_value_7 [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set high_value_7 [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set ddr is_ddr_ch_3 1
		} elseif {[string match "HBM0_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm0_pc0] == "0"} {
				set hbm0_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm0_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm0_pc0 1
		} elseif {[string match "HBM0_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm0_pc1] == "0"} {
				set hbm0_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm0_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm0_pc1 1
		} elseif {[string match "HBM1_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm1_pc0] == "0"} {
				set hbm1_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm1_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm1_pc0 1
		} elseif {[string match "HBM1_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm1_pc1] == "0"} {
				set hbm1_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm1_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm1_pc1 1
		} elseif {[string match "HBM2_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm2_pc0] == "0"} {
				set hbm2_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm2_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm2_pc0 1
		} elseif {[string match "HBM2_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm2_pc1] == "0"} {
				set hbm2_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm2_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm2_pc1 1
		} elseif {[string match "HBM3_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm3_pc0] == "0"} {
				set hbm3_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm3_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm3_pc0 1
		} elseif {[string match "HBM3_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm3_pc1] == "0"} {
				set hbm3_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm3_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm3_pc1 1
		} elseif {[string match "HBM4_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm4_pc0] == "0"} {
				set hbm4_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm4_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm4_pc0 1
		} elseif {[string match "HBM4_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm4_pc1] == "0"} {
				set hbm4_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm4_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm4_pc1 1
		} elseif {[string match "HBM5_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm5_pc0] == "0"} {
				set hbm5_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm5_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm5_pc0 1
		} elseif {[string match "HBM5_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm5_pc1] == "0"} {
				set hbm5_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm5_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm5_pc1 1
		} elseif {[string match "HBM6_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm6_pc0] == "0"} {
				set hbm6_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm6_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm6_pc0 1
		} elseif {[string match "HBM6_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm6_pc1] == "0"} {
				set hbm6_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm6_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm6_pc1 1
		} elseif {[string match "HBM7_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm7_pc0] == "0"} {
				set hbm7_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm7_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm7_pc0 1
		} elseif {[string match "HBM7_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm7_pc1] == "0"} {
				set hbm7_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm7_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm7_pc1 1
		} elseif {[string match "HBM8_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm8_pc0] == "0"} {
				set hbm8_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm8_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm8_pc0 1
		} elseif {[string match "HBM8_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm8_pc1] == "0"} {
				set hbm8_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm8_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm8_pc1 1
		} elseif {[string match "HBM9_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm9_pc0] == "0"} {
				set hbm9_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm9_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm9_pc0 1
		} elseif {[string match "HBM9_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm9_pc1] == "0"} {
				set hbm9_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm9_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm9_pc1 1
		} elseif {[string match "HBM10_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm10_pc0] == "0"} {
				set hbm10_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm10_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm10_pc0 1
		} elseif {[string match "HBM10_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm10_pc1] == "0"} {
				set hbm10_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm10_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm10_pc1 1
		} elseif {[string match "HBM11_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm11_pc0] == "0"} {
				set hbm11_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm11_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm11_pc0 1
		} elseif {[string match "HBM11_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm11_pc1] == "0"} {
				set hbm11_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm11_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm11_pc1 1
		} elseif {[string match "HBM12_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm12_pc0] == "0"} {
				set hbm12_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm12_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm12_pc0 1
		} elseif {[string match "HBM12_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm12_pc1] == "0"} {
				set hbm12_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm12_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm12_pc1 1
		} elseif {[string match "HBM13_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm13_pc0] == "0"} {
				set hbm13_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm13_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm13_pc0 1
		} elseif {[string match "HBM13_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm13_pc1] == "0"} {
				set hbm13_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm13_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm13_pc1 1
		} elseif {[string match "HBM14_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm14_pc0] == "0"} {
				set hbm14_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm14_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm14_pc0 1
		} elseif {[string match "HBM14_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm14_pc1] == "0"} {
				set hbm14_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm14_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm14_pc1 1
		} elseif {[string match "HBM15_*PC0*" $block_name]} {
			if {[dict get $hbm is_hbm15_pc0] == "0"} {
				set hbm15_pc0_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm15_pc0_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm15_pc0 1
		} elseif {[string match "HBM15_*PC1*" $block_name]} {
			if {[dict get $hbm is_hbm15_pc1] == "0"} {
				set hbm15_pc1_base [common::get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			}
			set hbm15_pc1_high [common::get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier $sw_proc] $periph] $i]]
			dict set hbm is_hbm15_pc1 1
		}
		incr i
	}
	set updat ""
	set updat_hbm ""
	set len [llength $updat]
	if {[dict get $ddr is_ddr_low_0] == 1} {
		set reg_val_0 [generate_reg_property $base_value_0 $high_value_0]
		set updat [lappend updat $reg_val_0]
	}
	if {[dict get $ddr is_ddr_low_1] == 1} {
		set reg_val_1 [generate_reg_property $base_value_1 $high_value_1]
		set updat [lappend updat $reg_val_1]
	}
	if {[dict get $ddr is_ddr_low_2] == 1} {
		set reg_val_2 [generate_reg_property $base_value_2 $high_value_2]
		set updat [lappend updat $reg_val_2]
	}
	if {[dict get $ddr is_ddr_low_3] == 1} {
		set reg_val_3 [generate_reg_property $base_value_3 $high_value_3]
		set updat [lappend updat $reg_val_3]
	}
	if {[dict get $ddr is_ddr_ch_0] == 1} {
		set reg_val_4 [generate_reg_property $base_value_4 $high_value_4]
		set updat [lappend updat $reg_val_4]
	}
	if {[dict get $ddr is_ddr_ch_1] == 1} {
		set reg_val_5 [generate_reg_property $base_value_5 $high_value_5]
		set updat [lappend updat $reg_val_5]
	}
	if {[dict get $ddr is_ddr_ch_2] == 1} {
		set reg_val_6 [generate_reg_property $base_value_6 $high_value_6]
		set updat [lappend updat $reg_val_6]
	}
	if {[dict get $ddr is_ddr_ch_3] == 1} {
		set reg_val_7 [generate_reg_property $base_value_7 $high_value_7]
		set updat [lappend updat $reg_val_7]
	}
	if {[dict get $hbm is_hbm0_pc0] == 1} {
		set reg_val_hbm0_pc0 [generate_reg_property $hbm0_pc0_base $hbm0_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm0_pc0]
	}
	if {[dict get $hbm is_hbm0_pc1] == 1} {
		set reg_val_hbm0_pc1 [generate_reg_property $hbm0_pc1_base $hbm0_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm0_pc1]
	}
	if {[dict get $hbm is_hbm1_pc0] == 1} {
		set reg_val_hbm1_pc0 [generate_reg_property $hbm1_pc0_base $hbm1_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm1_pc0]
	}
	if {[dict get $hbm is_hbm1_pc1] == 1} {
		set reg_val_hbm1_pc1 [generate_reg_property $hbm1_pc1_base $hbm1_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm1_pc1]
	}
	if {[dict get $hbm is_hbm2_pc0] == 1} {
		set reg_val_hbm2_pc0 [generate_reg_property $hbm2_pc0_base $hbm2_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm2_pc0]
	}
	if {[dict get $hbm is_hbm2_pc1] == 1} {
		set reg_val_hbm2_pc1 [generate_reg_property $hbm2_pc1_base $hbm2_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm2_pc1]
	}
	if {[dict get $hbm is_hbm3_pc0] == 1} {
		set reg_val_hbm3_pc0 [generate_reg_property $hbm3_pc0_base $hbm3_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm3_pc0]
	}
	if {[dict get $hbm is_hbm3_pc1] == 1} {
		set reg_val_hbm3_pc1 [generate_reg_property $hbm3_pc1_base $hbm3_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm3_pc1]
	}
	if {[dict get $hbm is_hbm4_pc0] == 1} {
		set reg_val_hbm4_pc0 [generate_reg_property $hbm4_pc0_base $hbm4_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm4_pc0]
	}
	if {[dict get $hbm is_hbm4_pc1] == 1} {
		set reg_val_hbm4_pc1 [generate_reg_property $hbm4_pc1_base $hbm4_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm4_pc1]
	}
	if {[dict get $hbm is_hbm5_pc0] == 1} {
		set reg_val_hbm5_pc0 [generate_reg_property $hbm5_pc0_base $hbm5_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm5_pc0]
	}
	if {[dict get $hbm is_hbm5_pc1] == 1} {
		set reg_val_hbm5_pc1 [generate_reg_property $hbm5_pc1_base $hbm5_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm5_pc1]
	}
	if {[dict get $hbm is_hbm6_pc0] == 1} {
		set reg_val_hbm6_pc0 [generate_reg_property $hbm6_pc0_base $hbm6_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm6_pc0]
	}
	if {[dict get $hbm is_hbm6_pc1] == 1} {
		set reg_val_hbm6_pc1 [generate_reg_property $hbm6_pc1_base $hbm6_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm6_pc1]
	}
	if {[dict get $hbm is_hbm7_pc0] == 1} {
		set reg_val_hbm7_pc0 [generate_reg_property $hbm7_pc0_base $hbm7_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm7_pc0]
	}
	if {[dict get $hbm is_hbm7_pc1] == 1} {
		set reg_val_hbm7_pc1 [generate_reg_property $hbm7_pc1_base $hbm7_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm7_pc1]
	}
	if {[dict get $hbm is_hbm8_pc0] == 1} {
		set reg_val_hbm8_pc0 [generate_reg_property $hbm8_pc0_base $hbm8_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm8_pc0]
	}
	if {[dict get $hbm is_hbm8_pc1] == 1} {
		set reg_val_hbm8_pc1 [generate_reg_property $hbm8_pc1_base $hbm8_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm8_pc1]
	}
	if {[dict get $hbm is_hbm9_pc0] == 1} {
		set reg_val_hbm9_pc0 [generate_reg_property $hbm9_pc0_base $hbm9_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm9_pc0]
	}
	if {[dict get $hbm is_hbm9_pc1] == 1} {
		set reg_val_hbm9_pc1 [generate_reg_property $hbm9_pc1_base $hbm9_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm9_pc1]
	}
	if {[dict get $hbm is_hbm10_pc0] == 1} {
		set reg_val_hbm10_pc0 [generate_reg_property $hbm10_pc0_base $hbm10_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm10_pc0]
	}
	if {[dict get $hbm is_hbm10_pc1] == 1} {
		set reg_val_hbm10_pc1 [generate_reg_property $hbm10_pc1_base $hbm10_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm10_pc1]
	}
	if {[dict get $hbm is_hbm11_pc0] == 1} {
		set reg_val_hbm11_pc0 [generate_reg_property $hbm11_pc0_base $hbm11_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm11_pc0]
	}
	if {[dict get $hbm is_hbm11_pc1] == 1} {
		set reg_val_hbm11_pc1 [generate_reg_property $hbm11_pc1_base $hbm11_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm11_pc1]
	}
	if {[dict get $hbm is_hbm12_pc0] == 1} {
		set reg_val_hbm12_pc0 [generate_reg_property $hbm12_pc0_base $hbm12_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm12_pc0]
	}
	if {[dict get $hbm is_hbm12_pc1] == 1} {
		set reg_val_hbm12_pc1 [generate_reg_property $hbm12_pc1_base $hbm12_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm12_pc1]
	}
	if {[dict get $hbm is_hbm13_pc0] == 1} {
		set reg_val_hbm13_pc0 [generate_reg_property $hbm13_pc0_base $hbm13_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm13_pc0]
	}
	if {[dict get $hbm is_hbm13_pc1] == 1} {
		set reg_val_hbm13_pc1 [generate_reg_property $hbm13_pc1_base $hbm13_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm13_pc1]
	}
	if {[dict get $hbm is_hbm14_pc0] == 1} {
		set reg_val_hbm14_pc0 [generate_reg_property $hbm14_pc0_base $hbm14_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm14_pc0]
	}
	if {[dict get $hbm is_hbm14_pc1] == 1} {
		set reg_val_hbm14_pc1 [generate_reg_property $hbm14_pc1_base $hbm14_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm14_pc1]
	}
	if {[dict get $hbm is_hbm15_pc0] == 1} {
		set reg_val_hbm15_pc0 [generate_reg_property $hbm15_pc0_base $hbm15_pc0_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm15_pc0]
	}
	if {[dict get $hbm is_hbm15_pc1] == 1} {
		set reg_val_hbm15_pc1 [generate_reg_property $hbm15_pc1_base $hbm15_pc1_high]
		set updat_hbm [lappend updat_hbm $reg_val_hbm15_pc1]
	}
	set len [llength $updat]
	set reg_val ""
	set len [expr {$len - 1}]
	if {$len > 0} {
		set reg_val [lindex $updat 0]
		append reg_val ">, "
		for {set k 1} {$k < $len} {incr k} {
			append reg_val "<[lindex $updat $k]>, "
		}
		append reg_val "<[lindex $updat $k]"
	}
	generate_mem_node $reg_val $parent_node "ddr"
	set len_hbm [llength $updat_hbm]
	set reg_val_hbm ""
	set len_hbm [expr {$len_hbm - 1}]
	if {$len_hbm > 0} {
		set reg_val_hbm [lindex $updat_hbm 0]
		append reg_val_hbm ">, "
		for {set j 1} {$j < $len_hbm} {incr j} {
			append reg_val_hbm "<[lindex $updat_hbm $j]>, "
		}
		append reg_val_hbm "<[lindex $updat_hbm $j]"
	}
	generate_mem_node $reg_val_hbm $parent_node "hbm"

}

proc generate_mem_node {reg_val parent_node mem_label} {
	if {[llength $reg_val]} {
		set higheraddr [expr [lindex $reg_val 0] << 32]
		set loweraddr [lindex $reg_val 1]
		set baseaddr [format 0x%x [expr {${higheraddr} + ${loweraddr}}]]
		regsub -all {^0x} $baseaddr {} baseaddr
		set memory_node [add_or_get_dt_node -n memory -l "memory_$mem_label" -u $baseaddr -p $parent_node]
		if {[catch {set dev_type [get_property CONFIG.device_type $drv_handle]} msg]} {
			set dev_type memory
		}
		if {[string_is_empty $dev_type]} {set dev_type memory}
		hsi::utils::add_new_dts_param "${memory_node}" "device_type" $dev_type string
		hsi::utils::add_new_dts_param "${memory_node}" "reg" $reg_val inthexlist
	}
}
