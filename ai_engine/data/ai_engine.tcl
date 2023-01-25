#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

variable aie_array_cols_start
variable aie_array_cols_num
proc generate_aie_array_device_info {node drv_handle bus_node} {
	set aie_array_id 0
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,ai-engine-v2.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist

	#set default values for S80 device
	set hw_gen "AIE"
	set aie_rows_start 1
	set aie_rows_num 8
	set mem_rows_start 0
	set mem_rows_num 0
	set shim_rows_start 0
	set shim_rows_num 1
	set ::aie_array_cols_start 0
	set ::aie_array_cols_num 50

	# override the above default values if AIE primitives are available in
	# xsa
	set CommandExists [ namespace which hsi::get_hw_primitives]
	if {$CommandExists != ""} {
		set aie_prop [hsi::get_hw_primitives aie]
		if {$aie_prop != ""} {
			puts "INFO: Reading AIE hardware properties from XSA."

			set hw_gen [get_property HWGEN [hsi::get_hw_primitives aie]]
			set aie_rows [get_property AIETILEROWS [hsi::get_hw_primitives aie]]
			set mem_rows [get_property MEMTILEROW [hsi::get_hw_primitives aie]]
			set shim_rows [get_property SHIMROW [hsi::get_hw_primitives aie]]
			set ::aie_array_cols_num [get_property AIEARRAYCOLUMNS [hsi::get_hw_primitives aie]]

			set aie_rows_start [lindex [split $aie_rows ":"] 0]
			set aie_rows_num [lindex [split $aie_rows ":"] 1]
			set mem_rows_start [lindex [split $mem_rows ":"] 0]
			if {$mem_rows_start==-1} {
				set mem_rows_start 0
			}
			set mem_rows_num [lindex [split $mem_rows ":"] 1]
			set shim_rows_start [lindex [split $shim_rows ":"] 0]
			set shim_rows_num [lindex [split $shim_rows ":"] 1]

		} else {
			dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
		}
	} else {
		dtg_warning "$drv_handle: AIE hardware properties are not available in XSA, using defaults."
	}

	if {$hw_gen=="AIE"} {
		append aiegen "/bits/ 8 <0x1>"
	} elseif {$hw_gen=="AIEML"} {
		append aiegen "/bits/ 8 <0x2>"
	}
	hsi::utils::add_new_dts_param "${node}" "xlnx,aie-gen" $aiegen noformating
	append shimrows "/bits/ 8 <${shim_rows_start} ${shim_rows_num}>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,shim-rows" $shimrows noformating
	append corerows "/bits/ 8 <${aie_rows_start} ${aie_rows_num}>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,core-rows" $corerows noformating
	append memrows "/bits/ 8 <$mem_rows_start $mem_rows_num>"
	hsi::utils::add_new_dts_param "${node}" "xlnx,mem-rows" $memrows noformating

	set name [get_property NAME [get_current_part $drv_handle]]
	set part_num [string range $name 0 7]

	if {$part_num == "xcvp2502"} {
		#s100
		set power_domain "&versal_firmware 0x18225072"
	} elseif {$part_num == "xcvp2802"} {
		#s200
		set power_domain "&versal_firmware 0x18227072"
	} else {
		set power_domain "&versal_firmware 0x18224072"
	}

	hsi::utils::add_new_dts_param "${node}" "power-domains" $power_domain intlist
	hsi::utils::add_new_dts_param "${node}" "#address-cells" "2" intlist
	hsi::utils::add_new_dts_param "${node}" "#size-cells" "2" intlist
	hsi::utils::add_new_dts_param "${node}" "ranges" "" boolean

	set ai_clk_node [add_or_get_dt_node -n "aie_core_ref_clk_0" -l "aie_core_ref_clk_0" -p ${bus_node}]
	set clk_freq [get_property CONFIG.AIE_CORE_REF_CTRL_FREQMHZ [get_cells -hier $drv_handle]]
	set clk_freq [expr ${clk_freq} * 1000000]
	hsi::utils::add_new_dts_param "${ai_clk_node}" "compatible" "fixed-clock" stringlist
	hsi::utils::add_new_dts_param "${ai_clk_node}" "#clock-cells" 0 int
	hsi::utils::add_new_dts_param "${ai_clk_node}" "clock-frequency" $clk_freq int

	set clocks "aie_core_ref_clk_0"
	set_drv_prop $drv_handle clocks "$clocks" reference
	hsi::utils::add_new_dts_param "${node}" "clock-names" "aclk0" stringlist

	return ${node}
}


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
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set RpRm [hsi::utils::get_rp_rm_for_drv $drv_handle]
		regsub -all { } $RpRm "" RpRm
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}

	generate_aie_array_device_info ${node} ${drv_handle} ${bus_node}

	set ip [get_cells -hier $drv_handle]
	set unit_addr [get_baseaddr ${ip} no_prefix]
	set aperture_id 0
	set aperture_node [add_or_get_dt_node -n "aie_aperture" -u "${unit_addr}" -l "aie_aperture_${aperture_id}" -p ${node}]

	set reg [get_property CONFIG.reg ${drv_handle}]
	hsi::utils::add_new_dts_param "${aperture_node}" "reg" $reg noformat


	set name [get_property NAME [get_current_part $drv_handle]]
	set part_num [string range $name 0 7]
	set part_num_v70 [string range $name 0 4]

	if {$part_num == "xcvp2502"} {
		#s100
		set power_domain "&versal_firmware 0x18225072"
		hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,device-name" "100" int
		set aperture_nodeid 0x18801000
	} elseif {$part_num == "xcvp2802"} {
		#s200
		set power_domain "&versal_firmware 0x18227072"
		hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,device-name" "200" int
		set aperture_nodeid 0x18803000
	} elseif {$part_num_v70 == "xcv70"} {
		#v70
		set power_domain "&versal_firmware 0x18224072"
		hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,device-name" "0" int
		set aperture_nodeid 0x18800000
	} else {
		#NON SSIT devices
		set intr_names "interrupt1"
		lappend intr_names "interrupt2"
		lappend intr_names "interrupt3"
		set intr_num "0x0 0x94 0x4>, <0x0 0x95 0x4>, <0x0 0x96 0x4"
		set power_domain "&versal_firmware 0x18224072"
		hsi::utils::add_new_dts_param "${aperture_node}" "interrupt-names" $intr_names stringlist
		hsi::utils::add_new_dts_param "${aperture_node}" "interrupts" $intr_num intlist
		hsi::utils::add_new_dts_param "${aperture_node}" "interrupt-parent" gic reference
		hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,device-name" "0" int
		set aperture_nodeid 0x18800000
	}

	hsi::utils::add_new_dts_param "${aperture_node}" "power-domains" $power_domain intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "#address-cells" "2" intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "#size-cells" "2" intlist

	hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,columns" "$::aie_array_cols_start $::aie_array_cols_num" intlist
	hsi::utils::add_new_dts_param "${aperture_node}" "xlnx,node-id" "${aperture_nodeid}" intlist

}
