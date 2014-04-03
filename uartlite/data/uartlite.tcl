proc generate {drv_handle} {
    set ip [get_cells $drv_handle]
    set ip_type [get_property IP_NAME $ip]
    if { [string compare -nocase $ip_type mdm] == 0 } {
    }
}
