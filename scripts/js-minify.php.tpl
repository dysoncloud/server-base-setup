<?php
/*
Plugin Name: JS Minifier and Cache
Description: Minifies enqueued JavaScript files (ignores .min.js files), stores them locally, and serves the minified version if it already exists.
Version: 1.0
*/

// Minify and cache JS
add_action('wp_enqueue_scripts', 'custom_minify_and_cache_js', 20);
function custom_minify_and_cache_js() {
    $scripts = wp_scripts();

    foreach ($scripts->queue as $handle) {
        $src = $scripts->registered[$handle]->src;

        // Skip external JS files
        if (strpos($src, home_url()) !== 0) {
            continue;
        }

        // Skip already minified JS files
        if (strpos($src, '.min.js') !== false) {
            continue;
        }

        // Convert URL to file path
        $relative_path = wp_make_link_relative($src);
        $js_file_path = wp_normalize_path(ABSPATH . ltrim($relative_path, '/'));

        if (file_exists($js_file_path)) {
            // Generate the path for the minified version
            $minified_js_path = custom_get_minified_js_path($js_file_path);

            // If minified file doesn't exist, create it
            if (!file_exists($minified_js_path)) {
                $js_content = file_get_contents($js_file_path);
                $minified_content = custom_minify_js_content($js_content);
                file_put_contents($minified_js_path, $minified_content);
            }

            // Use the minified JS file
            $minified_js_url = content_url('uploads/cp-minify/js/' . basename($minified_js_path));
            
            // Replace the original JS with the minified version
            wp_deregister_script($handle);
            wp_register_script($handle, $minified_js_url, [], filemtime($minified_js_path), true);
            wp_enqueue_script($handle);
        }
    }
}

// Get the path for the minified JS file
function custom_get_minified_js_path($js_file_path) {
    $upload_dir = wp_upload_dir();
    return wp_normalize_path($upload_dir['basedir'] . '/cp-minify/js/' . basename($js_file_path, '.js') . '.min.js');
}

// Minify JS content
function custom_minify_js_content($js_content) {
    // Minification logic: remove comments and whitespace
    $js_content = preg_replace('/\/\/.*?$|\/\*.*?\*\/|(?<!\S)\/\/.*?\n/s', '', $js_content); // Remove comments
    $js_content = preg_replace('/\s+/', ' ', $js_content); // Remove excess whitespace
    $js_content = str_replace([' ;', ' ,', ' {', '} '], [';', ',', '{', '}'], $js_content); // Optimize spaces
    return trim($js_content);
}