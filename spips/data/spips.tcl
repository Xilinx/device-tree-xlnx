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
	set ip [get_cells -hier $drv_handle]
	set cs-num 0
	# SPI PS only have chip select range 0 - 2
	foreach n {0 1 2} {
		set cs_en [get_property CONFIG.C_HAS_SS${n} $ip]
		if {[string equal "1" $cs_en]} {
			inc cs-num
		}
	}
	if {${cs-num} != 0} {
		set_property CONFIG.num-cs ${cs-num} $drv_handle
	}

	# the is-decoded-cs property is hard coded as we do not know if the
	# board has external decoder connected or not
	# Once we had the board level information, is-decoded-cs need to be
	# generated based on it.
}
