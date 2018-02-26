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
	set eth_ip [get_cells -hier $drv_handle]
	set ip_name [get_property IP_NAME $eth_ip]

	set stream_connected ""
	set end_point_ip ""
	set connectrx_ip ""
	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_be"]
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_be"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip]!= 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}
	if {[llength $connected_ip] != 0} {
		set stream_connected [lappend stream_connected $connected_ip]
	}

	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_res"]
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_res"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip] != 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}
	if {[llength $connected_ip] != 0} {
		set stream_connected [lappend stream_connected $connected_ip]
	}

	set connected_ip [hsi::utils::get_connected_stream_ip $eth_ip "tx_axis_st"]
	set connect_ip [hsi::utils::get_connected_stream_ip $eth_ip "rx_axis_st"]
	if {[llength $connect_ip] != 0} {
		set end_ip [hsi::utils::get_connected_stream_ip $connect_ip "M00_AXIS"]
		if {[llength $end_ip] != 0} {
			set end_point_ip [lappend end_point_ip $end_ip]
		} else {
			set connectrx_ip [lappend connectrx_ip $connect_ip]
		}
	}
	if {[llength $connected_ip] != 0} {
		set stream_connected [lappend stream_connected $connected_ip]
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
		if {[string match -nocase $intr1 "tsn_ep_scheduler_irq"]} {
			lappend ep_sched_irq $intr1
		}
	}
	set periph_list [get_cells -hier]
	foreach periph $periph_list {
		if {[string match -nocase "tsn_endpoint_ethernet_mac_0" $periph] } {
			set baseaddr [get_baseaddr $eth_ip no_prefix]
			set tmac0_size [get_property CONFIG.TEMAC_1_SIZE $eth_ip]
			gen_mac0_node $periph $baseaddr $tmac0_size $node $proc_type $drv_handle $stream_connected $end_point_ip $numqueues $freq $intr_parent $mac0intr $eth_ip $connectrx_ip
		}
		if {[string match -nocase "tsn_endpoint_ethernet_mac_0_tsn_temac_2" $periph] } {
			set tmac1_offset [get_property CONFIG.TEMAC_2_OFFSET $eth_ip]
			set tmac1_size [get_property CONFIG.TEMAC_2_SIZE $eth_ip]
			set addr_off [format %08x [expr 0x$baseaddr + $tmac1_offset]]
			gen_mac1_node $periph $addr_off $tmac1_size $numqueues $intr_parent $stream_connected $end_point_ip $node $drv_handle $proc_type $freq $eth_ip $mac1intr $connectrx_ip
		}
		if {[string match -nocase "tsn_endpoint_ethernet_mac_0_switch_core_top_0" $periph] } {
			set switch_offset [get_property CONFIG.SWITCH_OFFSET $eth_ip]
			set high_addr [get_property CONFIG.C_HIGHADDR $eth_ip]
			set one 0x1
			set switch_addr [format %08x [expr 0x$baseaddr + $switch_offset]]
			set switch_size [format %08x [expr $high_addr - 0x$switch_addr]]
			set switch_size [format %08x [expr 0x${switch_size} + 1]]
			gen_switch_node $periph $switch_addr $switch_size $numqueues $node $drv_handle $proc_type
		}
		if {[string match -nocase "tsn_endpoint_ethernet_mac_0_tsn_endpoint_block_0" $periph]} {
			set ep_offset [get_property CONFIG.EP_SCHEDULER_OFFSET $eth_ip]
			if {[llength $ep_offset] != 0} {
			set ep_addr [format %08x [expr 0x$baseaddr + $ep_offset]]
			set ep_size [get_property CONFIG.EP_SCHEDULER_SIZE $eth_ip]
			gen_ep_node $periph $ep_addr $ep_size $numqueues $node $drv_handle $proc_type $ep_sched_irq $eth_ip $intr_parent
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

proc pcspma_phy_node {slave} {
	set phyaddr [get_property CONFIG.PHYADDR $slave]
	set phyaddr [::hsi::utils::convert_binary_to_decimal $phyaddr]
	if {[string match -nocase $slave "tsn_endpoint_ethernet_mac_0_tsn_temac_2"]} {
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

proc gen_ep_node {periph ep_addr ep_size numqueues parent_node drv_handle proc_type ep_sched_irq eth_ip intr_parent} {
	set ep_node [add_or_get_dt_node -n "tsn_ep" -l tsn_ep -u $ep_addr -p $parent_node]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set ep_reg "0x$ep_addr $ep_size"
	} else {
		set ep_reg "0x0 0x$ep_addr 0x0 $ep_size"
	}
	if {[llength $ep_sched_irq] != 0} {
		set intr_num [get_intr_id $eth_ip [lindex $ep_sched_irq 0]]
		hsi::utils::add_new_dts_param "${ep_node}" "interrupt-names" $ep_sched_irq stringlist
		hsi::utils::add_new_dts_param ${ep_node} "interrupts" $intr_num intlist
		hsi::utils::add_new_dts_param "${ep_node}" "interrupt-parent" $intr_parent reference
	}
	hsi::utils::add_new_dts_param "${ep_node}" "reg" $ep_reg int
	hsi::utils::add_new_dts_param "${ep_node}" "compatible" "xlnx,tsn-ep" string
	hsi::utils::add_new_dts_param "${ep_node}" "xlnx,num-queues" $numqueues noformating
}

proc gen_switch_node {periph addr size numqueues parent_node drv_handle proc_type} {
	set switch_node [add_or_get_dt_node -n "tsn_switch" -l epswitch -u $addr -p $parent_node]
	if {[string match -nocase $proc_type "ps7_cortexa9"]} {
		set switch_reg "0x$addr 0x$size"
	} else {
		set switch_reg "0x0 0x$addr 0x0 0x$size"
	}
	hsi::utils::add_new_dts_param "${switch_node}" "reg" $switch_reg int
	hsi::utils::add_new_dts_param "${switch_node}" "compatible" "xlnx,tsn-switch" string
	hsi::utils::add_new_dts_param "${switch_node}" "xlnx,num-queues" $numqueues noformating
}

proc gen_mac0_node {periph addr size parent_node proc_type drv_handle stream_connected end_point_ip numqueues freq intr_parent mac0intr eth_ip connectrx_ip} {
	set tsn_mac_node [add_or_get_dt_node -n "tsn_emac_0" -l tsn_emac_0 -u $addr -p $parent_node]
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
	hsi::utils::add_new_dts_param $tsn_mac_node "local-mac-address" ${mac_addr} bytelist
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,txsum" $txcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,rxsum" $rxcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,eth-hasnobuf" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "phy-mode" $phytype string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,phy-type" $phy_type string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-queues" $numqueues noformating
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
	if {$phytype == "rgmii"} {
		set phynode [pcspma_phy_node $periph]
		set phya [lindex $phynode 0]
		if { $phya != "-1"} {
			set phy_name "[lindex $phynode 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "phy-handle" $phy_name reference
			gen_phy_node $mdionode $phy_name $phya
		}
	}
	set len [llength $stream_connected]
	switch $len {
		"1" {
			set ref_id [lindex $stream_connected 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $stream_connected 0]
			append ref_id ">, <&[lindex $stream_connected 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $stream_connected 0]
			append ref_id ">, <&[lindex $stream_connected 1]>, <&[lindex $stream_connected 2]"
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

proc gen_mac1_node {periph addr size numqueues intr_parent stream_connected end_point_ip parent_node drv_handle proc_type freq eth_ip mac1intr connectrx_ip} {
	set tsn_mac_node [add_or_get_dt_node -n "tsn_emac_1" -l tsn_emac_1 -u $addr -p $parent_node]
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
	hsi::utils::add_new_dts_param $tsn_mac_node "local-mac-address" ${mac_addr} bytelist
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,txsum" $txcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,rxsum" $rxcsum int
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,tsn-slave" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,eth-hasnobuf" "" boolean
	hsi::utils::add_new_dts_param "$tsn_mac_node" "phy-mode" $phytype string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,phy-type" $phy_type string
	hsi::utils::add_new_dts_param "$tsn_mac_node" "xlnx,num-queues" $numqueues noformating
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
	if {$phytype == "rgmii"} {
		set phynode [pcspma_phy_node $periph]
		set phya [lindex $phynode 0]
		if { $phya != "-1"} {
			set phy_name "[lindex $phynode 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "phy-handle" $phy_name reference
			gen_phy_node $mdionode $phy_name $phya
		}
	}
	set len [llength $stream_connected]
	switch $len {
		"1" {
			set ref_id [lindex $stream_connected 0]
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"2" {
			set ref_id [lindex $stream_connected 0]
			append ref_id ">, <&[lindex $stream_connected 1]"
			hsi::utils::add_new_dts_param "${tsn_mac_node}" "axistream-connected-tx" "$ref_id" reference
		}
		"3" {
			set ref_id [lindex $stream_connected 0]
			append ref_id ">, <&[lindex $stream_connected 1]>, <&[lindex $stream_connected 2]"
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
