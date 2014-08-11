proc generate {drv_handle} {
	set kernel_version [get_property CONFIG.kernel_version [get_os]]
	switch -exact $kernel_version {
		"2014.3" {
			hsm::utils::add_new_property $drv_handle "clock-names" stringlist "can_clk pclk"
		}
	}
}
