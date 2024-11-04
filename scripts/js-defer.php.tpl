<?php
/*
Plugin Name: Defer All JavaScript Loading
Description: Adds the 'defer' attribute to all enqueued JavaScript files unless it is already present, to improve page load performance.
Version: 1.0
*/

// Add 'defer' attribute to all enqueued scripts
add_filter('script_loader_tag', 'add_defer_attribute_to_scripts', 10, 2);
function add_defer_attribute_to_scripts($tag, $handle) {
    // Skip if 'src' attribute is missing, 'defer' is already present, or if the script is admin-related
    if (strpos($tag, 'src=') === false || strpos($tag, 'defer') !== false || is_admin()) {
        return $tag;
    }

    // Add 'defer' attribute
    $tag = str_replace('<script ', '<script defer ', $tag);
    return $tag;
}