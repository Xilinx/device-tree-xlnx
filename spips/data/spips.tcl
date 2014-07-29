proc generate {drv_handle} {
	set ip [get_cells $drv_handle]
	# SPI PS only have chip select range 0 - 2
	foreach n {0 1 2} {
		set cs_en [get_property CONFIG.C_HAS_SS${n} $ip]
		if {[string equal "1" $cs_en]} {
			inc cs-num
		}
	}
	set_property CONFIG.num-cs ${cs-num} $drv_handle

	# the is-decoded-cs property is hard coded as we do not know if the
	# board has external decoder connected or not
	# Once we had the board level information, is-decoded-cs need to be
	# generated based on it.
}
