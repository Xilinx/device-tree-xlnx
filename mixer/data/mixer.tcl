#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022 Advanced Micro Devices, Inc. All Rights Reserved.
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
	set compatible [append compatible " " "xlnx,mixer-3.0 xlnx,mixer-4.0 xlnx,mixer-5.0"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set mixer_ip [get_cells -hier $drv_handle]
	set num_layers [get_property CONFIG.NR_LAYERS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,num-layers" $num_layers int
	set samples_per_clock [get_property CONFIG.SAMPLES_PER_CLOCK [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,ppc" $samples_per_clock int
	set dma_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dma-addr-width" $dma_addr_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "${node}" "xlnx,bpc" $max_data_width int
	set logo_layer [get_property CONFIG.LOGO_LAYER [get_cells -hier $drv_handle]]
	if {[string match -nocase $logo_layer "true"]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,logo-layer" ""  boolean
	}
	set enable_csc_coefficient_registers [get_property CONFIG.ENABLE_CSC_COEFFICIENT_REGISTERS [get_cells -hier $drv_handle]]
	if {$enable_csc_coefficient_registers == 1} {
		hsi::utils::add_new_dts_param "$node" "xlnx,enable-csc-coefficient-register" "" boolean
	}
	set mixer_port_node [add_or_get_dt_node -n "port" -l crtc_mixer_port$drv_handle -u 0 -p $node]
	hsi::utils::add_new_dts_param "$mixer_port_node" "reg" 0 int
	set mix_outip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "m_axis_video"]
	if {![llength $mix_outip]} {
		dtg_warning "$drv_handle pin m_axis_video is not connected ...check your design"
	}
	set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $mix_outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	foreach outip $mix_outip {
		if {[llength $outip] != 0} {
			set ip_mem_handles [hsi::utils::get_ip_mem_ranges $outip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
				set mixer_crtc [add_or_get_dt_node -n "endpoint" -l mixer_crtc$drv_handle -p $mixer_port_node]
				gen_endpoint $drv_handle "mixer_crtc$drv_handle"
				hsi::utils::add_new_dts_param "$mixer_crtc" "remote-endpoint" $outip$drv_handle reference
				gen_remoteendpoint $drv_handle "$outip$drv_handle"
			} else {
				if {[string match -nocase [get_property IP_NAME $outip] "system_ila"]} {
					continue
				}
				set connectip [get_connect_ip $outip $master_intf]
				if {[llength $connectip]} {
					set mixer_crtc [add_or_get_dt_node -n "endpoint" -l mixer_crtc$drv_handle -p $mixer_port_node]
					gen_endpoint $drv_handle "mixer_crtc$drv_handle"
					hsi::utils::add_new_dts_param "$mixer_crtc" "remote-endpoint" $connectip$drv_handle reference
					gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                }
			}
		} else {
			dtg_warning "$drv_handle pin m_axis_video is not connected ...check your design"
		}
	}
	for {set layer 0} {$layer < $num_layers} {incr layer} {
		switch $layer {
			"0" {
				set mixer_node0 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_master$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-id" $layer int
				set maxwidth [get_property CONFIG.MAX_COLS [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-max-width" $maxwidth int
				set maxheight [get_property CONFIG.MAX_ROWS [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-max-height" $maxheight int
				hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-primary" "" boolean
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip] != 0} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node0 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node0 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-streaming" "" boolean
							set layer0_video_format [get_property CONFIG.VIDEO_FORMAT [get_cells -hier $drv_handle]]
							gen_video_format $layer0_video_format $mixer_node0 $drv_handle $max_data_width
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node0 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node0 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-streaming" "" boolean
							set layer0_video_format [get_property CONFIG.VIDEO_FORMAT [get_cells -hier $drv_handle]]
							gen_video_format $layer0_video_format $mixer_node0 $drv_handle $max_data_width
						}
					}
				}
			}
			"1" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer1_alpha [get_property CONFIG.LAYER1_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer1_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer1_maxwidth [get_property CONFIG.LAYER1_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer1_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video1"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER1_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer1_video_format [get_property CONFIG.LAYER1_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer1_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"2" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer2_alpha [get_property CONFIG.LAYER2_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer2_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer2_maxwidth [get_property CONFIG.LAYER2_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer2_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video2"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER2_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer2_video_format [get_property CONFIG.LAYER2_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer2_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"3" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer3_alpha [get_property CONFIG.LAYER3_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer3_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer3_maxwidth [get_property CONFIG.LAYER3_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer3_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video3"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER3_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer3_video_format [get_property CONFIG.LAYER3_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer3_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"4" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer4_alpha [get_property CONFIG.LAYER4_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer4_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer4_maxwidth [get_property CONFIG.LAYER4_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer4_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video4"]
				puts "connect_ip:$connect_ip"
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						puts "ip_mem_handles:$ip_mem_handles"
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER4_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer4_video_format [get_property CONFIG.LAYER4_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer4_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"5" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer5_alpha [get_property CONFIG.LAYER5_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer5_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer5_maxwidth [get_property CONFIG.LAYER5_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer5_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video5"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node0 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node0 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-streaming" "" boolean
							set layer0_video_format [get_property CONFIG.VIDEO_FORMAT [get_cells -hier $drv_handle]]
							gen_video_format $layer0_video_format $mixer_node0 $drv_handle $max_data_width
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER5_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer5_video_format [get_property CONFIG.LAYER5_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer5_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"6" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer6_alpha [get_property CONFIG.LAYER6_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer6_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer6_maxwidth [get_property CONFIG.LAYER6_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer6_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video6"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set ip_mem_handles [hsi::utils::get_ip_mem_ranges $connected_ip]
						if {[llength $ip_mem_handles]} {
							hsi::utils::add_new_dts_param $mixer_node0 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node0 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node0" "xlnx,layer-streaming" "" boolean
							set layer0_video_format [get_property CONFIG.VIDEO_FORMAT [get_cells -hier $drv_handle]]
							gen_video_format $layer0_video_format $mixer_node0 $drv_handle $max_data_width
						} else {
							set master_intf [::hsi::get_intf_pins -of_objects [get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
							set inip [get_in_connect_ip $connected_ip $master_intf]
							if {[llength $inip]} {
								hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$inip 0" reference
							}
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER6_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer6_video_format [get_property CONFIG.LAYER6_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer6_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"7" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer7_alpha [get_property CONFIG.LAYER7_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer7_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer7_maxwidth [get_property CONFIG.LAYER7_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer7_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video7"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER7_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer7_video_format [get_property CONFIG.LAYER7_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer7_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"8" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer8_alpha [get_property CONFIG.LAYER8_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer8_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer8_maxwidth [get_property CONFIG.LAYER8_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer8_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video8"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER8_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer8_video_format [get_property CONFIG.LAYER8_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer8_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"9" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer9_alpha [get_property CONFIG.LAYER9_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer9_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer9_maxwidth [get_property CONFIG.LAYER9_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer9_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video9"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER9_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer9_video_format [get_property CONFIG.LAYER9_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer9_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"10" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer10_alpha [get_property CONFIG.LAYER10_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer10_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer10_maxwidth [get_property CONFIG.LAYER10_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer10_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video10"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER10_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer10_video_format [get_property CONFIG.LAYER10_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer10_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"11" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer11_alpha [get_property CONFIG.LAYER11_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer11_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer11_maxwidth [get_property CONFIG.LAYER11_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer11_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video11"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER11_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer11_video_format [get_property CONFIG.LAYER11_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer11_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"12" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer12_alpha [get_property CONFIG.LAYER12_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer12_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer12_maxwidth [get_property CONFIG.LAYER12_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer12_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video12"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER12_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer12_video_format [get_property CONFIG.LAYER12_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer12_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"13" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer13_alpha [get_property CONFIG.LAYER13_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer13_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer13_maxwidth [get_property CONFIG.LAYER13_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer13_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video13"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER13_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer13_video_format [get_property CONFIG.LAYER13_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer13_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"14" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer14_alpha [get_property CONFIG.LAYER14_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer14_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer14_maxwidth [get_property CONFIG.LAYER14_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer14_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video14"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER14_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer14_video_format [get_property CONFIG.LAYER14_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer14_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"15" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer15_alpha [get_property CONFIG.LAYER15_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer15_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer15_maxwidth [get_property CONFIG.LAYER15_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer15_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video15"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "v_frmbuf_rd"]} {
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
						}
					}
				}
				set sample [get_property CONFIG.LAYER15_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer15_video_format [get_property CONFIG.LAYER15_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer15_video_format $mixer_node1 $drv_handle $max_data_width
			}
			"16" {
				set mixer_node1 [add_or_get_dt_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
				set layer16_alpha [get_property CONFIG.LAYER16_ALPHA [get_cells -hier $drv_handle]]
				if {[string match -nocase $layer16_alpha "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-alpha" "" boolean
				}
				set layer16_maxwidth [get_property CONFIG.LAYER16_MAX_WIDTH [get_cells -hier $drv_handle]]
				hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-max-width" $layer16_maxwidth int
				set connect_ip [get_connected_stream_ip [get_cells -hier $drv_handle] "s_axis_video16"]
				foreach connected_ip $connect_ip {
					if {[llength $connected_ip]} {
						set connected_ip_type [get_property IP_NAME $connected_ip]
						if {[string match -nocase $connected_ip_type "system_ila"]} {
							continue
						}
							hsi::utils::add_new_dts_param $mixer_node1 "dmas" "$connected_ip 0" reference
							hsi::utils::add_new_dts_param $mixer_node1 "dma-names" "dma0" string
							hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-streaming" "" boolean
					}
				}
				set sample [get_property CONFIG.LAYER16_UPSAMPLE [get_cells -hier $drv_handle]]
				if {[string match -nocase $sample "true"]} {
					hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-scale" "" boolean
				}
				set layer16_video_format [get_property CONFIG.LAYER16_VIDEO_FORMAT [get_cells -hier $drv_handle]]
				gen_video_format $layer16_video_format $mixer_node1 $drv_handle $max_data_width
			}
			default {
			}
		}
	}
	set mixer_node1 [add_or_get_dt_node -n "logo" -l xx_mix_logo$drv_handle -p $node]
	hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,layer-id" $layer int
	set logo_width [get_property CONFIG.MAX_LOGO_COLS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,logo-width" $logo_width int
	set logo_height [get_property CONFIG.MAX_LOGO_ROWS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$mixer_node1" "xlnx,logo-height" $logo_height int
	gen_gpio_reset $drv_handle $node
}

proc gen_video_format {num node drv_handle max_data_width} {
	set vid_formats ""
	switch $num {
		"0" {
			append vid_formats " " "BG24"
		}
		"1" {
			append vid_formats " " "YUYV"
		}
		"2" {
			if {$max_data_width == 10} {
				append vid_formats " " "XV20"
			} else {
				append vid_formats " " "NV16"
			}
		}
		"3" {
			if {$max_data_width == 10} {
				append vid_formats " " "XV15"
			} else {
				append vid_formats " " "NV12"
			}
		}
		"5" {
			append vid_formats " " "AB24"
		}
		"6" {
			append vid_formats " " "AVUY"
		}
		"10" {
			append vid_formats " " "XB24"
		}
		"11" {
			append vid_formats " " "XV24"
		}
		"12" {
			append vid_formats " " "YUYV"
		}
		"13" {
			append vid_formats " " "AB24"
		}
		"14" {
			append vid_formats " " "AVUY"
		}
		"15" {
			append vid_formats " " "XB30"
		}
		"16" {
			append vid_formats " " "XV30"
		}
		"17" {
			append vid_formats " " "BG16"
		}
		"18" {
			append vid_formats " " "NV16"
		}
		"19" {
			append vid_formats " " "NV12"
		}
		"20" {
			append vid_formats " " "BG24"
		}
		"21" {
			append vid_formats " " "VU24"
		}
		"22" {
			append vid_formats " " "XV20"
		}
		"23" {
			append vid_formats " " "XV15"
		}
		"24" {
			append vid_formats " " "GREY"
		}
		"25" {
			append vid_formats " " "Y10 "
		}
		"26" {
			append vid_formats " " "AR24"
		}
		"27" {
			append vid_formats " " "XR24"
		}
		"28" {
			append vid_formats " " "UYVY"
		}
		"29" {
			append vid_formats " " "RG24"
		}
		default {
			dtg_warning "Not supported format:$num"
		}
	}
	if {![string match -nocase $vid_formats ""]} {
		hsi::utils::add_new_dts_param "$node" "xlnx,vformat" $vid_formats stringlist
	}
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
								# As versal has only one bank0 for MIOs
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
							hsi::utils::add_new_dts_param "$node" "reset-gpios" "$periph $gpio 1" reference
						}
					} else {
						dtg_warning "$drv_handle:peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
		}
	}
}
