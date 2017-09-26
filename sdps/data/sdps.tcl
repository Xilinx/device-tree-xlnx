#
# (C) Copyright 2014-2015 Xilinx, Inc.
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
    set ip [get_cells -hier $drv_handle]
    set clk_freq [hsi::utils::get_ip_param_value $ip C_SDIO_CLK_FREQ_HZ]
    set_property CONFIG.clock-frequency "$clk_freq" $drv_handle
    set_drv_conf_prop $drv_handle C_MIO_BANK xlnx,mio_bank hexint
}


