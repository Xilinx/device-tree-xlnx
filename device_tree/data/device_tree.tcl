#
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
#
# Michal SIMEK <monstr@monstr.eu>
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

foreach i [get_sw_cores device_tree] {
    set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
    if {[file exists $common_tcl_file]} {
        source $common_tcl_file
        break
    }
}

proc get_ip_prop {drv_handle pram} {
    set ip [get_cells -hier $drv_handle]
    set value [get_property ${pram} $ip]
    return $value
}

proc inc_os_prop {drv_handle os_conf_dev_var var_name conf_prop} {
    set ip_check "False"
    set os_ip [get_property ${os_conf_dev_var} [get_os]]
    if {![string match -nocase "" $os_ip]} {
        set os_ip [get_property ${os_conf_dev_var} [get_os]]
        set ip_check "True"
    }

    set count [hsi::utils::get_os_parameter_value $var_name]
    if {[llength $count] == 0} {
        if {[string match -nocase "True" $ip_check]} {
            set count 1
        } else {
            set count 0
        }
    }

    if {[string match -nocase "True" $ip_check]} {
        set ip [get_cells -hier $drv_handle]
        if {[string match -nocase $os_ip $ip]} {
            set ip_type [get_property IP_NAME $ip]
            set_property ${conf_prop} 0 $drv_handle
            return
        }
    }

    set_property $conf_prop $count $drv_handle
    incr count
    ::hsi::utils::set_os_parameter_value $var_name $count
}

proc gen_count_prop {drv_handle data_dict} {
    dict for {dev_type dev_conf_mapping} [dict get $data_dict] {
        set os_conf_dev_var [dict get $data_dict $dev_type "os_device"]
        set valid_ip_list [dict get $data_dict $dev_type "ip"]
        set drv_conf [dict get $data_dict $dev_type "drv_conf"]
        set os_count_name [dict get $data_dict $dev_type "os_count_name"]

        set slave [get_cells -hier $drv_handle]
        set iptype [get_property IP_NAME $slave]
        if {[lsearch $valid_ip_list $iptype] < 0} {
            continue
        }

        set irq_chk [dict get $data_dict $dev_type "irq_chk"]
        if {![string match -nocase "false" $irq_chk]} {
            set irq_id [::hsi::utils::get_interrupt_id $slave $irq_chk]
            if {[llength $irq_id] < 0} {
                dtg_warning "Fail to located interrupt pin - $irq_chk. The $drv_conf is not set for $dev_type"
                continue
            }
        }

        inc_os_prop $drv_handle $os_conf_dev_var $os_count_name $drv_conf
    }
}

proc gen_dev_conf {} {
    # data to populated certain configs for different devices
    set data_dict {
        uart {
            os_device "CONFIG.console_device"
            ip "axi_uartlite axi_uart16550 ps7_uart psu_uart psv_uart psx_sbsauart"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        mdm_uart {
            os_device "CONFIG.console_device"
            ip "mdm"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
            irq_chk "Interrupt"
        }
        syace {
            os_device "sysace_device"
            ip "axi_sysace"
            os_count_name "sysace_count"
            drv_conf "CONFIG.port-number"
            irq_chk "false"
        }
        traffic_gen {
            os_device "trafficgen_device"
            ip "axi_traffic_gen"
            os_count_name "trafficgen_count"
            drv_conf "CONFIG.xlnx,device-id"
            irq_chk "false"
        }
    }
    # update CONFIG.<para> for each driver when match driver is found
    foreach drv [get_drivers] {
        gen_count_prop $drv $data_dict
    }
}

# For calling from top level BSP
proc bsp_drc {os_handle} {
}

# If standalone purpose
proc device_tree_drc {os_handle} {
    bsp_drc $os_handle
    hsi::utils::add_new_child_node $os_handle "global_params"
}

proc extract_dts_name {override value} {
    set idx [lsearch -exact $override $value]
    set var [lreplace $override $idx $idx]
    return $var
}

proc gen_edac_node {} {
	set dts_file [get_property CONFIG.pcw_dts [get_os]]
	set edac_node [add_or_get_dt_node -n &xilsem_edac -d $dts_file]
	set pspmc [get_cells -hier -filter {IP_NAME == "pspmc"}]
	if {[llength $pspmc]} {
		if { [get_property CONFIG.SEM_MEM_SCAN $pspmc] || [get_property CONFIG.SEM_NPI_SCAN $pspmc] } {
			hsi::utils::add_new_dts_param "${edac_node}" "status" "okay" string
		}
	}
}

proc gen_ddrmc_node {} {
	set dts_file [get_property CONFIG.pcw_dts [get_os]]
	set ddrmc [get_cells -hier -filter {IP_NAME == "noc_mc_ddr4"}]
	if {[llength $ddrmc]} {
		set i 0
		foreach mc $ddrmc {
			set ddrmc_node [add_or_get_dt_node -n &mc$i -d $dts_file]
			if { [get_property CONFIG.MC_ECC $mc] } {
				hsi::utils::add_new_dts_param "${ddrmc_node}" "status" "okay" string
			}
			incr i
		}
	}

}

proc gen_sata_laneinfo {} {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {$remove_pl} {
		return 0
	}

	foreach ip [get_cells] {
		set slane 0
		set freq {}
		set ip_type [get_property IP_TYPE [get_cells $ip]]
		#if {$ip_type eq ""} {
		#	set ps $ip
		#}
		set ps $ip
	}

	set param0 "/bits/ 8 <0x18 0x40 0x18 0x28>"
	set param1 "/bits/ 8 <0x06 0x14 0x08 0x0E>"
	set param2 "/bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param3 "/bits/ 16 <0x96A4 0x3FFC>"

	set param4 "/bits/ 8 <0x1B 0x4D 0x18 0x28>"
	set param5 "/bits/ 8 <0x06 0x19 0x08 0x0E>"
	set param6 " /bits/ 8 <0x13 0x08 0x4A 0x06>"
	set param7 "/bits/ 16 <0x96A4 0x3FFC>"

	set param_list "ceva,p%d-cominit-params ceva,p%d-comwake-params ceva,p%d-burst-params ceva,p%d-retry-params"
	while {$slane < 2} {
		if {[get_property CONFIG.PSU__SATA__LANE$slane\__ENABLE [get_cells $ps]] == 1} {
			set gt_lane [get_property CONFIG.PSU__SATA__LANE$slane\__IO [get_cells $ps]]
			regexp [0-9] $gt_lane gt_lane
			lappend freq [get_property CONFIG.PSU__SATA__REF_CLK_FREQ [get_cells $ps]]
		} else {
			lappend freq 0
			}
		incr slane
	}

	foreach {i j} $freq {
		set i [expr {$i ? $i : $j}]
		set j [expr {$j ? $j : $i}]
	}

	lset freq 0 $i
	lset freq 1 $j
	set dts_file [get_property CONFIG.pcw_dts [get_os]]
	set sata_node [add_or_get_dt_node -n &sata -d $dts_file]
	set hsi_version [get_hsi_version]
	set ver [split $hsi_version "."]
	set version [lindex $ver 0]

	set slane 0
	while {$slane < 2} {
		set f [lindex $freq $slane]
		set count 0
		if {$f != 0} {
			while {$count < 4} {
				if {$version < 2018} {
					dtg_warning "quotes to be removed or use 2018.1 version for $sata_node params param0..param7"
				}
				set val_name [format [lindex $param_list $count] $slane]
				switch $count {
					"0" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param0 noformating
					}
					"1" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param1 noformating
					}
					"2" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param2 noformating
					}
					"3" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param3 noformating
					}
					"4" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param4 noformating
					}
					"5" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param5 noformating
					}
					"6" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param6 noformating
					}
					"7" {
					hsi::utils::add_new_dts_param $sata_node $val_name $param7 noformating
					}
				}
			incr count
			}
		}
	incr slane
	}
}

proc gen_ext_axi_interface {}  {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {$remove_pl} {
		return 0
	}
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psu_cortexa53"]} {
		set ext_axi_intf [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]] -filter {INSTANCE ==""}]
		set hsi_version [get_hsi_version]
		set ver [split $hsi_version "."]
		set version [lindex $ver 0]
		set intf_count 0
		foreach drv_handle $ext_axi_intf {
			set base [string tolower [get_property BASE_VALUE $drv_handle]]
			set high [string tolower [get_property HIGH_VALUE $drv_handle]]
			set size [format 0x%x [expr {${high} - ${base} + 1}]]
			set default_dts [get_property CONFIG.pcw_dts [get_os]]
			set root_node [add_or_get_dt_node -n / -d ${default_dts}]
			if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
				set temp $base
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_base "0x[string range $temp $rem $len]"
				set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_base [format 0x%08x $low_base]
				if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
					set temp $size
					set temp [string trimleft [string trimleft $temp 0] x]
					set len [string length $temp]
					set rem [expr {${len} - 8}]
					set high_size "0x[string range $temp $rem $len]"
					set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
					set low_size [format 0x%08x $low_size]
					set reg "$low_base $high_base $low_size $high_size"
				} else {
					set reg "$low_base $high_base 0x0 $size"
				}
			} else {
				set reg "0x0 $base 0x0 $size"
			}
			regsub -all {^0x} $base {} base
			set ext_int_node [add_or_get_dt_node -n $drv_handle -l $drv_handle$intf_count -u $base -d $default_dts -p $root_node]
			hsi::utils::add_new_dts_param $ext_int_node "reg" "$reg" intlist
			incr intf_count
			if {$version >= 2018} {
				hsi::utils::add_new_dts_param "${ext_int_node}" "/* This is a external AXI interface, user may need to update the entries */" "" comment
			}
		}
	}
}

proc gen_include_headers {} {
	foreach i [get_sw_cores device_tree] {
		set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
		set kernel_ver [get_property CONFIG.kernel_version [get_os]]
		set includes_dir [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/include"]
		set dir_path "./"
		# Copy full include directory to dt WS
		if {[file exists $includes_dir]} {
			file delete -force -- $dir_path/include
			file copy -force $includes_dir $dir_path
		}
	}
}

proc gen_include_dtfile {args} {
	set kernel_dtsi [lindex $args 0]
	set fp [open $kernel_dtsi r]
	set file_data [read $fp]
	set data [split $file_data "\n"]
	set include_regexp {^#include \".*\.dts.*\"$}
	foreach line $data {
		if {[regexp $include_regexp $line matched]} {
			set include_dt [lindex [split $line " "] 1]
			regsub -all " |\t|;|\"" $include_dt {} include_dt
			foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/*]] {
				# NOTE: ./ works only if we did not change our directory
				if {[regexp $include_dt $file match]} {
					file copy -force $file ./
					gen_include_dtfile "$file"
                                        break
				}
			}
		}
	}
}

proc gen_board_info {} {
    # periph_type_overrides = {BOARD KC705 full/lite} or {BOARD ZYNQ} or {BOARD ZC1751 ES2/ES1}
    set overrides [get_property CONFIG.periph_type_overrides [get_os]]
    if {[string match $overrides ""]} {
		return
    }
    foreach i [get_sw_cores device_tree] {
    foreach override $overrides {
	if {[lindex $override 0] == "BOARD"} {
		set first_element [lindex $override 0]
		set dtsi_file [lindex $override 1]
		if {[file exists $dtsi_file]} {
			set dir [pwd]
			set pathtype [file pathtype $dtsi_file]
			if {[string match -nocase $pathtype "relative"]} {
				dtg_warning "checking file:$dtsi_file  pwd:$dir"
				#Get the absolute path from relative path
				set dtsi_file [file normalize $dtsi_file]
			}
			file copy -force $dtsi_file ./
			update_system_dts_include [file tail $dtsi_file]
			return
		}
		set kernel_ver [get_property CONFIG.kernel_version [get_os]]
		set includes_dir [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/include"]
		set dir_path "./"
		# Copy full include directory to dt WS
		if {[file exists $includes_dir]} {
			file delete -force -- $dir_path/include
			file copy -force $includes_dir $dir_path
		}
		set dts_name [string tolower [lindex $override 1]]
		if {[string match -nocase $dts_name "template"]} {
			return
		}
		if {[llength $dts_name] == 0} {
			return
		}
		set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
		set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
		if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
			set mainline_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${mainline_ker}/board"]
			if {[file exists $mainline_dtsi]} {
				set mainline_board_file 0
				foreach file [glob [file normalize [file dirname ${mainline_dtsi}]/board/*]] {
					set dtsi_name "$dts_name.dtsi"
					# NOTE: ./ works only if we did not change our directory
					if {[regexp $dtsi_name $file match]} {
						file copy -force $file ./
						update_system_dts_include [file tail $file]
						set mainline_board_file 1
					}
				}
				if {$mainline_board_file == 0} {
					error "Error:$dtsi_name board file is not present in DTG. Please add a vaild board."
				}
			}
		} else {
			set kernel_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/BOARD"]
			if {[file exists $kernel_dtsi]} {
				set valid_board_file 0
				foreach file [glob [file normalize [file dirname ${kernel_dtsi}]/BOARD/*]] {
					set dtsi_name "$dts_name.dtsi"
					# NOTE: ./ works only if we did not change our directory
					if {[regexp $dtsi_name $file match]} {
						file copy -force $file ./
						update_system_dts_include [file tail $file]
						set valid_board_file 1
						gen_include_dtfile "${file}"
						break
					}
				}
				if {$valid_board_file == 0} {
					error "Error:$dtsi_name board file is not present in DTG. Please add a valid board."
				}
				set default_dts [get_property CONFIG.master_dts [get_os]]
				set root_node [add_or_get_dt_node -n / -d ${default_dts}]
			} else {
				puts "File not found\n\r"
			}
		}
        }
    }
  }
}

proc gen_zynqmp_ccf_clk {} {
	set default_dts [get_property CONFIG.pcw_dts [get_os]]
	set ccf_node [add_or_get_dt_node -n "&pss_ref_clk" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [list_property [get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__PSS_REF_CLK__FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PSU__PSS_REF_CLK__FREQMHZ [get_cells -hier $periph]]
				if {[string match -nocase $freq "33.333"]} {
					return
				} else {
					dtg_warning "Frequency $freq used instead of 33.333"
					hsi::utils::add_new_dts_param "${ccf_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
				}
			}
		}
	}
	set ccf_node [add_or_get_dt_node -n "&video_clk" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [list_property [get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PSU__VIDEO_REF_CLK__FREQMHZ [get_cells -hier $periph]]
				if {[string match -nocase $freq "27"]} {
					return
				} else {
					dtg_warning "Frequency $freq used instead of 27.00"
					hsi::utils::add_new_dts_param "${ccf_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
				}
			}
		}
	}

}

proc gen_zynqmp_opp_freq {} {
	set default_dts [get_property CONFIG.pcw_dts [get_os]]
	set cpu_opp_table [add_or_get_dt_node -n "&cpu_opp_table" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [list_property [get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__FREQMHZ [get_cells -hier $periph]]
				if {[string match -nocase $freq "1200"]} {
					# This is the default value set, so no need to calcualte
					return
				}
				if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ"] >= 0} {
					set act_freq [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ [get_cells -hier $periph]]
					set act_freq [expr $act_freq * 1000000]
				}
				if {[lsearch -nocase $avail_param "CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0"] >= 0} {
					set div [get_property CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 [get_cells -hier $periph]]
				}
				set opp_freq  [expr $act_freq * $div]
				set opp00_result [expr int ([expr $opp_freq / 1])]
				set opp01_result [expr int ([expr $opp_freq / 2])]
				set opp02_result [expr int ([expr $opp_freq / 3])]
				set opp03_result [expr int ([expr $opp_freq / 4])]
				set opp00 "/bits/ 64 <$opp00_result>"
				set opp01 "/bits/ 64 <$opp01_result>"
				set opp02 "/bits/ 64 <$opp02_result>"
				set opp03 "/bits/ 64 <$opp03_result>"
				set opp00_table [add_or_get_dt_node -n "opp00" -d $default_dts -p $cpu_opp_table]
				hsi::utils::add_new_dts_param "$opp00_table" "opp-hz" $opp00 noformating
				set opp01_table [add_or_get_dt_node -n "opp01" -d $default_dts -p $cpu_opp_table]
				hsi::utils::add_new_dts_param "$opp01_table" "opp-hz" $opp01 noformating
				set opp02_table [add_or_get_dt_node -n "opp02" -d $default_dts -p $cpu_opp_table]
				hsi::utils::add_new_dts_param "$opp02_table" "opp-hz" $opp02 noformating
				set opp03_table [add_or_get_dt_node -n "opp03" -d $default_dts -p $cpu_opp_table]
				hsi::utils::add_new_dts_param "$opp03_table" "opp-hz" $opp03 noformating
			}
		}
	}
}

proc gen_versal_clk {} {
	set default_dts [get_property CONFIG.pcw_dts [get_os]]
	set ref_node [add_or_get_dt_node -n "&ref_clk" -d $default_dts]
	set pl_alt_ref_node [add_or_get_dt_node -n "&pl_alt_ref_clk" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set versal_ps [get_property IP_NAME $periph]
		if {[string match -nocase $versal_ps "versal_cips"] } {
			set ver [get_comp_ver $periph]
			if {$ver < 3.0} {
				set avail_param [list_property [get_cells -hier $periph]]
				if {[lsearch -nocase $avail_param "CONFIG.PMC_REF_CLK_FREQMHZ"] >= 0} {
					set freq [get_property CONFIG.PMC_REF_CLK_FREQMHZ [get_cells -hier $periph]]
					if {![string match -nocase $freq "33.333"]} {
						dtg_warning "Frequency $freq used instead of 33.333"
						hsi::utils::add_new_dts_param "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
					}
				}
				if {[lsearch -nocase $avail_param "CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ"] >= 0} {
					set freq [get_property CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ [get_cells -hier $periph]]
					if {![string match -nocase $freq "33.333"]} {
						dtg_warning "Frequency $freq used instead of 33.333"
						hsi::utils::add_new_dts_param "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
					}
				}
			}
		}
		if {[string match -nocase $versal_ps "pspmc"] } {
			set avail_param [list_property [get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PMC_REF_CLK_FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PMC_REF_CLK_FREQMHZ [get_cells -hier $periph]]
				if {![string match -nocase $freq "33.333"]} {
					dtg_warning "Frequency $freq used instead of 33.333"
					hsi::utils::add_new_dts_param "${ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ"] >= 0} {
				set freq [get_property CONFIG.PMC_PL_ALT_REF_CLK_FREQMHZ [get_cells -hier $periph]]
				if {![string match -nocase $freq "33.333"]} {
					dtg_warning "Frequency $freq used instead of 33.333"
					hsi::utils::add_new_dts_param "${pl_alt_ref_node}" "clock-frequency" [scan [expr $freq * 1000000] "%d"] int
				}
			}
		}
	}

}

proc gen_zynqmp_pinctrl {} {
	set default_dts [get_property CONFIG.pcw_dts [get_os]]
	set pinctrl_node [add_or_get_dt_node -n "&pinctrl0" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set zynq_ultra_ps [get_property IP_NAME $periph]
		if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
			set avail_param [list_property [get_cells -hier $periph]]
			if {[lsearch -nocase $avail_param "CONFIG.PSU__UART1__PERIPHERAL__IO"] >= 0} {
				set uart1_io [get_property CONFIG.PSU__UART1__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $uart1_io "EMIO"]} {
					set pinctrl_uart1_default [add_or_get_dt_node -n "uart1-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_uart1_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart1_default" "/delete-node/ conf" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart1_default" "/delete-node/ conf-rx" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart1_default" "/delete-node/ conf-tx" "" boolean
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PSU__UART0__PERIPHERAL__IO"] >= 0} {
				set uart0_io [get_property CONFIG.PSU__UART0__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $uart0_io "EMIO"]} {
					set pinctrl_uart0_default [add_or_get_dt_node -n "uart0-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_uart0_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart0_default" "/delete-node/ conf" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart0_default" "/delete-node/ conf-rx" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_uart0_default" "/delete-node/ conf-tx" "" boolean
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PSU__CAN1__PERIPHERAL__IO"] >= 0} {
				set can1_io [get_property CONFIG.PSU__CAN1__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $can1_io "EMIO"]} {
					set pinctrl_can1_default [add_or_get_dt_node -n "can1-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_can1_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_can1_default" "/delete-node/ conf" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_can1_default" "/delete-node/ conf-rx" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_can1_default" "/delete-node/ conf-tx" "" boolean
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PSU__SD1__PERIPHERAL__IO"] >= 0} {
				set sd1_io [get_property CONFIG.PSU__SD1__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $sd1_io "EMIO"]} {
					set pinctrl_sdhci1_default [add_or_get_dt_node -n "sdhci1-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ conf" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ conf-cd" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ mux-cd" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ conf-wp" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_sdhci1_default" "/delete-node/ mux-wp" "" boolean
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PSU__ENET3__PERIPHERAL__IO"] >= 0} {
				set gem3_io [get_property CONFIG.PSU__ENET3__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $gem3_io "EMIO"]} {
					set pinctrl_gem3_default [add_or_get_dt_node -n "gem3-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ conf" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ conf-rx" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ conf-tx" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ conf-mdio" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_gem3_default" "/delete-node/ mux-mdio" "" boolean
				}
			}
			if {[lsearch -nocase $avail_param "CONFIG.PSU__I2C1__PERIPHERAL__IO"] >= 0} {
				set i2c1_io [get_property CONFIG.PSU__I2C1__PERIPHERAL__IO [get_cells -hier $periph]]
				if {[string match -nocase $i2c1_io "EMIO"]} {
					set pinctrl_i2c1_default [add_or_get_dt_node -n "i2c1-default" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_i2c1_default" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_i2c1_default" "/delete-node/ conf" "" boolean
					set pinctrl_i2c1_gpio [add_or_get_dt_node -n "i2c1-gpio" -d $default_dts -p $pinctrl_node]
					hsi::utils::add_new_dts_param "$pinctrl_i2c1_gpio" "/delete-node/ mux" "" boolean
					hsi::utils::add_new_dts_param "$pinctrl_i2c1_gpio" "/delete-node/ conf" "" boolean
				}
			}
		}
	}
}

proc gen_zocl_node {} {
	set zocl [get_property CONFIG.dt_zocl [get_os]]
	puts "zocl:$zocl"
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	set ext_platform [get_property platform.extensible [get_os]]
	puts "ext_platform:$ext_platform"
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {$remove_pl} {
		return
	}
	if {!$zocl} {
		return
	}
	#Check if design has any PL ip's
	set ip_count 0
	foreach ip [get_drivers] {
		if {[is_pl_ip $ip]} {
			incr ip_count
			break
		}
	}
	if {$ip_count == 0} {
		dtg_warning "dt_zocl enabled and No PL ip's found in specified design, skip adding zocl node"
		return
	}
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
	set default_dts pl.dtsi
	set zocl_node [add_or_get_dt_node -n "zyxclmm_drm" -d ${default_dts} -p $bus_node]
	if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "ps7_cortexa9"]} {
		hsi::utils::add_new_dts_param $zocl_node "compatible" "xlnx,zocl" string
	} else {
		hsi::utils::add_new_dts_param $zocl_node "compatible" "xlnx,zocl-versal" string
	}
	set intr_ctrl [get_cells -hier -filter {IP_NAME == axi_intc}]
	if {[llength $intr_ctrl]} {
	set intr_ctrl_len [llength $intr_ctrl]
	puts "intr_ctrl_len:$intr_ctrl_len"
	set int0 [lindex $intr_ctrl 0]
	foreach ip [get_drivers] {
		if {[string compare -nocase $ip $int0] == 0} {
			set target_handle $ip
		}
	}
	set intr [get_property CONFIG.interrupt-parent $target_handle]
	set int1 [lindex $intr_ctrl 1]
	foreach ip [get_drivers] {
		if {[string compare -nocase $ip $int1] == 0} {
			set target_handle $ip
		}
	}
	set intr [get_property CONFIG.interrupt-parent $target_handle]
	switch $intr_ctrl_len {
		"1"   {
			set ref [lindex $intr_ctrl 0]
			append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>,
<&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>,
<&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>,
<&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>,
<&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>,
<&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4 "
			hsi::utils::add_new_dts_param $zocl_node "interrupts-extended" $ref reference
		}
		"2"   {
			set ref [lindex $intr_ctrl 0]
			append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>, <&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>, <&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>, <&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>, <&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>, <&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4>, <&[lindex $intr_ctrl 1] 0 4>, <&[lindex $intr_ctrl 1] 1 4>, <&[lindex $intr_ctrl 1] 2 4>,  <&[lindex $intr_ctrl 1] 3 4>,  <&[lindex $intr_ctrl 1] 4 4>,  <&[lindex $intr_ctrl 1] 5 4>, <&[lindex $intr_ctrl 1] 6 4>, <&[lindex $intr_ctrl 1] 7 4>,  <&[lindex $intr_ctrl 1] 8 4>,  <&[lindex $intr_ctrl 1] 9 4>,  <&[lindex $intr_ctrl 1] 10 4>, <&[lindex $intr_ctrl 1] 11 4>, <&[lindex $intr_ctrl 1] 12 4>, <&[lindex $intr_ctrl 1] 13 4>, <&[lindex $intr_ctrl 1] 14 4>, <&[lindex $intr_ctrl 1] 15 4>, <&[lindex $intr_ctrl 1] 16 4>, <&[lindex $intr_ctrl 1] 17 4>, <&[lindex $intr_ctrl 1] 18 4>, <&[lindex $intr_ctrl 1] 19 4>, <&[lindex $intr_ctrl 1] 20 4>, <&[lindex $intr_ctrl 1] 21 4>, <&[lindex $intr_ctrl 1] 22 4>, <&[lindex $intr_ctrl 1] 23 4>, <&[lindex $intr_ctrl 1] 24 4>, <&[lindex $intr_ctrl 1] 25 4>, <&[lindex $intr_ctrl 1] 26 4>, <&[lindex $intr_ctrl 1] 27 4>, <&[lindex $intr_ctrl 1] 28 4>, <&[lindex $intr_ctrl 1] 29 4>, <&[lindex $intr_ctrl 1] 30 4 "
		hsi::utils::add_new_dts_param $zocl_node "interrupts-extended" $ref reference
		}
		"3" {
			set ref [lindex $intr_ctrl 0]
			append ref " 0 4>, <&[lindex $intr_ctrl 0] 1 4>, <&[lindex $intr_ctrl 0] 2 4>, <&[lindex $intr_ctrl 0] 3 4>, <&[lindex $intr_ctrl 0] 4 4>, <&[lindex $intr_ctrl 0] 5 4>, <&[lindex $intr_ctrl 0] 6 4>, <&[lindex $intr_ctrl 0] 7 4>, <&[lindex $intr_ctrl 0] 8 4>, <&[lindex $intr_ctrl 0] 9 4>, <&[lindex $intr_ctrl 0] 10 4>, <&[lindex $intr_ctrl 0] 11 4>, <&[lindex $intr_ctrl 0] 12 4>, <&[lindex $intr_ctrl 0] 13 4>, <&[lindex $intr_ctrl 0] 14 4>, <&[lindex $intr_ctrl 0] 15 4>, <&[lindex $intr_ctrl 0] 16 4>, <&[lindex $intr_ctrl 0] 17 4>, <&[lindex $intr_ctrl 0] 18 4>, <&[lindex $intr_ctrl 0] 19 4>, <&[lindex $intr_ctrl 0] 20 4>, <&[lindex $intr_ctrl 0] 21 4>, <&[lindex $intr_ctrl 0] 22 4>, <&[lindex $intr_ctrl 0] 23 4>, <&[lindex $intr_ctrl 0] 24 4>, <&[lindex $intr_ctrl 0] 25 4>, <&[lindex $intr_ctrl 0] 26 4>, <&[lindex $intr_ctrl 0] 27 4>, <&[lindex $intr_ctrl 0] 28 4>, <&[lindex $intr_ctrl 0] 29 4>, <&[lindex $intr_ctrl 0] 30 4>, <&[lindex $intr_ctrl 0] 31 4>, <&[lindex $intr_ctrl 1] 0 4>, <&[lindex $intr_ctrl 1] 1 4>, <&[lindex $intr_ctrl 1] 2 4>, <&[lindex $intr_ctrl 1] 2 4>, <&[lindex $intr_ctrl 1] 3 4>, <&[lindex $intr_ctrl 1] 4 4>, <&[lindex $intr_ctrl 1] 5 4>, <&[lindex $intr_ctrl 1] 6 4>, <&[lindex $intr_ctrl 1] 7 4>, <&[lindex $intr_ctrl 1] 8 4>, <&[lindex $intr_ctrl 1] 9 4>, <&[lindex $intr_ctrl 1] 10 4>, <&[lindex $intr_ctrl 1] 11 4>, <&[lindex $intr_ctrl 1] 12 4>, <&[lindex $intr_ctrl 1] 13 4>, <&[lindex $intr_ctrl 1] 14 4>, <&[lindex $intr_ctrl 1] 15 4>, <&[lindex $intr_ctrl 1] 16 4>, <&[lindex $intr_ctrl 1] 17 4>, <&[lindex $intr_ctrl 1] 18 4>, <&[lindex $intr_ctrl 1] 19 4>, <&[lindex $intr_ctrl 1] 20 4>, <&[lindex $intr_ctrl 1] 21 4>, <&[lindex $intr_ctrl 1] 22 4>, <&[lindex $intr_ctrl 1] 23 4>, <&[lindex $intr_ctrl 1] 24 4>, <&[lindex $intr_ctrl 1] 25 4>, <&[lindex $intr_ctrl 1] 26 4>, <&[lindex $intr_ctrl 1] 27 4>, <&[lindex $intr_ctrl 1] 28 4>, <&[lindex $intr_ctrl 1] 29 4>, <&[lindex $intr_ctrl 1] 30 4>, <&[lindex $intr_ctrl 1] 31 4>, <&[lindex $intr_ctrl 2] 0 4>, <&[lindex $intr_ctrl 2] 1 4>, <&[lindex $intr_ctrl 2] 2 4>, <&[lindex $intr_ctrl 2] 3 4>, <&[lindex $intr_ctrl 2] 4 4>, <&[lindex $intr_ctrl 2] 5 4>, <&[lindex $intr_ctrl 2] 6 4>, <&[lindex $intr_ctrl 2] 7 4>, <&[lindex $intr_ctrl 2] 8 4>, <&[lindex $intr_ctrl 2] 9 4>, <&[lindex $intr_ctrl 2] 10 4>, <&[lindex $intr_ctrl 2] 11 4>, <&[lindex $intr_ctrl 2] 12 4>, <&[lindex $intr_ctrl 2] 13 4>, <&[lindex $intr_ctrl 2] 14 4>, <&[lindex $intr_ctrl 2] 15 4>, <&[lindex $intr_ctrl 2] 16 4>, <&[lindex $intr_ctrl 2] 17 4>, <&[lindex $intr_ctrl 2] 18 4>, <&[lindex $intr_ctrl 2] 19 4>, <&[lindex $intr_ctrl 2] 20 4>, <&[lindex $intr_ctrl 2] 21 4>, <&[lindex $intr_ctrl 2] 22 4 >, <&[lindex $intr_ctrl 2] 23 4>, <&[lindex $intr_ctrl 2] 24 4>, <&[lindex $intr_ctrl 2] 25 4>, <&[lindex $intr_ctrl 2] 26 4>, <&[lindex $intr_ctrl 2] 27 4>, <&[lindex $intr_ctrl 2] 28 4>, <&[lindex $intr_ctrl 2] 29 4>, <&[lindex $intr_ctrl 2] 30 4 "
		hsi::utils::add_new_dts_param $zocl_node "interrupts-extended" $ref reference
		}
	}
	}
	set decouplers [get_cells -hier -filter {IP_NAME == "dfx_decoupler"}]
	set count 1
	foreach decoupler $decouplers {
		if { $count == 1 } {
			hsi::utils::add_new_dts_param "$zocl_node" "xlnx,pr-decoupler" "" boolean
		} else {
			#zocl driver not supporting multiple decouplers so display warning.
			dtg_warning "Multiple dfx_decoupler IPs found in the design,\
				using pr-isolation-addr from [lindex [split $decouplers " "] 0] IP"
			break
		}
		set baseaddr [get_property CONFIG.C_BASEADDR [get_cells -hier $decoupler]]
		if {[llength $baseaddr]} {
			set baseaddr "0x0 $baseaddr"
			hsi::utils::add_new_dts_param "$zocl_node" "xlnx,pr-isolation-addr" "$baseaddr" intlist
		}
		incr count
	}
}

proc generate {lib_handle} {
	add_skeleton
	foreach drv_handle [get_drivers] {
		if {[string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
			gen_peripheral_nodes $drv_handle "create_node_only"
		}
	}
	foreach drv_handle [get_drivers] {
		# generate the default properties
		if {![string match -nocase [common::get_property IP_NAME [get_cells -hier $drv_handle]] "axi_intc"]} {
			gen_peripheral_nodes $drv_handle "create_node_only"
		}
		gen_reg_property $drv_handle
		gen_compatible_property $drv_handle
		gen_drv_prop_from_ip $drv_handle
		gen_interrupt_property $drv_handle
		gen_clk_property $drv_handle
	}
	gen_board_info
	gen_include_headers
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"] || [string match -nocase $proctype "psx_cortexa78"]} {
		set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
		if {[string match -nocase $mainline_ker "none"]} {
			gen_sata_laneinfo
			gen_zynqmp_ccf_clk
			gen_versal_clk
			gen_zynqmp_opp_freq
			gen_zynqmp_pinctrl
			gen_zocl_node
			if {[string match -nocase $proctype "psv_cortexa72"]} {
				gen_edac_node
				gen_ddrmc_node
			}
		}
	}
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
		if {[string match -nocase $mainline_ker "none"]} {
			gen_zocl_node
		}
	}
	gen_ext_axi_interface
}

proc post_generate {os_handle} {
    update_chosen $os_handle
    update_alias $os_handle
    update_cpu_node $os_handle
    gen_dev_conf
    foreach drv_handle [get_drivers] {
        gen_peripheral_nodes $drv_handle
	update_endpoints $drv_handle
    }
    global zynq_soc_dt_tree
    delete_objs [get_dt_tree $zynq_soc_dt_tree]
    remove_empty_reference_node
    remove_main_memory_node
}

proc add_skeleton {} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set chosen_node [add_or_get_dt_node -n "chosen" -d ${default_dts} -p ${system_root_node}]
    set alias_node [add_or_get_dt_node -n "aliases" -d ${default_dts} -p ${system_root_node}]
}

proc update_chosen {os_handle} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set chosen_node [add_or_get_dt_node -n "chosen" -d ${default_dts} -p ${system_root_node}]

    #getting boot arguments
    set bootargs [get_property CONFIG.bootargs $os_handle]
    set console [hsi::utils::get_os_parameter_value "console"]
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[llength $bootargs]} {
        append bootargs " earlycon"
    } else {
	set bootargs "earlycon"
    }
    if {[string match -nocase $proctype "psv_cortexa72"]} {
	#as the early params are defined in board dts files
	return
    }
    if {[string match -nocase $proctype "psx_cortexa78"]} {
	#as the early params are defined in board dts files
	return
    }
    hsi::utils::add_new_dts_param "${chosen_node}" "bootargs" "$bootargs" string
    set consoleip [get_property CONFIG.console_device $os_handle]
    if {![string match -nocase $consoleip "none"]} {
         set consoleip [ps_node_mapping $consoleip label]
         set index [string first "," $console]
         set baud [string range $console [expr $index + 1] [string length $console]]
         hsi::utils::add_new_dts_param "${chosen_node}" "stdout-path" "serial0:${baud}n8" string
   }
}

proc update_cpu_node {os_handle} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]

    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "psv_cortexa72"] } {
        set current_proc "psv_cortexa72_"
        set total_cores 2
    } elseif {[string match -nocase $proctype "psx_cortexa78"] } {
        set current_proc "psx_cortexa78_"
        set total_cores 16
    } elseif {[string match -nocase $proctype "psu_cortexa53"] } {
        set current_proc "psu_cortexa53_"
        set total_cores 4
    } elseif {[string match -nocase $proctype "ps7_cortexa9"] } {
        set current_proc "ps7_cortexa9_"
        set total_cores 2
    } else {
        set current_proc ""
    }

    if {[string compare -nocase $current_proc ""] == 0} {
        return
    }
    if {[string match -nocase $proctype "psv_cortexa72"]} {
        set procs [get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        set pnames ""
	foreach proc_name $procs {
              if {[regexp "psv_cortexa72*" $proc_name match]} {
	             append pnames " " $proc_name
              }
        }
        set a72cores [llength $pnames]
        if {[string match -nocase $a72cores $total_cores]} {
	     return
        }
    }
    if {[string match -nocase $proctype "psx_cortexa78"]} {
        set procs [get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        set pnames ""
	foreach proc_name $procs {
              if {[regexp "psx_cortexa78*" $proc_name match]} {
	             append pnames " " $proc_name
              }
        }
        set a78cores [llength $pnames]
        if {[string match -nocase $a78cores $total_cores]} {
	     return
        }
    }
    #getting boot arguments
    set proc_instance 0
    for {set i 0} {$i < $total_cores} {incr i} {
        set proc_name [lindex [get_cells -hier -filter {IP_TYPE==PROCESSOR} *$proctype*] $i]
        if {[llength $proc_name] == 0} {
            set cpu_node [add_or_get_dt_node -n "cpus" -d ${default_dts} -p ${system_root_node}]
            hsi::utils::add_new_dts_param "${cpu_node}" "/delete-node/ cpu@$i" "" boolean
            continue
        }
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $proc_name]] "microblaze"]} {
		return
	}
	if {[regexp ".*${current_proc}${i}" $proc_name match]} {
            continue
        } else {
            set cpu_node [add_or_get_dt_node -n "cpus" -d ${default_dts} -p ${system_root_node}]
            hsi::utils::add_new_dts_param "${cpu_node}" "/delete-node/ cpu@$i" "" boolean
        }
    }
}

proc update_alias {os_handle} {
    set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
    set valid_mainline_kernel_list "v4.17 v4.18 v4.19 v5.0 v5.1 v5.2 v5.3 v5.4"
    if {[lsearch $valid_mainline_kernel_list $mainline_ker] >= 0 } {
         return
    }
    set no_alias [get_property CONFIG.no_alias [get_os]]
    if {$no_alias} {
    #Don't generate the alias node when no_alias is set to true
	return
    }
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set all_labels [get_all_dt_labels]
	set all_drivers [get_drivers]

	# Search for ps_qspi, if it is there then interchange this with first driver
	# because to have correct internal u-boot commands qspi has to be listed in aliases as the first for spi0
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		set pos [lsearch $all_drivers "ps7_qspi*"]
	} elseif {[string match -nocase $proctype "psu_cortexa53"]} {
		set pos [lsearch $all_drivers "psu_qspi*"]
	} elseif {[string match -nocase $proctype "psv_cortexa72"]} {
		set pos [lsearch $all_drivers "psv_pmc_qspi*"]
	} elseif {[string match -nocase $proctype "psx_cortexa78"]} {
		set pos [lsearch $all_drivers "psx_pmc_qspi*"]
	} else {
		set pos [lsearch $all_drivers "psu_qspi*"]
	}
	if { $pos >= 0 } {
		set first_element [lindex $all_drivers 0]
		set qspi_element [lindex $all_drivers $pos]
		set all_drivers [lreplace $all_drivers 0 0 $qspi_element]
		set all_drivers [lreplace $all_drivers $pos $pos $first_element]
    }
	# Update all_drivers list such that console device should be the first
	# uart device in the list.
	set console_ip [get_property CONFIG.console_device [get_os]]
	if {![string match -nocase $console_ip "none"]} {
		set valid_console [lsearch $all_drivers $console_ip]
		if { $valid_console < 0 } {
			error "Trying to assign a console::$console_ip which doesn't exists !!!"
		}
	}
	set dt_overlay [get_property CONFIG.DT_Overlay [get_os]]
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	foreach drv_handle $all_drivers {
		if {[is_pl_ip $drv_handle] && $remove_pl} {
			continue
		}
		set alias_str [get_property CONFIG.dtg.alias $drv_handle]
		if {[string match -nocase $alias_str "serial"]} {
			if {![string match -nocase $console_ip "none"]} {
				if {[string match $console_ip $drv_handle] == 0} {
					# break the loop After swaping console device and uart device
					# found in list
					set consoleip_pos [lsearch $all_drivers $console_ip]
					set first_occur_pos [lsearch $all_drivers $drv_handle]
					set console_element [lindex $all_drivers $consoleip_pos]
					set uart_element [lindex $all_drivers $first_occur_pos]
					set all_drivers [lreplace $all_drivers $consoleip_pos $consoleip_pos $uart_element]
					set all_drivers [lreplace $all_drivers $first_occur_pos $first_occur_pos $console_element]
					break
				} else {
					# if the first uart device in the list is console device
					break
				}
			}
		}
	}
	set psi2clist ""
	set pli2clist ""
	set i2clen ""
	set alias_node ""
	set psuartlist ""
	set pluartlist ""
	set uartlen ""
	set psspilist ""
	set plspilist ""
	set spilen ""

	foreach drv_handle $all_drivers {
            if {[is_pl_ip $drv_handle] && $dt_overlay} {
                continue
            }
            if {[is_pl_ip $drv_handle] && $remove_pl} {
                continue
            }
            if {[check_ip_trustzone_state $drv_handle] == 1} {
                continue
            }
            set ip_name  [get_property IP_NAME [get_cells -hier $drv_handle]]
            if {[string match -nocase $ip_name "psv_pmc_qspi"]} {
                  set ip_type [get_property IP_TYPE [get_cells -hier $drv_handle]]
                  if {[string match -nocase $ip_type "PERIPHERAL"]} {
                        continue
                  }
            }

        set tmp [list_property $drv_handle CONFIG.dtg.alias]
        if {[string_is_empty $tmp]} {
            continue
        } else {
            set alias_str [get_property CONFIG.dtg.alias $drv_handle]
		if {[string match -nocase $alias_str "i2c"]} {
			set upate [lappend upate $drv_handle]
			set i2clen [llength $upate]
			set i2cps [is_ps_ip $drv_handle]
			if {$i2cps} {
				set psi2clist [lappend psi2clist $drv_handle]
			}
			set i2cpl [is_pl_ip $drv_handle]
			if {$i2cpl} {
				set pli2clist [lappend pli2clist $drv_handle]
			}
		}
		if {[string match -nocase $alias_str "serial"]} {
			set uartate [lappend uartate $drv_handle]
			set uartlen [llength $uartate]
			set uartps [is_ps_ip $drv_handle]
			if {$uartps} {
				set psuartlist [lappend psuartlist $drv_handle]
			}
			set uartpl [is_pl_ip $drv_handle]
			if {$uartpl} {
				set pluartlist [lappend pluartlist $drv_handle]
			}
		}
		if {[string match -nocase $alias_str "spi"]} {
			set spiat [lappend spiat $drv_handle]
			set spilen [llength $spiat]
			set spips [is_ps_ip $drv_handle]
			if {$spips} {
				set psspilist [lappend psspilist $drv_handle]
			}
			set spipl [is_pl_ip $drv_handle]
			if {$spipl} {
				set plspilist [lappend plspilist $drv_handle]
			}
		}

            set alias_count [get_os_dev_count alias_${alias_str}_count]
            set conf_name ${alias_str}${alias_count}
            set value [ps_node_mapping $drv_handle label]
            set ip_list "i2c spi serial"
            # TODO: need to check if the label already exists in the current system
			if {[lsearch $all_labels $conf_name] >=0} {
				set str [lsearch $ip_list $alias_str]
				if {[string match $str "-1"]} {
					continue
				}
			}
            set alias_node [add_or_get_dt_node -n "aliases" -d ${default_dts} -p ${system_root_node}]
            hsi::utils::add_new_dts_param "${alias_node}" ${conf_name} ${value} aliasref
            hsi::utils::set_os_parameter_value alias_${alias_str}_count [expr $alias_count + 1]
        }
    }
	set i2c_pslen [llength $psi2clist]
	for {set i 0} {$i < $i2c_pslen} {incr i} {
		set drv_name [lindex $psi2clist $i]
		set value [ps_node_mapping $drv_name label]
		set name "i2c$i"
		hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
	}
	set i2c_pllen [llength $pli2clist]
	set i2clen1 [expr {$i2c_pslen + $i2c_pllen}]
	for {set i $i2c_pslen} {$i < $i2clen1} {incr i} {
		set drv_name [lindex $pli2clist [expr {$i - $i2c_pslen}]]
		set value [ps_node_mapping $drv_name label]
		set name "i2c$i"
		hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
	}
	 set is_pl_console [is_pl_ip $console_ip]
	if {$is_pl_console} {
		for {set i 0} {$i < $uartlen} {incr i} {
			set drv_name [lindex $uartate $i]
			set value [ps_node_mapping $drv_name label]
			set name "serial$i"
			hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
		}
	} else {
		set uart_pslen [llength $psuartlist]
		for {set i 0} {$i < $uart_pslen} {incr i} {
			set drv_name [lindex $psuartlist $i]
			set value [ps_node_mapping $drv_name label]
			set name "serial$i"
			hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
		}
		set uart_pllen [llength $pluartlist]
		set uartlen1 [expr {$uart_pslen + $uart_pllen}]
		for {set i $uart_pslen} {$i < $uartlen1} {incr i} {
			set drv_name [lindex $pluartlist [expr {$i - $uart_pslen}]]
			set value [ps_node_mapping $drv_name label]
			set name "serial$i"
			hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
		}
	}
	set spi_pslen [llength $psspilist]
	for {set i 0} {$i < $spi_pslen} {incr i} {
		set drv_name [lindex $psspilist $i]
		set value [ps_node_mapping $drv_name label]
		set name "spi$i"
		hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
	}
	set spi_pllen [llength $plspilist]
	set spilen1 [expr {$spi_pslen + $spi_pllen}]
	for {set i $spi_pslen} {$i < $spilen1} {incr i} {
		set drv_name [lindex $plspilist [expr {$i - $spi_pslen}]]
		set value [ps_node_mapping $drv_name label]
		set name "spi$i"
		hsi::utils::add_new_dts_param "${alias_node}" ${name} ${value} aliasref
	}
}

# remove main memory node
proc remove_main_memory_node {} {
    set main_memory [get_property CONFIG.main_memory [get_os]]
    if {[string_is_empty $main_memory]} {
        return 0
    }

    # in theory it will not del the ps ddr as it snot been generated
    set mc_obj [get_node_object $main_memory "" ""]
    if {[string_is_empty $mc_obj]} {
        return 0
    }
	set all_drivers [get_drivers]
	foreach drv_handle $all_drivers {
		set ip [get_property IP_NAME [get_cells -hier $drv_handle]]
		if {[string match -nocase $ip "ddr4"]} {
			set slave [get_cells -hier ${drv_handle}]
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $slave]
			if {[llength $ip_mem_handles] > 1} {
				return
			}
		}
	}
    set cur_dts [current_dt_tree]
    foreach dts_file [get_dt_tree] {
        set dts_nodes [get_all_tree_nodes $dts_file]
        foreach node ${dts_nodes} {
            if {[regexp $mc_obj $node match]} {
                current_dt_tree $dts_file
                delete_objs $mc_obj
                current_dt_tree $cur_dts
            }
        }
    }
}
