proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    update_eth_mac_addr $drv_handle
    set node [gen_peripheral_nodes $drv_handle]
    gen_mdio_node $drv_handle $node
}

