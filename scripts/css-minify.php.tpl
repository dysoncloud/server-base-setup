<?php
/*
Plugin Name: CSS Minifier and Cache
Description: Minifies enqueued CSS files (ignores .min.css files), stores them locally, and serves the minified version if it already exists.
Version: 1.0
*/

// Minify and cache CSS
add_action('wp_enqueue_scripts', 'custom_minify_and_cache_css', 20);
function custom_minify_and_cache_css()
{
    $styles = wp_styles();

    foreach ($styles->queue as $handle) {
        $src = $styles->registered[$handle]->src;

        // Skip external CSS files
        if (strpos($src, home_url()) !== 0) {
            continue;
        }

        // Skip already minified CSS files
        if (strpos($src, '.min.css') !== false) {
            continue;
        }

        // Convert URL to file path
        $relative_path = wp_make_link_relative($src);
        $css_file_path = wp_normalize_path(ABSPATH . ltrim($relative_path, '/'));

        if (file_exists($css_file_path)) {
            // Generate the path for the minified version
            $minified_css_path = custom_get_minified_path($css_file_path);

            // If minified file doesn't exist, create it
            if (!file_exists($minified_css_path)) {
                $css_content = file_get_contents($css_file_path);
                $minified_content = custom_minify_css_content($css_content);
                file_put_contents($minified_css_path, $minified_content);
            }

            // Use the minified CSS file
            $minified_css_url = content_url('uploads/cp-minify/css/' . basename($minified_css_path));

            // Replace the original CSS with the minified version
            wp_deregister_style($handle);
            wp_register_style($handle, $minified_css_url, [], filemtime($minified_css_path));
            wp_enqueue_style($handle);
        }
    }
}

// Get the path for the minified CSS file
function custom_get_minified_path($css_file_path)
{
    $upload_dir = wp_upload_dir();
    return wp_normalize_path($upload_dir['basedir'] . '/cp-minify/css/' . basename($css_file_path, '.css') . '.min.css');
}

// Minify CSS content
function custom_minify_css_content($css_content)
{
    // Minification logic: remove comments and whitespace
    $css_content = preg_replace('!/\*.*?\*/!s', '', $css_content); // Remove comments
    $css_content = preg_replace('/\s+/', ' ', $css_content); // Remove excess whitespace
    $css_content = str_replace([' :', ' {', '; ', ', ', '} '], [':', '{', ';', ',', '}'], $css_content); // Optimize spaces
    return trim($css_content);
}