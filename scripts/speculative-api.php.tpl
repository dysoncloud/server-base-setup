<?php
/**
 * Plugin Name: Speculative API
 * Description: Injects JavaScript to prefetch/prerender API requests, excluding menu items and unnecessary links.
 * Version: 1.0
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

function speculative_api() {
    // Don't push the script if the user is logged in and an admin
    if (is_user_logged_in() && current_user_can('manage_options')) {
        return;
    }

    // Define default values if constants are not set
    $mode = defined('CP_SPECULATIVE_API_MODE') ? CP_SPECULATIVE_API_MODE : 'prefetch';
    $eagerness = defined('CP_SPECULATIVE_API_EAGERNESS') ? CP_SPECULATIVE_API_EAGERNESS : 'moderate';

    ?>
    <script type="speculationrules">
        {
            "<?php echo esc_js($mode); ?>": [
                {
                    "source": "document",
                    "eagerness": "<?php echo esc_js($eagerness); ?>",
                    "where": {
                        "and": [
                            {"href_matches": "\/*"},
                            {"not": {"href_matches": [
                                "\/cart\/*", "\/checkout\/*", "\/my-account\/*", "\/logout\/*", 
                                "\/wp-*.php", "\/wp-admin\/*", "\/wp-content\/uploads\/*", 
                                "\/wp-content\/*", "\/wp-content\/plugins\/*", "\/wp-content\/themes\/*", 
                                "\/*\\?(.+)"
                            ]}},
                            {"not": {"selector_matches": ".no-prerender, .no-prefetch"}},
                            {"not": {"selector_matches": "a[rel~='nofollow']"}}
                        ]
                    }
                }
            ]
        }
    </script>
    <?php
}

add_action('wp_footer', 'speculative_api');
