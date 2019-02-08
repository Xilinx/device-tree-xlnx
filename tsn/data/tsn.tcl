#
# (C) Copyright 2018 Xilinx, Inc.
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
	set proc_type [get_sw_proc_prop IP_NAME]
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set eth_ip [get_cells -hier $drv_handle]
	set ip_name [get_property IP_NAME $eth_ip]

	global tsn_ep_node
	global tsn_emac0_node
	global tsn_emac1_node
	global tsn_ex_ep_node
	set tsn_ep_node "tsn_ep"
	set tsn_emac0_node "tsn_emac_0"
	set tsn_emac1_node "tsn_emac_1"
	set tsn_ex_ep_node "tsn_ex_ep"
	set end_point_ip ""
	set end1 ""
	set connectrx_ip ""
	set connecttx_ip ""
	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_be"]
	if {[llength $connected_ip] != 0} {
		set end1_ip [hsi::utils::get_connected_stream_ip $connected_ip "S00_AXIS"]
		if {[llength $end1_ip] != 0} {
			set end1 [lappend end1 $end1_ip]
		} else {
			set connecttx_ip [lappend connecttx_ip $connected_ip]
		}
	}
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_be"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip]!= 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}
	foreach ip [get_drivers] {
		if {[string compare -nocase $ip $end_ip] == 0} {
			set target_handle $ip
		}
	}
	set connectedrx_ipname [get_property IP_NAME $end_ip]
	set id 1
	set queue ""
	if {$connectedrx_ipname == "axi_mcdma"} {
		set num_queues [get_property CONFIG.c_num_s2mm_channels $end_ip]
		set rx_queues  [get_property CONFIG.c_num_mm2s_channels $end_ip]
		if {$num_queues > $rx_queues} {
			set queue $num_queues
		} else {
			set queue $rx_queues
		}
		for {set i 2} {$i <= $num_queues} {incr i} {
			set i [format "%x" $i]
			append id "\""
			append id ",\"" $i
			set i [expr 0x$i]
		}
		set int1 [get_property CONFIG.interrupts $target_handle]
		set int2 [get_property CONFIG.interrupt-parent $target_handle]
		set int3  [get_property CONFIG.interrupt-names $target_handle]
	}
	set inhex [format %x $queue]
	append queues "/bits/ 16 <0x$inhex>"

	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_res"]
	if {[llength $connected_ip] != 0} {
		set end1_ip [hsi::utils::get_connected_stream_ip $connected_ip "S00_AXIS"]
		if {[llength $end1_ip] != 0} {
			set end1 [lappend end1 $end1_ip]
		} else {
			set connecttx_ip [lappend connecttx_ip $connected_ip]
		}
	}
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_res"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip] != 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}

	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_st"]
	if {[llength $connected_ip] != 0} {
		set end1_ip [hsi::utils::get_connected_stream_ip $connected_ip "S00_AXIS"]
		if {[llength $end1_ip] != 0} {
			set end1 [lappend end1 $end1_ip]
		} else {
			set connecttx_ip [lappend connecttx_ip $connected_ip]
		}
	}
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_st"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip] != 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}

	set baseaddr [get_baseaddr $eth_ip no_prefix]
	set num_queues [get_property CONFIG.NUM_PRIORITIES $eth_ip]
	if {[string match -nocase $proc_type "psu_cortexa53"]} {
		hsi::utils::add_new_dts_param $node "#address-cells" 2 int
		hsi::utils::add_new_dts_param $node "#size-cells" 2 int
		hsi::utils::add_new_dts_param "${node}" "ranges" "" boolean
	} elseif {[string match -nocase $proc_type "ps7_cortexa9"]} {
		hsi::utils::add_new_dts_param $node "#address-cells" 1 int
		hsi::utils::add_new_dts_param $node "#size-cells" 1 int
		hsi::utils::add_new_dts_param "${node}" "ranges" "" boolean
	}
	set freq ""
	set clk [get_pins -of_objects $eth_ip "S_AXI_ACLK"]
	if {[llength $clk] } {
		set freq [get_property CLK_FREQ $clk]
	}
	set inhex [format %x $num_queues]
	append numqueues "/bits/ 16 <0x$inhex>"

	set intr_val [get_property CONFIG.interrupts $drv_handle]
	set intr_parent [get_property CONFIG.interrupt-parent $drv_handle]
	set intr_names [get_property CONFIG.interrupt-names $drv_handle]

	set mac0intr ""
	set mac1intr ""
	set ep_sched_irq ""
	foreach intr1 $intr_names {
		set num [regexp -all -inline -- {[0-9]+} $intr1]
		if {$num == 1} {
			lappend mac0intr $intr1
		}
		if {$num == 2} {
			lappend mac1intr $intr1
		}
		if {[string match -nocase $intr1 "interrupt_ptp_timer"]} {
			lappend mac0intr $intr1
		}
		if {[string match -nocase $intr1 "tsn_ep_scheduler_irq"]} {
			lappend ep_sched_irq $intr1
		}
	}
	set switch_present ""
	set periph_list [get_cells -hier]
   set tsn_inst_name [get_cells -filter {IP_NAME =~ "*tsn*"}]
	foreach periph $periph_list {
		if {[string match -nocase "${tsn_inst_name}_switch_core_top_0" $periph] } {
			set switch_offset [get_property CONFIG.SWITCH_OFFSET $eth_ip]
			set high_addr [get_property CONFIG.C_HIGHADDR $eth_ip]
			set one 0x1
			set switch_present 0x1
			set switch_addr [format %08x [expr 0x$baseaddr + $switch_offset]]
			set switch_size [format %08x [expr $high_addr - 0x$switch_addr]]
			set switch_size [format %08x [expr 0x${switch_size} + 1]]
			gen_switch_node $periph $switch_addr $switch_size $numqueues $node $drv_handle $proc_type $eth_ip
		}
		if {[string match -nocase "${tsn_inst_name}" $periph] } {
			set baseaddr [get_baseaddr $eth_ip no_prefix]
			set tmac0_size [get_property CONFIG.TEMAC_1_SIZE $eth_ip]
			if { $switch_present != 1 } {
				gen_mac0_node $periph $baseaddr $tmac0_size $node $proc_type $drv_handle $numqueues $freq $intr_parent $mac0intr $eth_ip $queues $id $end1 $end_point_ip $connectrx_ip $connecttx_ip $tsn_inst_name
			} else {
				set end_point_ip ""
				set connectrx_ip ""
				set connecttx_ip ""
				gen_mac0_node $periph $baseaddr $tmac0_size $node $proc_type $drv_handle $numqueues $freq $intr_parent $mac0intr $eth_ip $queues $id $end1 $end_point_ip $connectrx_ip $connecttx_ip $tsn_inst_name
			}
		}
		if {[string match -nocase "${tsn_inst_name}_tsn_temac_2" $periph] } {
			set baseaddr [get_baseaddr $eth_ip no_prefix]
			set tmac1_offset [get_property CONFIG.TEMAC_2_OFFSET $eth_ip]
			set tmac1_size [get_property CONFIG.TEMAC_2_SIZE $eth_ip]
			set addr_off [format %08x [expr 0x$baseaddr + $tmac1_offset]]
			gen_mac1_node $periph $addr_off $tmac1_size $numqueues $intr_parent $node $drv_handle $proc_type $freq $eth_ip $mac1intr $baseaddr $queues $tsn_inst_name
		}
		if {[string match -nocase "${tsn_inst_name}_tsn_endpoint_block_0" $periph]} {
			set ep_offset [get_property CONFIG.EP_SCHEDULER_OFFSET $eth_ip]
			if {[llength $ep_offset] != 0} {
				set ep_addr [format %08x [expr 0x$baseaddr + $ep_offset]]
				set ep_size [get_property CONFIG.EP_SCHEDULER_SIZE $eth_ip]
				if { $switch_present == 1 } {
					gen_ep_node $periph $ep_addr $ep_size $numqueues $node $drv_handle $proc_type $ep_sched_irq $eth_ip $intr_parent $int3 $int1 $id $end1 $end_point_ip $connectrx_ip $connecttx_ip
				} else {
					set end_point_ip ""
					set connectrx_ip ""
					set connecttx_ip ""
					gen_ep_node $periph $ep_addr $ep_size $numqueues $node $drv_handle $proc_type $ep_sched_irq $eth_ip $intr_parent $int3 $int1 $id $end1 $end_point_ip $connectrx_ip $connecttx_ip
				}
			}
		}
	}
}

proc get_checksum {value} {
	if {[string compare -nocase $value "None"] == 0} {
		set value 0
	} elseif {[string compare -nocase $value "Partial"] == 0} {
		set value 1
	} else {
		set value 2
	}
	return $value
}

proc get_phytype {value} {
	if {[string compare -nocase $value "MII"] == 0} {
		set value 0
	} elseif {[string compare -nocase $value "GMII"] == 0} {
		set value 1
	} elseif {[string compare -nocase $value "RGMII"] == 0} {
		set value 3
	} elseif {[string compare -nocase $value "SGMII"] == 0} {
		set value 4
	} else {
		set value 5
	}
	return $value
}

proc pcspma_phy_node {slave tsn_inst_name} {
	set phyaddr [get_property CONFIG.PHYADDR $slave]
	set phyaddr [::hsi::utils::convert_binary_to_decimal $phyaddr]
	if {[string match -nocase $slave "${tsn_inst_name}_tsn_temac_2"]} {
		set phyaddr "2"
	} else {
		set phyaddr "1"
	}
	set phymode "phy$phyaddr"
	return "$phyaddr $phymode"
}

proc gen_phy_node args {
	set mdio_node [lindex $args 0]
	set phy_name [lindex $args 1]
	set phya [lindex $args 2]

	set phy_node [add_or_get_dt_node -l ${phy_name} -n phy -u $phya -p $mdio_node]
	hsi::utils::add_new_dts_param "${phy_node}" "reg" 0 int
	hsi::utils::add_new_dts_param "${phy_node}" "device_type" "ethernet-phy" string
	hsi::utils::add_new_dts_param  "${phy_node}" "compatible"  "marvell,88e1111" string
	return $phy_node
}

proc gen_ep_node {periph ep_addr ep_size numqueues parent_node drv_handle proc_type ep_sched_irq eth_ip intr_parent int3 int1 id end1 end_point_ip connectrx_ip connecttx_ip} {
	global tsn_ep_node
	set ep_node [add_or_get_dt_node -n "tsn_ep" -l $tsn_ep_node -u $ep_addr -p $parent_node]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set ep_reg "0x$ep_addr $ep_size"
	} else {
		set ep_reg "0x0 0x$ep_addr 0x0 $ep_size"
	}
	foreach intr $int3 {
		lappend ep_sched_irq $intr
	}
	if {[llength $ep_sched_irq] != 0} {
		set intr_num [get_intr_id $eth_ip [lindex $ep_sched_irq 0]]
	}
	foreach int $int1 {
		lappend intr_num $int
	}
	hsi::utils::add_new_dts_param "${ep_node}" "interrupt-names" $ep_sched_irq stringlist
	hsi::utils::add_new_dts_param ${ep_node} "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${ep_node}" "interrupt-parent" $intr_parent reference

	hsi::utils::add_new_dts_param "${ep_node}" "reg" $ep_reg int
	hsi::utils::add_new_dts_param "${ep_node}" "compatible" "xlnx,tsn-ep" string
	hsi::utils::add_new_dts_param "${ep_node}" "xlnx,num-tc" $numqueues noformating
	hsi::utils::add_new_dts_param "${ep_node}" "xlnx,channel-ids" $id string
	set mac_addr "00 0A 35 00 01 10"
	hsi::utils::add_new_dts_param $ep_node "local-mac-address" ${mac_addr} bytelist
	hsi::utils::add_new_dts_param "$ep_node" "xlnx,eth-hasnobuf" "" boolean
	global tsn_ex_ep_node
	set tsn_ex_ep [get_property CONFIG.EN_EP_PORT_EXTN $eth_ip]
	if {[string match -nocase $tsn_ex_ep "true"]} {
		set tsn_ex_ep_node [add_or_get_dt_node -n "tsn_ex_ep" -l $tsn_ex_ep_node -p $parent_node]
		hsi::utils::add_new_dts_param "${tsn_ex_ep_node}" "compatible" "xlnx,tsn-ex-ep" string
		set mac_addr "00 0A 35 00 01 0d"
		hsi::utils::add_new_dts_param $tsn_ex_ep_node "local-mac-address" ${mac_addr} bytelist
		hsi::utils::add_new_dts_param "$tsn_ex_ep_node" "tsn,endpoint" $tsn_ep_node reference
	}

	set len [llength $end1]
	switch $len {
		"1" {
			set ref_id [lindex $end1 0]
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]>, <&[lindex $end1 2]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}
	set len3 [llength $connecttx_ip]
	switch $len3 {
		"1" {
			set ref_id [lindex $connecttx_ip 0]
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $connecttx_ip 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $connecttx_ip 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]>, <&[lindex $connecttx_ip 2]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}
	if {$len && $len3} {
		if {$len == 1} {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]>, <&[lindex $connecttx_ip 2]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
		if {$len == 2} {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]>, <&[lindex $connecttx_ip 0]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}

	set len1 [llength $end_point_ip]
	switch $len1 {
		"1" {
			set ref_id [lindex $end_point_ip 0]
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $end_point_ip 0]
			append ref_id ">, <&[lindex $end_point_ip 1]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $end_point_ip 0]
			append ref_id ">, <&[lindex $end_point_ip 1]>, <&[lindex $end_point_ip 2]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
	}
	set len2 [llength $connectrx_ip]
	switch $len2 {
		"1" {
			set ref_id [lindex $connectrx_ip 0]
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $connectrx_ip 0]
			append ref_id ">, <&[lindex $connectrx_ip 1]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $connectrx_ip 0]
			append ref_id ">, <&[lindex $connectrx_ip 1]>, <&[lindex $connectrx_ip 2]"
			hsi::utils::add_new_dts_param "${ep_node}" "axistream-connected-rx" "$ref_id" reference
		}
	}
}

proc gen_switch_node {periph addr size numqueues parent_node drv_handle proc_type eth_ip} {
	set switch_node [add_or_get_dt_node -n "tsn_switch" -l epswitch -u $addr -p $parent_node]
	set hwaddr_learn [get_property CONFIG.EN_HW_ADDR_LEARNING $eth_ip]
	set mgmt_tag [get_property CONFIG.EN_INBAND_MGMT_TAG $eth_ip]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set switch_reg "0x$addr 0x$size"
	} else {
		set switch_reg "0x0 0x$addr 0x0 0x$size"
	}
	hsi::utils::add_new_dts_param "${switch_node}" "reg" $switch_reg int
	hsi::utils::add_new_dts_param "${switch_node}" "compatible" "xlnx,tsn-switch" string
	hsi::utils::add_new_dts_param "${switch_node}" "xlnx,num-tc" $numqueues noformating
	if {[string match -nocase $hwaddr_learn "true"]} {
		hsi::utils::add_new_dts_param "${switch_node}" "xlnx,has-hwaddr-learning" "" boolean
	}
	if {[string match -nocase $mgmt_tag "true"]} {
		hsi::utils::add_new_dts_param "${switch_node}" "xlnx,has-inband-mgmt-tag" "" boolean
	}
	set inhex [format %x 3]
	append numports "/bits/ 16 <0x$inhex>"
	hsi::utils::add_new_dts_param "${switch_node}" "xlnx,num-ports" $numports noformating
	global tsn_ep_node
	global tsn_emac0_node
	global tsn_emac1_node
	set end1 ""
	set end1 [lappend end1 $tsn_ep_node]
	set end1 [lappend end1 $tsn_emac0_node]
	set end1 [lappend end1 $tsn_emac1_node]
	set len [llength $end1]
        switch $len {
                "1" {
                        set ref_id [lindex $end1 0]
                        hsi::utils::add_new_dts_param "${switch_node}" "ports" "$ref_id" reference
                }
                "2" {
                        set ref_id [lindex $end1 0]
                        append ref_id ">, <&[lindex $end1 1]"
                        hsi::utils::add_new_dts_param "${switch_node}" "ports" "$ref_id" reference
                }
                "3" {
                        set ref_id [lindex $end1 0]
                        append ref_id ">, <&[lindex $end1 1]>, <&[lindex $end1 2]"
                        hsi::utils::add_new_dts_param "${switch_node}" "ports" "$ref_id" reference
                }
        }

}

proc gen_mac0_node {periph addr size parent_node proc_type drv_handle numqueues freq intr_parent mac0intr eth_ip queues id end1 end_point_ip connectrx_ip connecttx_ip tsn_inst_name} {
	global tsn_emac0_node
	set tsn_mac_node [add_or_get_dt_node -n "tsn_emac_0" -l $tsn_emac0_node -u $addr -p $parent_node]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set tsnreg "0x$addr $size"
	} else {
		set tsnreg "0x0 0x$addr 0x0 $size"
	}
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "reg" $tsnreg int
	set tsn_comp "xlnx,tsn-ethernet-1.00.a"
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "compatible" $tsn_comp stringlist
	set mdionode [add_or_get_dt_node -l ${drv_handle}_mdio0 -n mdio -p $tsn_mac_node]
	hsi::utils::add_new_dts_param "${mdionode}" "#address-cells" 1 int ""
	hsi::utils::add_new_dts_param "${mdionode}" "#size-cells" 0 int ""
	set phytype [string tolower [get_property CONFIG.PHYSICAL_INTERFACE $periph]]
	set txcsum "0"
	set rxcsum "0"
	set mac_addr "00 0A 35 00 01 0e"
	set phy_type [get_phytype $phytype]
	set qbv_offset [get_property CONFIG.TEMAC_1_SCHEDULER_OFFSET $periph]
	set qbv_size [get_property CONFIG.TEMAC_1_SCHEDULER_SIZE $periph]
	hsi::utils::add_new_dts_param $tsn_mac_node "local-mac-address" ${mac_addr} bytelist
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,txsum" $txcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,rxsum" $rxcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,eth-hasnobuf" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "phy-mode" $phytype string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,phy-type" $phy_type string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-tc" $numqueues noformating
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,channel-ids" $id string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-queues" $queues noformating
	global tsn_ep_node
	hsi::utils::add_new_dts_param "$tsn_mac_node" "tsn,endpoint" $tsn_ep_node reference
	if {[llength $qbv_offset] != 0} {
		set qbv_addr 0x[format %08x [expr 0x$addr + $qbv_offset]]
		hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,qbv-addr" $qbv_addr int
		hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,qbv-size" $qbv_size int
	}
	set intr_len [llength $mac0intr]
	for {set i 0} {$i < $intr_len} {incr i} {
		lappend intr [lindex $mac0intr $i]
		lappend intr_num [get_intr_id $eth_ip [lindex $mac0intr $i]]
	}
	regsub -all "\{||\t" $intr_num {} intr_num
	regsub -all "\}||\t" $intr_num {} intr_num
	hsi::utils::add_new_dts_param $tsn_mac_node "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "interrupt-parent" $intr_parent reference
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "interrupt-names" $mac0intr stringlist
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "clock-frequency" $freq int
	if {$phytype == "rgmii" || $phytype == "gmii"} {
		set phynode [pcspma_phy_node $periph $tsn_inst_name]
		set phya [lindex $phynode 0]
		if { $phya != "-1"} {
			set phy_name "[lindex $phynode 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "phy-handle" $phy_name reference
			gen_phy_node $mdionode $phy_name $phya
		}
	}
	set len [llength $end1]
	switch $len {
		"1" {
			set ref_id [lindex $end1 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]>, <&[lindex $end1 2]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}
	set len3 [llength $connecttx_ip]
	switch $len3 {
		"1" {
			set ref_id [lindex $connecttx_ip 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $connecttx_ip 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $connecttx_ip 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]>, <&[lindex $connecttx_ip 2]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}
	if {$len && $len3} {
		if {$len == 1} {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $connecttx_ip 1]>, <&[lindex $connecttx_ip 2]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		if {$len == 2} {
			set ref_id [lindex $end1 0]
			append ref_id ">, <&[lindex $end1 1]>, <&[lindex $connecttx_ip 0]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
	}

	set len1 [llength $end_point_ip]
	switch $len1 {
		"1" {
			set ref_id [lindex $end_point_ip 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $end_point_ip 0]
			append ref_id ">, <&[lindex $end_point_ip 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $end_point_ip 0]
			append ref_id ">, <&[lindex $end_point_ip 1]>, <&[lindex $end_point_ip 2]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
	}
	set len2 [llength $connectrx_ip]
	switch $len2 {
		"1" {
			set ref_id [lindex $connectrx_ip 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $connectrx_ip 0]
			append ref_id ">, <&[lindex $connectrx_ip 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $connectrx_ip 0]
			append ref_id ">, <&[lindex $connectrx_ip 1]>, <&[lindex $connectrx_ip 2]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-rx" "$ref_id" reference
		}
	}
}

proc gen_mac1_node {periph addr size numqueues intr_parent parent_node drv_handle proc_type freq eth_ip mac1intr baseaddr queues tsn_inst_name} {
	global tsn_emac1_node
	set tsn_mac_node [add_or_get_dt_node -n "tsn_emac_1" -l $tsn_emac1_node -u $addr -p $parent_node]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set tsn_reg "0x$addr $size"
	} else {
		set tsn_reg "0x0 0x$addr 0x0 $size"
	}
	set tsn_comp "xlnx,tsn-ethernet-1.00.a"
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "reg" $tsn_reg int
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "compatible" $tsn_comp stringlist
	set mdionode [add_or_get_dt_node -l ${drv_handle}_mdio1 -n mdio -p $tsn_mac_node]
	hsi::utils::add_new_dts_param "${mdionode}" "#address-cells" 1 int ""
	hsi::utils::add_new_dts_param "${mdionode}" "#size-cells" 0 int ""
	set tsn_emac2_ip [get_property IP_NAME $periph]
	set tsn_ip [get_cells -hier -filter {IP_NAME == $tsn_emac2_ip}]
	set phytype [string tolower [get_property CONFIG.Physical_Interface $periph]]
	set txcsum "0"
	set rxcsum "0"
	set mac_addr "00 0A 35 00 01 0f"
	set phy_type [get_phytype $phytype]
	set qbv_offset [get_property CONFIG.TEMAC_2_SCHEDULER_OFFSET $eth_ip]
	set qbv_size [get_property CONFIG.TEMAC_2_SCHEDULER_SIZE $eth_ip]
	hsi::utils::add_new_dts_param $tsn_mac_node "local-mac-address" ${mac_addr} bytelist
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,txsum" $txcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,rxsum" $rxcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn-slave" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,eth-hasnobuf" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "phy-mode" $phytype string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,phy-type" $phy_type string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-tc" $numqueues noformating
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-queues" $queues noformating
	global tsn_ep_node
	hsi::utils::add_new_dts_param "$tsn_mac_node" "tsn,endpoint" $tsn_ep_node reference
	if {[llength $qbv_offset] != 0} {
		set qbv_addr 0x[format %08x [expr 0x$baseaddr + $qbv_offset]]
		hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,qbv-addr" $qbv_addr int
		hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,qbv-size" $qbv_size int
	}
	set intr_len [llength $mac1intr]
	for {set i 0} {$i < $intr_len} {incr i} {
		lappend intr [lindex $mac1intr $i]
		lappend intr_num [get_intr_id $eth_ip [lindex $mac1intr $i]]
	}
	regsub -all "\{||\t" $intr_num {} intr_num
	regsub -all "\}||\t" $intr_num {} intr_num
	hsi::utils::add_new_dts_param $tsn_mac_node "interrupts" $intr_num intlist
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "interrupt-parent" $intr_parent reference
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "interrupt-names" $mac1intr stringlist
	hsi::utils::add_new_dts_param "${tsn_mac_node}" "clock-frequency" $freq int
	if {$phytype == "rgmii" || $phytype == "gmii"} {
		set phynode [pcspma_phy_node $periph $tsn_inst_name]
		set phya [lindex $phynode 0]
		if { $phya != "-1"} {
			set phy_name "[lindex $phynode 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "phy-handle" $phy_name reference
			gen_phy_node $mdionode $phy_name $phya
		}
	}
}
