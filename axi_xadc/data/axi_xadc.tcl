#
# (C) Copyright 2015 Xilinx, Inc.
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
	# try to source the common tcl procs
	# assuming the order of return is based on repo priority
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	gen_xadc_driver_prop $drv_handle
}

proc gen_xadc_driver_prop {drv_handle} {
	gen_drv_prop_from_ip $drv_handle
	gen_dev_ccf_binding $drv_handle "s_axi_aclk"

	hsi::utils::add_new_property $drv_handle "compatible" stringlist "xlnx,axi-xadc-1.00.a"
	set adc_ip [get_cells -hier $drv_handle]
	set has_dma [get_property CONFIG.C_HAS_EXTERNAL_MUX $adc_ip]
	if {$has_dma == 0} {
		set has_dma_str "none"
	} elseif {$has_dma == 1} {
		set has_dma_str "single"
	}

	hsi::utils::add_new_property $drv_handle "xlnx,external-mux" string $has_dma_str
	if {$has_dma != 0} {
		set ext_mux_chan [get_property CONFIG.EXTERNAL_MUX_CHANNEL $adc_ip]
		if {[string match -nocase $ext_mux_chan "VP_VN"] } {
			set chan_nr 0
		} else {
			for {set i 0} { $i < 16 } { incr i} {
				if {[string match -nocase $ext_mux_chan "VAUXP${i}_VAUXN${i}"]} {
					set chan_nr [expr $i + 1]
				}
			}
		}
		hsi::utils::add_new_property $drv_handle "xlnx,external-mux-channel" int $chan_nr
	}
}
