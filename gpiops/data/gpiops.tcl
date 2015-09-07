#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
#
# Michal SIMEK <monstr@monstr.eu>
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
     set count 32
     set ip [get_cells -hier $drv_handle]
     set_property CONFIG.emio-gpio-width "[hsi::utils::get_ip_param_value $ip C_EMIO_GPIO_WIDTH]" $drv_handle
     set gpiomask [hsi::utils::get_ip_param_value $ip "C_MIO_GPIO_MASK"]
     set mask [expr {$gpiomask & 0xffffffff}]
     set_property CONFIG.gpio-mask-low "$mask" $drv_handle
     set mask [expr {$gpiomask>>$count}]
     set mask [expr {$mask & 0xffffffff}]
     set_property CONFIG.gpio-mask-high "$mask" $drv_handle
}


