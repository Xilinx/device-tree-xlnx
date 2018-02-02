#
# (C) Copyright 2017 Xilinx, Inc.
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
    # try to source the common tcl procs
    # assuming the order of return is based on repo priority
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    # Generate properties required for vcu node
    set node [gen_peripheral_nodes $drv_handle]
    hsi::utils::add_new_dts_param "${node}" "#address-cells" 2 int
    hsi::utils::add_new_dts_param "${node}" "#size-cells" 2 int
    set tab "\n\t\t\t\t"
    set reg "0x0 0xa0040000 0x0 0x1000>,$tab<0x0 0xa0041000 0x0 0x1000"
    set_drv_prop $drv_handle reg $reg int
    set intr_val [get_property CONFIG.interrupts $drv_handle]
    set intr_parent [get_property CONFIG.interrupt-parent $drv_handle]
    set clock-names "pll_ref"
    set clock-names [append clock-names " aclk"]
    hsi::utils::add_new_dts_param "${node}" "clock-names" ${clock-names} stringlist
    zynq_gen_pl_clk_binding $drv_handle
    set first_reg_name "vcu_slcr"
    set second_reg_name " logicore"
    set reg_name [append first_reg_name $second_reg_name]
    hsi::utils::add_new_dts_param "${node}" "reg-names" ${reg_name} stringlist
    hsi::utils::add_new_dts_param "${node}" "ranges" "" boolean
    set compatible [get_ipdetails $drv_handle "compatible"]
    set vcu_comp " xlnx,vcu"
    set compatible [append compatible $vcu_comp]
    set_drv_prop $drv_handle compatible "$compatible" stringlist
    hsi::utils::add_new_dts_param "${node}" "compatible" ${compatible} stringlist

    # Generate child encoder
    set ver [get_ipdetails $drv_handle "ver"]
    set encoder_node [add_or_get_dt_node -l "encoder" -n "al5e@a0000000" -p $node]
    set encoder_comp "al,al5e-${ver}"
    set encoder_comp [append encoder_comp " al,al5e"]
    hsi::utils::add_new_dts_param "${encoder_node}" "compatible" $encoder_comp stringlist
    set encoder_reg "0x0 0xa0000000 0x0 0x10000"
    hsi::utils::add_new_dts_param "${encoder_node}" "reg" $encoder_reg int
    hsi::utils::add_new_dts_param "${encoder_node}" "interrupts" $intr_val int
    hsi::utils::add_new_dts_param "${encoder_node}" "interrupt-parent" $intr_parent reference
    # Fenerate child decoder
    set decoder_node [add_or_get_dt_node -l "decoder" -n "al5d@a0020000" -p $node]
    set decoder_comp "al,al5d-${ver}"
    set decoder_comp [append decoder_comp " al,al5d"]
    hsi::utils::add_new_dts_param "${decoder_node}" "compatible" $decoder_comp stringlist
    set decoder_reg "0x0 0xa0020000 0x0 0x10000"
    hsi::utils::add_new_dts_param "${decoder_node}" "reg" $decoder_reg int
    hsi::utils::add_new_dts_param "${decoder_node}" "interrupts" $intr_val int
    hsi::utils::add_new_dts_param "${decoder_node}" "interrupt-parent" $intr_parent reference
    set proc_type [get_sw_proc_prop IP_NAME]
    if {[string match -nocase $proc_type "psu_cortexa53"]} {
       update_clk_node $drv_handle "pll_ref_clk s_axi_lite_aclk"
    }
    set clknames "pll_ref aclk"
    overwrite_clknames $clknames $drv_handle
}

proc get_ipdetails {drv_handle arg} {
    set slave [get_cells -hier ${drv_handle}]
    set vlnv [split [get_property VLNV $slave] ":"]
    set ver [lindex $vlnv 3]
    set name [lindex $vlnv 2]
    set ver [lindex $vlnv 3]
    set comp_prop "xlnx,${name}-${ver}"
    regsub -all {_} $comp_prop {-} comp_prop
    if {[string match -nocase $arg "ver"]} {
        return $ver
    } else {
        return $comp_prop
    }
}
