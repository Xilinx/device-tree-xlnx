proc get_clock_frequency {ip_handle portname} {
    set clk ""
    set clkhandle [get_pins -of_objects $ip_handle $portname]
    if {[string compare -nocase $clkhandle ""] != 0} {
        set clk [get_property CLK_FREQ $clkhandle ]
    }
    return $clk
}

proc gen_mb_ccf_subnode {dts_handle name freq reg} {
    set clk_node [hsm::utils::get_or_create_child_node $dts_handle "clocks"]

    set node_name "clk_${name}"
    set node_handle [hsm::utils::get_or_create_child_node $clk_node ${node_name}]

    hsm::utils::add_new_property $clk_node "#address-cells" int 1
    hsm::utils::add_new_property $clk_node "#size-cells" int 0

    # clk subnode data
    hsm::utils::add_new_property $node_handle "compatible" stringlist "fixed-clock"
    hsm::utils::add_new_property $node_handle "#clock-cells" int 0
    hsm::utils::add_new_property $node_handle "clock-output-names" string $node_name
    hsm::utils::add_new_property $node_handle "reg" int $reg
    hsm::utils::add_new_property $node_handle "clock-frequency" int $freq
}

proc generate_mb_ccf_node {os_handle} {
    set drv_list [get_drivers]
    set pl_node [hsm::utils::get_or_create_child_node $os_handle "dtg.pl"]
    # list of ip should have the clocks property
    set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_ethernet axi_ethernet_buffer axi_timebase_wdt axi_can can"

    set proc_name [get_property HW_INSTANCE [get_sw_processor]]
    set hwproc [get_cells -filter " NAME==$proc_name"]
    set proctype [get_property IP_NAME $hwproc]
    if {[string match -nocase $proctype "microblaze"]} {
        set bus_clk_list ""
        foreach drv ${drv_list} {
            set hwinst [get_property HW_INSTANCE $drv]
            set iptype [get_property IP_NAME [get_cells $hwinst]]
            if  {[lsearch $valid_ip_list $iptype] < 0 } {
                continue
            }
            # get bus clock frequency
            set clk_freq [get_clock_frequency [get_cells $drv] "S_AXI_ACLK"]
            if {![string equal $clk_freq ""]} {
                # FIXME: bus clk source count should based on the clock generator not based on clk freq diff
                if  {[lsearch $bus_clk_list $clk_freq] < 0 } {
                    set bus_clk_list [lappend $bus_clk_list $clk_freq]
                }
                set bus_clk_cnt [lsearch -exact $bus_clk_list $clk_freq]
                # create the node and assuming reg 0 is taken by cpu
                gen_mb_ccf_subnode $pl_node bus_${bus_clk_cnt} $clk_freq [expr ${bus_clk_cnt} + 1]
                # set bus clock frequency (current it is there)
                set_property CONFIG.clock-frequency $clk_freq [get_drivers $drv]
                hsm::utils::add_new_property [get_drivers $drv] "clocks" int &clk_bus_${bus_clk_cnt}
            }
        }
        set cpu_clk_freq [get_clock_frequency $hwproc "CLK"]
        # issue:
        # - hardcoded reg number cpu clock node
        # - assume clk_cpu for mb cpu
        # - only applies to master mb cpu
        gen_mb_ccf_subnode $pl_node cpu $cpu_clk_freq 0
        #hsm::utils::add_new_property [get_drivers $hwproc] "clocks" int &clk_cpu
    }
}

proc zynq_gen_pl_clk_binding {} {
    # add dts binding for required nodes
    #   clock-names = "ref_clk";
    #   clocks = <&clkc 0>;
    set proc_name [get_property HW_INSTANCE [get_sw_processor]]
    set hwproc [get_cells -filter " NAME==$proc_name"]
    set proctype [get_property IP_NAME $hwproc]
    # Assuming the device support mb ccf should generated this
    set valid_ip_list "axi_timer axi_uartlite axi_uart16550 axi_ethernet axi_ethernet_buffer axi_timebase_wdt axi_can can"

    set drv_list [get_drivers]
    if { [string match -nocase $proctype "ps7_cortexa9"] } {
        foreach drv ${drv_list} {
            set hwinst [get_property HW_INSTANCE $drv]
            set iptype [get_property IP_NAME [get_cells $hwinst]]
            if  {[lsearch $valid_ip_list $iptype] < 0 } {
                continue
        }
        # this is hardcoded - maybe dynamic detection
        hsm::utils::add_new_property $drv "clock-names" stringlist "ref_clk"
        hsm::utils::add_new_property $drv "clocks" reference "clkc 0"
        }
    }
}

# workaround for moving nodes around until HSM core to support it
proc move_node {node_drv parent_node_drv} {
    set new_node ""
    if {[llength $node_drv] == 0 && [llength $parent_node_drv] == 0 } {
        return $new_node
    }
    set node_class [get_property CLASS $node_drv]
    set parent_class [get_property CLASS $parent_node_drv ]
    #set ip [get_cells $node_drv]
    #set ip_base_addr [string tolower [get_property CONFIG.C_S_AXI_BASEADDR $ip]]
    #set ip_name [get_property IP_NAME $ip]
    #regsub -- "_" $ip_name "-" ip_name
    # FIXME: the node can't be create with <node name>: <node nome>@<addr>
    set new_node [::hsm::utils::add_new_child_node $parent_node_drv "${node_drv}"]
    set params [get_comp_params -of_objects $node_drv]
    foreach param $params {
        set type [get_property CONFIG.type $param]
        set value [get_property VALUE $param]
        ::hsm::utils::add_new_property $new_node "$param" "$type" $value
    }
    # disable the old node generation
    set_property NAME "none" $node_drv
    return $new_node
}

proc get_ip_prop {drv_handle pram} {
    set ip [get_cells $drv_handle]
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

    set count [hsm::utils::get_os_parameter_value $var_name]
    if {[llength $count] == 0} {
        if {[string match -nocase "True" $ip_check]} {
            set count 1
        } else {
            set count 0
        }
    }

    if {[string match -nocase "True" $ip_check]} {
        set ip [get_cells $drv_handle]
        if {[string match -nocase $os_ip $ip]} {
            set ip_type [get_property IP_NAME $ip]
            if {[string match -nocase $ip_type]} {
                set_property ${conf_prop} 0 $drv_handle
            }
            return
        }
    }

    set_property $conf_prop $count $drv_handle
    incr count
    ::hsm::utils::set_os_parameter_value $var_name $count

}

proc gen_count_prop {drv_handle data_dict} {
    dict for {dev_type dev_conf_mapping} [dict get $data_dict] {
        set os_conf_dev_var [dict get $data_dict $dev_type "os_device"]
        set valid_ip_list [dict get $data_dict $dev_type "ip"]
        set drv_conf [dict get $data_dict $dev_type "drv_conf"]
        set os_count_name [dict get $data_dict $dev_type "os_count_name"]

        set hwinst [get_property HW_INSTANCE $drv_handle]
        set iptype [get_property IP_NAME [get_cells $hwinst]]
        if  {[lsearch $valid_ip_list $iptype] < 0 } {
            continue
        }
        inc_os_prop $drv_handle $os_conf_dev_var $os_count_name $drv_conf
    }
}

proc gen_dev_conf {} {
    # data to populated certain configs for different devices
    set data_dict {
        uart {
            os_device "CONFIG.console_device"
            ip "axi_uartlite axi_uart16550 ps7_uart"
            os_count_name "serial_count"
            drv_conf "CONFIG.port-number"
        }
    }
    # update CONFIG.<para> for each driver when match driver is found
    foreach drv [get_drivers] {
        gen_count_prop $drv $data_dict
    }
}

# move nand or nor/sram flash under smcc node
proc ps7_smc_workaround {os_handle} {
    foreach drv_handle [get_drivers] {
        set ip_name [get_ip_prop $drv_handle IP_NAME]
        switch -exact $ip_name {
            "ps7_nand" {set nand $drv_handle}
            "ps7_sram" {set sram $drv_handle}
            "ps7_smcc" {set smcc $drv_handle}
            default {continue}
        }
    }
    # check if smcc and nand exists
    if {[info exists smcc]} {
        if {[info exists nand]} {
            set nand_node [move_node $nand $smcc]
            # Hack to add reg as hsm core did not export the data
            ::hsm::utils::add_new_property $nand_node "reg" "hexintlist" "0xe1000000 0x1000000"
        } elseif {[info exists sram]} {
            set sram_node [move_node $sram $smcc]
            # TODO: check configuration before setting the size
            ::hsm::utils::add_new_property $sram_node "reg" "hexintlist" "0xe2000000 0x2000000"
        }
    }
}

# For calling from top level BSP
proc bsp_drc {os_handle} {
}

# If standalone purpose
proc device_tree_drc {os_handle} {
	bsp_drc $os_handle
    hsm::utils::add_new_child_node $os_handle "global_params"
}

proc generate {lib_handle} {
}

proc post_generate {os_handle} {
    add_chosen $os_handle 
    clean_os $os_handle
    add_ps7_pmu $os_handle
    generate_mb_ccf_node $os_handle
    ps7_smc_workaround $os_handle
    zynq_gen_pl_clk_binding
    gen_dev_conf
}

proc clean_os { os_handle } {
    #deleting unwanted child nodes of OS for dumping into dts file
    set node [get_nodes -of_objects $os_handle "global_params"]
    if { [llength $node] } {
        delete_objs $node
    }
}

proc add_chosen { os_handle } {
    set system_node [hsm::utils::get_or_create_child_node $os_handle "dtg.system"]
    set chosen_node [hsm::utils::get_or_create_child_node $system_node "chosen"]

    #getting boot arguments 
    set bootargs [get_property CONFIG.bootargs $os_handle]
    if { [llength $bootargs] == 0 } {
        set console [hsm::utils::get_os_parameter_value "console"]
        if { [llength $console] } {
            set bootargs "console=$console"
        }
    }
    if { [llength $bootargs]  } {
        hsm::utils::add_new_property $chosen_node "bootargs" string $bootargs
    }
    set consoleip [get_property CONFIG.console_device $os_handle]
    hsm::utils::add_new_property $chosen_node "linux,stdout-path" aliasref $consoleip
}

#Hack to disable ps7_pmu from bus and add it explicitly parallel to cpu
proc add_ps7_pmu { os_handle } {
    set proc_name [get_property HW_INSTANCE [get_sw_processor]]
    set hwproc [get_cells -filter " NAME==$proc_name"]
    set proctype [get_property IP_NAME $hwproc]
    if { [string match -nocase $proctype "ps7_cortexa9"] } {


        #get PMU driver handler and disabling it 
        set all_drivers [get_drivers] 
        foreach driver $all_drivers {
            set hwinst [get_property HW_INSTANCE $driver]
            set ip [get_cells $hwinst]
            set iptype [get_property IP_NAME $ip]
            if { [string match -nocase $iptype "ps7_pmu" ] } {
                set_property NAME "none" $driver
            }
        }

        #adding hardcoded pmu into system node
        set ps_node [hsm::utils::get_or_create_child_node $os_handle "dtg.ps"]
        set pmu_node [hsm::utils::get_or_create_child_node $ps_node "ps7_pmu"]
        hsm::utils::add_new_property $pmu_node "reg" hexintlist "0xf8891000 0x1000 0xf8893000 0x1000"
        hsm::utils::add_new_property $pmu_node "reg-names" stringlist "cpu0 cpu1"
        hsm::utils::add_new_property $pmu_node "compatible" stringlist "arm,cortex-a9-pmu"
    }
}

