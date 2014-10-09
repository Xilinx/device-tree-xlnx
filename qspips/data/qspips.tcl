proc generate {drv_handle} {
    set slave [get_cells $drv_handle]
    set qspi_mode [hsi::utils::get_ip_param_value $slave "C_QSPI_MODE"]
    if { $qspi_mode == 2} {
        set is_dual 1
    } else {
        set is_dual 0
    }
    set_property CONFIG.is-dual $is_dual $drv_handle

    # these are board level information
    # set primary_flash [hsi::utils::add_new_child_node $drv_handle "primary_flash"]
    # hsi::utils::add_new_property $primary_flash "dts.device_type" string "ps7-qspi"
    # hsi::utils::add_new_property $primary_flash reg hexint 0
    # hsi::utils::add_new_property $primary_flash spi-max-frequency int 50000000
}
