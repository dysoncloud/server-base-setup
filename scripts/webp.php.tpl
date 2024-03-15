<?php
/**
 * Plugin Name: Convert Thumbnails to WebP
 * Description: Automatically converts thumbnails of uploaded images into WebP format.
 */

add_action('delete_attachment', 'delete_webp_files_on_delete');
function delete_webp_files_on_delete($attachment_id)
{
    // If the file is not an image or not JPEG/PNG, return
    if (!wp_attachment_is_image($attachment_id)) {
        return;
    }

    $file = get_attached_file($attachment_id);

    // Ensure that the file is within the uploads directory
    $uploads_dir = wp_get_upload_dir()['basedir'];
    if (strpos($file, $uploads_dir) !== 0) {
        return;
    }

    // Get thumbnail sizes
    $thumbnail_sizes = array_merge(array('full'), get_intermediate_image_sizes());

    // Loop through each thumbnail size and convert it to WebP
    foreach ($thumbnail_sizes as $size) {
        // Get attachment file path for the specific size
        $attachment_file = wp_get_attachment_image_src($attachment_id, $size);

        if (!$attachment_file) {
            continue; // Skip if thumbnail file doesn't exist
        }

        $thumbnail_file = $attachment_file[0];

        // Convert to local file path
        $local_file_path = str_replace(site_url('/'), ABSPATH, $thumbnail_file) . '.webp';

        if (file_exists($local_file_path)) {
            unlink($local_file_path);
        }
    }
}

add_action('wp_generate_attachment_metadata', 'convert_thumbnails_to_webp', 10, 2);
function convert_thumbnails_to_webp($metadata, $attachment_id)
{
    $quality = ${QUALITY};
    $keep_metadata = ${METADATA};

    // If the file is not an image or not JPEG/PNG, return
    if (!wp_attachment_is_image($attachment_id)) {
        return;
    }

    $file = get_attached_file($attachment_id);

    // Get the file extension
    $extension = pathinfo($file, PATHINFO_EXTENSION);

    // Check if the file is JPEG or PNG
    if (!in_array(strtolower($extension), ['jpg', 'jpeg', 'png'])) {
        return;
    }

    // Ensure that the file is within the uploads directory
    $uploads_dir = wp_get_upload_dir()['basedir'];
    if (strpos($file, $uploads_dir) !== 0) {
        return;
    }

    // Check if Imagick extension is available
    if (!extension_loaded('imagick')) {
        return;
    }

    // Create Imagick object
    $imagick_thumbnail = new Imagick();

    // Get thumbnail sizes
    $thumbnail_sizes = array_merge(array('full'), get_intermediate_image_sizes());

    // Loop through each thumbnail size and convert it to WebP
    foreach ($thumbnail_sizes as $size) {
        // Get attachment file path for the specific size
        $attachment_file = wp_get_attachment_image_src($attachment_id, $size);

        // Check if the thumbnail file exists with exponential backoff
        $retry_count = 0;
        $max_retries = 3; // Maximum number of retries
        while (!$attachment_file && $retry_count < $max_retries) {
            $delay = pow(2, $retry_count); // Exponential backoff with power of 2
            sleep($delay); // Wait for the calculated delay before retrying
            $attachment_file = wp_get_attachment_image_src($attachment_id, $size);
            $retry_count++;
        }

        if (!$attachment_file) {
            continue; // Skip if thumbnail file doesn't exist after retries
        }

        $thumbnail_file = $attachment_file[0];

        // Check if the file is JPEG or PNG
        $thumbnail_extension = pathinfo($thumbnail_file, PATHINFO_EXTENSION);
        if (!in_array(strtolower($thumbnail_extension), ['jpg', 'jpeg', 'png'])) {
            continue;
        }

        // Convert to local file path
        $local_file_path = str_replace(site_url('/'), ABSPATH, $thumbnail_file);

        // Open the thumbnail file with Imagick
        $imagick_thumbnail->readImage($local_file_path);

        // Set format to WebP
        $imagick_thumbnail->setImageFormat('webp');
        $imagick_thumbnail->setImageCompressionQuality($quality);

        // Strip metadata retaining color profile
        if (!$keep_metadata) {
            $profiles = $imagick_thumbnail->getImageProfiles("icc", true);
            $imagick_thumbnail->stripImage();

            if (!empty($profiles)) {
                $imagick_thumbnail->profileImage("icc", $profiles['icc']);
            }
        }

        // Save the thumbnail as WebP
        $imagick_thumbnail->writeImage($local_file_path . '.webp');

        // Clear Imagick resources
        $imagick_thumbnail->clear();
    }

    // Destroy Imagick resources
    $imagick_thumbnail->destroy();

    return $metadata;
}