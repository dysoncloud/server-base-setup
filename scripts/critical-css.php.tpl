<?php
/*
Plugin Name: Defer Stylesheets
Description: Defer loading of original stylesheets to improve performance.
Version: 1.0
*/

function defer_stylesheets($html, $handle, $href, $media) {
    // Only apply to non-admin pages
    if (is_admin()) {
        return $html;
    }

    // Replace rel="stylesheet" with rel="preload" and add onload attribute
    $deferred_html = <<<HTML
<link rel="preload" href="$href" type="text/css" as="style" onload="this.onload=null;this.rel='stylesheet';">
HTML;

    return $deferred_html;
}

add_filter('style_loader_tag', 'defer_stylesheets', 10, 4);

function insert_critical_css_at_top() {
    global $wp_filesystem;

    // Cache key
    $cache_key = CP_CRITICAL_CSS_CACHE_KEY;

    // Try to fetch Critical CSS from Object Cache (Redis)
    $critical_css = wp_cache_get($cache_key);

    if ($critical_css === false) {
        // Path to Critical CSS file
        $css_file_path = WP_CONTENT_DIR . '/cp-critical-css.css';

        // Check if the file exists and read it
        if (file_exists($css_file_path)) {
            if (!isset($wp_filesystem)) {
                require_once ABSPATH . 'wp-admin/includes/file.php';
                WP_Filesystem();
            }
            $critical_css = $wp_filesystem->get_contents($css_file_path);

            // Store in Object Cache (Redis)
            if ($critical_css) {
                wp_cache_set($cache_key, $critical_css);
            }
        }
    }

    // Inject the CSS at the top of <head>
    if (!empty($critical_css)) {
        echo "<style id='critical-css'>{$critical_css}</style>\n";
    }
}

add_action('wp_head', 'insert_critical_css_at_top', -9999);
