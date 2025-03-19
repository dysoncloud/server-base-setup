<?php
/*
Plugin Name: Preload LCP Image
Description: Automatically preloads the Largest Contentful Paint (LCP) image to improve performance.
Version: 1.0
*/

// Hook into WordPress to start buffer
add_action('template_redirect', 'preload_lcp_output');

function preload_lcp_output() {
    // Start output buffering
    ob_start('preload_lcp');

    // Hook into 'shutdown' action to send the output to the browser
    add_action('shutdown', function() {
        ob_end_flush();
    }, 0);
}

function preload_lcp($buffer) {
    if (!$buffer) {
        return ''; // Fallback in case buffer is empty
    }

    $lcp_url = '';

    // Determine LCP image URL based on the current context
    if (is_singular('product')) {
        $product = wc_get_product(get_the_ID());

        if ($product) {
            $attachment_id = $product->get_image_id(); // Main product image
            if ($attachment_id) {
                $lcp_url = wp_get_attachment_url($attachment_id);
            }
        }
    } elseif (is_singular()) {
        $post_id = get_the_ID();
        $thumbnail_id = get_post_thumbnail_id($post_id);
        if ($thumbnail_id) {
            $lcp_url = wp_get_attachment_url($thumbnail_id);
        }
    } elseif (is_home() || is_front_page()) {
        $page_for_posts = get_option('page_for_posts');
        if ($page_for_posts) {
            $thumbnail_id = get_post_thumbnail_id($page_for_posts);
            if ($thumbnail_id) {
                $lcp_url = wp_get_attachment_url($thumbnail_id);
            }
        }
    } elseif (is_category() || is_tag() || is_tax()) {
        $term_id = get_queried_object_id();
        $thumbnail_id = get_term_meta($term_id, 'thumbnail_id', true);
        if ($thumbnail_id) {
            $lcp_url = wp_get_attachment_url($thumbnail_id);
        }
    } elseif (is_search()) {
        $search_thumbnail_id = get_option('search_thumbnail_id');
        if ($search_thumbnail_id) {
            $lcp_url = wp_get_attachment_url($search_thumbnail_id);
        }
    } elseif (is_author()) {
        $author_id = get_queried_object_id();
        $thumbnail_id = get_user_meta($author_id, 'author_thumbnail_id', true);
        if ($thumbnail_id) {
            $lcp_url = wp_get_attachment_url($thumbnail_id);
        }
    } elseif (is_date()) {
        $custom_logo_id = get_theme_mod('custom_logo');
        if ($custom_logo_id) {
            $lcp_url = wp_get_attachment_url($custom_logo_id);
        }
    }

    // No LCP image, output buffer and exit
    if (!$lcp_url) {
        return $buffer;
    }

    // Step 1: Extract filename (without extension)
    $image_name = pathinfo($lcp_url, PATHINFO_FILENAME);

    // Step 2: Match in the HTML buffer
    if (preg_match('/<img[^>]+src=["\']([^"\']*' . preg_quote($image_name) . '[^"\']*)["\']/i', $buffer, $matches)) {
        $matched_url = $matches[1];

        // Step 3: Build preload tag
        $preload_tag = '<link rel="preload" as="image" href="' . $matched_url . '" fetchpriority="high" />';

        // Step 4: Inject into <head>
        $buffer = preg_replace('/<\/head>/', $preload_tag . "\n</head>", $buffer, 1);
    }

    // Output final buffer
    return $buffer;
}
