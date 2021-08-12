#
# (C) Copyright 2018 Xilinx, Inc.
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

	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,axi-frmbuf-rd-v2.1"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set ip [get_cells -hier $drv_handle]
	set_drv_conf_prop $drv_handle C_S_AXI_CTRL_ADDR_WIDTH xlnx,s-axi-ctrl-addr-width
	set_drv_conf_prop $drv_handle C_S_AXI_CTRL_DATA_WIDTH xlnx,s-axi-ctrl-data-width
	set vid_formats ""
	set has_bgr8 [get_property CONFIG.HAS_BGR8 [get_cells -hier $drv_handle]]
	if {$has_bgr8 == 1} {
		append vid_formats " " "rgb888"
	}
	set has_rgbx8 [get_property CONFIG.HAS_RGBX8 [get_cells -hier $drv_handle]]
	if {$has_rgbx8 == 1} {
		append vid_formats " " "xbgr8888"
	}
	set has_bgra8 [get_property CONFIG.HAS_BGRA8 [get_cells -hier $drv_handle]]
	if {$has_bgra8 == 1} {
		append vid_formats " " "argb8888"
	}
	set has_bgrx8 [get_property CONFIG.HAS_BGRX8 [get_cells -hier $drv_handle]]
	if {$has_bgrx8 == 1} {
		append vid_formats " " "xrgb8888"
	}
	set has_rgb8 [get_property CONFIG.HAS_RGB8 [get_cells -hier $drv_handle]]
	if {$has_rgb8 == 1} {
		append vid_formats " " "bgr888"
	}
	set has_rgba8 [get_property CONFIG.HAS_RGBA8 [get_cells -hier $drv_handle]]
	if {$has_rgba8 == 1} {
		append vid_formats " " "abgr8888"
	}
	set has_bgrx10 [get_property CONFIG.HAS_RGBX10 [get_cells -hier $drv_handle]]
	if {$has_bgrx10 == 1} {
		append vid_formats " " "xbgr2101010"
	}
	set has_uyvy8 [get_property CONFIG.HAS_UYVY8 [get_cells -hier $drv_handle]]
	if {$has_uyvy8 == 1} {
		append vid_formats " " "uyvy"
	}
	set has_y8 [get_property CONFIG.HAS_Y8 [get_cells -hier $drv_handle]]
	if {$has_y8 == 1} {
		append vid_formats " " "y8"
	}
	set has_y10 [get_property CONFIG.HAS_Y10 [get_cells -hier $drv_handle]]
	if {$has_y10 == 1} {
		append vid_formats " " "y10"
	}
	set has_yuv8 [get_property CONFIG.HAS_YUV8 [get_cells -hier $drv_handle]]
	if {$has_yuv8 == 1} {
		append vid_formats " " "vuy888"
	}
	set has_yuvx8 [get_property CONFIG.HAS_YUVX8 [get_cells -hier $drv_handle]]
	if {$has_yuvx8 == 1} {
		append vid_formats " " "xvuy8888"
	}
	set has_yuvx10 [get_property CONFIG.HAS_YUVX10 [get_cells -hier $drv_handle]]
	if {$has_yuvx10 == 1} {
		append vid_formats " " "yuvx2101010"
	}
	set has_yuyv8 [get_property CONFIG.HAS_YUYV8 [get_cells -hier $drv_handle]]
	if {$has_yuyv8 == 1} {
		append vid_formats " " "yuyv"
	}
	set has_y_uv8_420 [get_property CONFIG.HAS_Y_UV8_420 [get_cells -hier $drv_handle]]
	if {$has_y_uv8_420 == 1} {
		append vid_formats " " "nv12"
	}
	set has_y_uv8 [get_property CONFIG.HAS_Y_UV8 [get_cells -hier $drv_handle]]
	if {$has_y_uv8 == 1} {
		append vid_formats " " "nv16"
	}
	set has_y_uv10 [get_property CONFIG.HAS_Y_UV10 [get_cells -hier $drv_handle]]
	if {$has_y_uv10 == 1} {
		append vid_formats " " "xv20"
	}
	set has_y_uv10_420 [get_property CONFIG.HAS_Y_UV10_420 [get_cells -hier $drv_handle]]
	if {$has_y_uv10_420 == 1} {
		append vid_formats " " "xv15"
	}
	if {![string match $vid_formats ""]} {
		hsi::utils::add_new_dts_param "${node}" "xlnx,vid-formats" $vid_formats stringlist
	}
	set samples_per_clk [get_property CONFIG.SAMPLES_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,pixels-per-clock" $samples_per_clk int
	set dma_align [expr $samples_per_clk * 8]
	hsi::utils::add_new_dts_param "$node" "xlnx,dma-align" $dma_align int
	set has_interlaced [get_property CONFIG.HAS_INTERLACED [get_cells -hier $drv_handle]]
	if {$has_interlaced == 1} {
		hsi::utils::add_new_dts_param "$node" "xlnx,fid" "" boolean
	}
	set dma_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dma-addr-width" $dma_addr_width int
	hsi::utils::add_new_dts_param "$node" "#dma-cells" 1 int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,video-width" $max_data_width int
	set max_rows [get_property CONFIG.MAX_ROWS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-height" $max_rows int
	set max_cols [get_property CONFIG.MAX_COLS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,max-width" $max_cols int
	gen_gpio_reset $drv_handle $node
}

proc gen_gpio_reset {drv_handle node} {
	set pins [::hsi::utils::get_source_pins [get_pins -of_objects [get_cells -hier [get_cells -hier $drv_handle]] "ap_rst_n"]]
	foreach pin $pins {
		set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "xlslice"]} {
				set gpio [get_property CONFIG.DIN_FROM $sink_periph]
				set pins [get_pins -of_objects [get_nets -of_objects [get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [::hsi::get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [get_property IP_NAME $periph]
						set proc_type [get_sw_proc_prop IP_NAME]
						if {[string match -nocase $proc_type "psv_cortexa72"] } {
							if {[string match -nocase $ip "versal_cips"]} {
								# As versal has only bank0 for MIOs
								set gpio [expr $gpio + 26]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio0 $gpio 1" reference
								break
							}
						}
						if {[string match -nocase $proc_type "psu_cortexa53"] } {
							if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
								set gpio [expr $gpio + 78]
								hsi::utils::add_new_dts_param "$node" "reset-gpios" "gpio $gpio 1" reference
								break
							}
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 0 1" reference
						}
					} else {
						dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
}
