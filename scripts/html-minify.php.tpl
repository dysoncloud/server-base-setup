<?php
/*
Plugin Name: HTML Minify
Description: Minify HTML responses before they are sent to the browser.
*/

// Hook into WordPress to minify HTML output
add_action('template_redirect', 'html_minify_output');

function html_minify_output() {
    // Start output buffering
    ob_start('minify_html');

    // Hook into 'shutdown' action to send the minified output to the browser
    add_action('shutdown', function() {
        ob_end_flush();
    }, 0);
}

function minify_html($buffer) {
    // Remove HTML comments
    $buffer = preg_replace('/<!--[\s\S]*?-->/', '', $buffer);

    // Minify HTML output
    $search = [
        '/\>[^\S ]+/s',  // Strip whitespaces after tags, except space
        '/[^\S ]+\</s',  // Strip whitespaces before tags, except space
        '/(\s)+/s'       // Shorten multiple whitespace sequences
    ];

    $replace = [
        '>',
        '<',
        '\\1'
    ];

    $buffer = preg_replace($search, $replace, $buffer);

    return $buffer;
}
