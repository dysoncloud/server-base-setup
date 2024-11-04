<?php
/*
Plugin Name: Custom Post Update API Trigger
Description: Triggers an API call when a post is updated.
Version: 1.0
*/

// Hook into post update
add_action('save_post', 'custom_post_update_edge_cache_api_trigger', 20, 3);

function custom_post_update_edge_cache_api_trigger($post_ID, $post, $update) {
    // Check if this is a revision or autosave
    if ( !$update || wp_is_post_revision( $post_ID ) || wp_is_post_autosave( $post_ID ) ) {
        return;
    }

    // Check if the post status is 'publish'
    if ($post->post_status !== 'publish') {
        return;
    }

    // Get the post URL
    $post_url = get_permalink($post_ID);

    // API endpoint to trigger
    $api_url = 'https://' . CP_API_URL . '/v1/application/' . CP_APPLICATION_ID . '/optimization/cache/purge';

    // Data to be sent in the request body
    $body = array(
        'post_urls' => [$post_url],
        'type' => 'EDGE_CACHE',
        'domain_id' => CP_CF_DOMAIN_ID
    );

    // Additional headers
    $headers = array(
        'x-api-key' => CP_APPLICATION_IDENTIFIER
    );

    wp_remote_post($api_url, array(
        'body'    => $body,
        'headers' => $headers,
    ));
}
?>
