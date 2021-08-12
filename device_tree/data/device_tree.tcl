#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
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
            ip "axi_uartlite axi_uart16550 ps7_uart psu_uart psv_uart"
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

proc gen_sata_laneinfo {} {
	set remove_pl [get_property CONFIG.remove_pl [get_os]]
	if {$remove_pl} {
		return 0
	}

	foreach ip [get_cells] {
		set slane 0
		set freq {}
		set ip_type [get_property IP_TYPE [get_cells $ip]]
		if {$ip_type eq ""} {
			set ps $ip
		}
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
		set include_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/include"]
		set include_list "include*"
		set dir_path "./"
		if {[string match -nocase $proctype "psu_cortexa53"]} {
			set power_list "xlnx-zynqmp-power.h"
			set clock_list "xlnx-zynqmp-clk.h"
			set reset_list "xlnx-zynqmp-resets.h"
		} else {
			set power_list "xlnx-versal-power.h"
			set clock_list "xlnx-versal-clk.h"
			set reset_list "xlnx-zynqmp-resets.h"
		}
		set powerdir "$dir_path/include/dt-bindings/power"
		set clockdir "$dir_path/include/dt-bindings/clock"
		set resetdir "$dir_path/include/dt-bindings/reset"
		file mkdir $powerdir
		file mkdir $clockdir
		file mkdir $resetdir
		if {[file exists $include_dtsi]} {
			foreach file [glob [file normalize [file dirname ${include_dtsi}]/*/*/*/*]] {
				if {[string first $power_list $file]!= -1} {
					file copy -force $file $powerdir
				} elseif {[string first $clock_list $file] != -1} {
					file copy -force $file $clockdir
				} elseif {[string first $reset_list $file] != -1} {
					file copy -force $file $resetdir
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
		set dts_name [string tolower [lindex $override 1]]
		if {[string match -nocase $dts_name "template"]} {
			return
		}
		if {[llength $dts_name] == 0} {
			return
		}
		set kernel_ver [get_property CONFIG.kernel_version [get_os]]
		set include_dtsi [file normalize "[get_property "REPOSITORY" $i]/data/kernel_dtsi/${kernel_ver}/include"]
		set include_list "include*"
		set dir_path "./"
		set gpio_list "gpio.h"
		set intr_list "irq.h"
		set phy_list  "phy.h"
		set input_list "input.h"
		set pinctrl_list "pinctrl-zynqmp.h"
		set gpiodir "$dir_path/include/dt-bindings/gpio"
		set phydir "$dir_path/include/dt-bindings/phy"
		set intrdir "$dir_path/include/dt-bindings/interrupt-controller"
		set inputdir "$dir_path/include/dt-bindings/input"
		set pinctrldir "$dir_path/include/dt-bindings/pinctrl"
		file mkdir $phydir
		file mkdir $gpiodir
		file mkdir $intrdir
		file mkdir $inputdir
		file mkdir $pinctrldir
		if {[file exists $include_dtsi]} {
			foreach file [glob [file normalize [file dirname ${include_dtsi}]/*/*/*/*]] {
				if {[string first $gpio_list $file] != -1} {
					file copy -force $file $gpiodir
				} elseif {[string first $phy_list $file] != -1} {
					file copy -force $file $phydir
				} elseif {[string first $intr_list $file] != -1} {
					file copy -force $file $intrdir
				} elseif {[string first $input_list $file] != -1} {
					file copy -force $file $inputdir
				} elseif {[string first $pinctrl_list $file] != -1} {
					file copy -force $file $pinctrldir
				}
			}
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

}

proc gen_versal_clk {} {
	set default_dts [get_property CONFIG.pcw_dts [get_os]]
	set ref_node [add_or_get_dt_node -n "&ref_clk" -d $default_dts]
	set pl_alt_ref_node [add_or_get_dt_node -n "&pl_alt_ref_clk" -d $default_dts]
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		set versal_ps [get_property IP_NAME $periph]
		if {[string match -nocase $versal_ps "versal_cips"] } {
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

proc generate {lib_handle} {
    add_skeleton
    foreach drv_handle [get_drivers] {
        # generate the default properties
        gen_peripheral_nodes $drv_handle "create_node_only"
        gen_reg_property $drv_handle
        gen_compatible_property $drv_handle
        gen_drv_prop_from_ip $drv_handle
        gen_interrupt_property $drv_handle
        gen_clk_property $drv_handle
    }
    gen_board_info
    gen_include_headers
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    if {[string match -nocase $proctype "psu_cortexa53"] || [string match -nocase $proctype "psv_cortexa72"]} {
	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	if {[string match -nocase $mainline_ker "none"]} {
		gen_sata_laneinfo
		gen_zynqmp_ccf_clk
		gen_versal_clk
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
    if {[string match -nocase $proctype "psu_cortexa53"]} {
           append bootargs " clk_ignore_unused"
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
    #getting boot arguments
    set proc_instance 0
    for {set i 0} {$i < $total_cores} {incr i} {
        set proc_name [lindex [get_cells -hier -filter {IP_TYPE==PROCESSOR}] $i]
        if {[llength $proc_name] == 0} {
            set cpu_node [add_or_get_dt_node -n "cpus" -d ${default_dts} -p ${system_root_node}]
            hsi::utils::add_new_dts_param "${cpu_node}" "/delete-node/ cpu@$i" "" boolean
            continue
        }
	if {[string match -nocase [get_property IP_NAME [get_cells -hier $proc_name]] "microblaze"]} {
		return
	}
        if {[string match -nocase $proc_name "$current_proc$i"] } {
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
