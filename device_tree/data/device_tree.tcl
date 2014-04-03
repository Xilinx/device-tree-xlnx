
# For calling from top level BSP
proc bsp_drc {os_handle} {
}

# If standalone purpose
proc device_tree_drc {os_handle} {
	bsp_drc $os_handle
    hsm::utils::add_new_child_node $os_handle "chosen"
    hsm::utils::add_new_child_node $os_handle "system"
    hsm::utils::add_new_child_node $os_handle "global_params"
}

proc generate {lib_handle} {
}

proc post_generate {os_handle} {
    set node [get_child_nodes -of_objects [get_os] "global_params"]
    if { [llength $node] } {
        delete_objs $node
    }
}
