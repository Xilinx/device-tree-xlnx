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
            ip "axi_uartlite axi_uart16550 ps7_uart psu_uart"
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

proc generate {lib_handle} {
    add_skeleton
    foreach drv_handle [get_drivers] {
        # generate the default properties
        gen_peripheral_nodes $drv_handle "create_node_only"
        gen_reg_property $drv_handle
        gen_compatible_property $drv_handle
        gen_drv_prop_from_ip $drv_handle
        gen_interrupt_property $drv_handle
    }
}

proc post_generate {os_handle} {
    update_chosen $os_handle
    update_alias $os_handle
    gen_dev_conf
    foreach drv_handle [get_drivers] {
        gen_peripheral_nodes $drv_handle
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
    # assuming memory node is call memory
    set alias_node [add_or_get_dt_node -n "memory" -d ${default_dts} -p ${system_root_node}]
}

proc update_chosen {os_handle} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set chosen_node [add_or_get_dt_node -n "chosen" -d ${default_dts} -p ${system_root_node}]

    #getting boot arguments
    set bootargs [get_property CONFIG.bootargs $os_handle]
    if {[llength $bootargs] == 0} {
        set console [hsi::utils::get_os_parameter_value "console"]
        if {[llength $console]} {
            set bootargs "console=$console"
        }
    }
    if {[llength $bootargs]} {
        hsi::utils::add_new_dts_param "${chosen_node}" "bootargs" $bootargs string
    }
    set consoleip [get_property CONFIG.console_device $os_handle]
    set consoleip [ps_node_mapping $consoleip label]
    if {[lsearch [get_drivers] $consoleip] < 0} {return -1}
    hsi::utils::add_new_dts_param "${chosen_node}" "linux,stdout-path" $consoleip aliasref
    hsi::utils::add_new_dts_param "${chosen_node}" "stdout-path" $consoleip aliasref
}

proc update_alias {os_handle} {
    set default_dts [get_property CONFIG.master_dts [get_os]]
    set system_root_node [add_or_get_dt_node -n "/" -d ${default_dts}]
    set all_labels [get_all_dt_labels]
	set all_drivers [get_drivers]

	# Search for ps_qspi, if it is there then interchange this with first driver
	# because to have correct internal u-boot commands qspi has to be listed in aliases as the first for spi0
	set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
	if {[string match -nocase $proctype "ps7_cortexa9"]} {
		set pos [lsearch $all_drivers "ps7_qspi*"]
	} else {
		set pos [lsearch $all_drivers "psu_qspi*"]
	}
	set pos [lsearch $all_drivers "ps7_qspi*"]
	if { $pos >= 0 } {
		set first_element [lindex $all_drivers 0]
		set qspi_element [lindex $all_drivers $pos]
		set all_drivers [lreplace $all_drivers 0 0 $qspi_element]
		set all_drivers [lreplace $all_drivers $pos $pos $first_element]
    }
	# Update all_drivers list such that console device should be the first
	# uart device in the list.
	set console_ip [get_property CONFIG.console_device [get_os]]
	foreach drv_handle $all_drivers {
		set alias_str [get_property CONFIG.dtg.alias $drv_handle]
		if {[string match -nocase $alias_str "serial"]} {
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

	foreach drv_handle $all_drivers {
        set tmp [list_property $drv_handle CONFIG.dtg.alias]
        if {[string_is_empty $tmp]} {
            continue
        } else {
            set alias_str [get_property CONFIG.dtg.alias $drv_handle]
            set alias_count [get_os_dev_count alias_${alias_str}_count]
            set conf_name ${alias_str}${alias_count}
            set value [ps_node_mapping $drv_handle label]
            # TODO: need to check if the label already exists in the current system
			if {[lsearch $all_labels $conf_name] >=0} {
				if {![string equal $alias_str "spi"]} {
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
