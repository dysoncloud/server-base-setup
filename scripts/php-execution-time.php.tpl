<?php
/*
Plugin Name: PHP Execution Timer
Description: Adds PHP execution time to the response headers for debugging.
*/

if (!defined('ABSPATH')) {
    exit;
}

add_action('shutdown', function () {
    if (!headers_sent()) {
        $php_execution_time = microtime(true) - $_SERVER["REQUEST_TIME_FLOAT"];
        header("x-php-time: {$php_execution_time}");
    }
});
