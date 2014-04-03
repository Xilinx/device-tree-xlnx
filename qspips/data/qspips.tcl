proc generate {drv_handle} {
    set slave [get_cells $drv_handle]
   	set qspi_mode [get_ip_param_value $slave "C_QSPI_MODE"]
    if { $qspi_mode == 2} {
    	set is_dual 1
    } else {
    	set is_dual 0
    }
    set_property CONFIG.is-dual $is_dual $drv_handle

    set primary_flash [hsm::utils::add_new_child_node $drv_handle "primary_flash"]
    set_property CONFIG.reg 0x0 $primary_flash
    set_property CONFIG.spi-max-frequency 50000000 $primary_flash
}
