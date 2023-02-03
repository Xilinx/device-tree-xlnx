#
# (C) Copyright 2017-2022 Xilinx, Inc.
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

proc gen_reset_gpio {drv_handle node} {
    set ip [get_cells -hier $drv_handle]
    set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier $ip] "vdu_resetn"]]
    foreach pin $pins {
        set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [get_property IP_NAME $sink_periph]
		    if {[string match -nocase $sink_ip "axi_gpio"]} {
			    hsi::utils::add_new_dts_param "$node" "reset-gpios" "$sink_periph 0 1" reference
			}
			if {[string match -nocase $sink_ip "xlslice"]} {
				set gpio [get_property CONFIG.DIN_FROM $sink_periph]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [::hsi::get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [get_property IP_NAME $periph]
						set proc_type [get_sw_proc_prop IP_NAME]
						if {[string match -nocase $proc_type "psv_cortexa72"] } {
							if {[string match -nocase $ip "versal_cips"]} {
								# As in versal there is only bank0 for MIOs
								set gpio [expr $gpio + 26]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio0 $gpio 0" reference
								break
							}
						}
						if {[string match -nocase $proc_type "psu_cortexa53"] } {
							if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
								set gpio [expr $gpio + 78]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio $gpio 0" reference
								break
							}
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 0 1" reference
						}
					} else {
						dtg_warning "periph for the pin:$pin is NULL $periph...check the design"
					}
				}
			}
		} else {
			dtg_warning "peripheral for the pin:$pin is NULL $sink_periph...check the design"
		}
	}
}

proc get_intr_width {intr_parent} {
    set intr_width ""
    if { [string match -nocase $intr_parent "gic"] }  {
        set intr_width "3"
	} else {
        set intr_width "2"
	}
    return $intr_width
}

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
    # Generate properties required for vdu node
    set node [gen_peripheral_nodes $drv_handle]
    if {$node == 0} {
           return
    }
    set drv_label [ps_node_mapping $drv_handle label]
    set default_dts [set_drv_def_dts $drv_handle]
	set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
	if {$dt_overlay} {
		set bus_node "amba"
	} else {
		set bus_node "amba_pl"
	}
    set vdu_ip [get_cells -hier $drv_handle]
    set core_clk [get_property CONFIG.CORE_CLK [get_cells -hier $drv_handle]]
    if {[llength $core_clk]} {
        hsi::utils::add_new_dts_param "${node}" "xlnx,core_clk" ${core_clk} int
    }
    set mcu_clk [get_property CONFIG.MCU_CLK [get_cells -hier $drv_handle]]
    if {[llength $mcu_clk]} {
        hsi::utils::add_new_dts_param "${node}" "xlnx,mcu_clk" ${mcu_clk} int
    }
    set ref_clk [get_property CONFIG.REF_CLK [get_cells -hier $drv_handle]]
    if {[llength $ref_clk]} {
        hsi::utils::add_new_dts_param "${node}" "xlnx,ref_clk" ${ref_clk} int
    }
    set enable_dpll [get_property CONFIG.ENABLE_DPLL [get_cells -hier $drv_handle]]
    if {[string match -nocase $enable_dpll "true"]} {
        hsi::utils::add_new_dts_param "${node}" "xlnx,enable_dpll" "" boolean
    }
    gen_reset_gpio "$drv_handle" "$node"
    set intr_val ""
    set intr_parent ""
    set intr_names ""
    global drv_handlers_mapping
    if {[info exists drv_handlers_mapping] && [dict exists $drv_handlers_mapping $drv_handle]} {
        if {[dict exists $drv_handlers_mapping $drv_handle "interrupts"]} {
            set intr_val [dict get $drv_handlers_mapping $drv_handle "interrupts"]
        }
        if {[dict exists $drv_handlers_mapping $drv_handle "interrupt-parent"]} {
            set intr_parent [dict get $drv_handlers_mapping $drv_handle "interrupt-parent"]
        }
        if {[dict exists $drv_handlers_mapping $drv_handle "interrupt-names"]} {
            set intr_names [dict get $drv_handlers_mapping $drv_handle "interrupt-names"]
        }
    }
    set intrnames_List ""
    if {[llength $intr_names]} {
        set intrnames_List [regexp -inline -all -- {\S+} $intr_names]
    }
    set baseaddr [get_baseaddr $vdu_ip no_prefix]
    set num_decoders [get_property CONFIG.NUM_DECODER_INSTANCES [get_cells -hier $drv_handle]]
    set al5d_baseoffset "0x20000"
    set al5d_baseaddr [format %08x [expr 0x$baseaddr + $al5d_baseoffset]]
    set al5d_offset "0x100000"
    set intr_width ""
    for {set inst 0} {$inst < $num_decoders} {incr inst} {
        set al5d_node [add_or_get_dt_node -n al5d@$al5d_baseaddr -d $default_dts -p $bus_node]
        hsi::utils::add_new_dts_param $al5d_node "compatible" "al,al5d" string
        hsi::utils::add_new_dts_param $al5d_node "al,devicename" "allegroDecodeIP$inst" string
        hsi::utils::add_new_dts_param $al5d_node "xlnx,vdu" "$drv_label" reference
        hsi::utils::add_new_dts_param $al5d_node \
            "/*To be filled by user depending on design else CMA region will be used */" "" comment
        hsi::utils::add_new_dts_param $al5d_node "/*memory-region = <&mem_reg_0> */" "" comment

		# check if base address is 64bit and split it as MSB and LSB
		if {[regexp -nocase {0x([0-9a-f]{9})} "0x$al5d_baseaddr" match]} {
		    set temp $al5d_baseaddr
			set temp [string trimleft [string trimleft $temp 0] x]
			set len [string length $temp]
			set rem [expr {${len} - 8}]
			set high_base "0x[string range $temp $rem $len]"
			set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
			set low_base [format 0x%08x $low_base]
			if {[regexp -nocase {0x([0-9a-f]{9})} "$al5d_offset" match]} {
			    set temp $al5d_offset
				set temp [string trimleft [string trimleft $temp 0] x]
				set len [string length $temp]
				set rem [expr {${len} - 8}]
				set high_size "0x[string range $temp $rem $len]"
				set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
				set low_size [format 0x%08x $low_size]
				set reg "$low_base $high_base $low_size $high_size"
			} else {
				set reg "$low_base $high_base 0x0 $al5d_offset"
			}
		} else {
			set reg "0x0 0x$al5d_baseaddr 0x0 $al5d_offset"
		}
        hsi::utils::add_new_dts_param $al5d_node "reg" "$reg" int
        if {[llength $intr_parent]} {
            set intr_width [get_intr_width $intr_parent]
            hsi::utils::add_new_dts_param $al5d_node "interrupt-parent" "$intr_parent" reference
        }

        if {[llength $intr_width] && [llength $intr_val]} {
            set intrs_List [regexp -inline -all -- {\S+} $intr_val]
            set intrs_cnt [llength $intrs_List]
            set start "[expr {${inst} * $intr_width}]"
            set end "[expr {$start + $intr_width - 1}]"
            if { $intrs_cnt > $intr_width } {
                hsi::utils::add_new_dts_param $al5d_node "interrupts" "[lrange $intrs_List $start $end]" intlist
            } else {
                hsi::utils::add_new_dts_param $al5d_node "interrupts" "$intrs_List" intlist
            }
        }

        if {[llength $intrnames_List]} {
            set intrnames_cnt [llength $intrnames_List]
            if { $intrnames_cnt > 1 } {
                hsi::utils::add_new_dts_param $al5d_node "interrupt-names" "[lindex $intrnames_List $inst]" string
            } else {
                hsi::utils::add_new_dts_param $al5d_node "interrupt-names" "[lindex $intrnames_List 0]" string
            }
        }
        set al5d_baseaddr [format %08x [expr 0x$al5d_baseaddr + $al5d_offset]]
    }
}
