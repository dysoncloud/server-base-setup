<?php
/*
Plugin Name: Async All JavaScript Loading
Description: Adds the 'async' attribute to all enqueued JavaScript files unless it is already present, to improve page load performance.
Version: 1.0
*/

// Add 'async' attribute to all enqueued scripts
add_filter('script_loader_tag', 'add_async_attribute_to_scripts', 10, 2);
function add_async_attribute_to_scripts($tag, $handle) {
    // Skip if 'src' attribute is missing, 'async' is already present, or if the script is admin-related
    if (strpos($tag, 'src=') === false || strpos($tag, 'async') !== false || is_admin()) {
        return $tag;
    }

    // Add 'async' attribute
    $tag = str_replace('<script ', '<script async ', $tag);
    return $tag;
}