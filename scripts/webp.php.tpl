<?php
/*
Plugin Name: Convert Thumbnails to WebP
Description: Automatically converts thumbnails of uploaded images into WebP format.
Version: 1.1
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
        $local_file_path = str_replace(
            site_url('/wp-content/uploads/'), 
            ABSPATH . 'wp-content/' . CP_WEBP_PATH . '/', 
            $thumbnail_file
        ) . '.webp';

        if (file_exists($local_file_path)) {
            unlink($local_file_path);
        }
    }
}

add_action('wp_generate_attachment_metadata', 'convert_thumbnails_to_webp', 10, 2);
function convert_thumbnails_to_webp($metadata, $attachment_id) {
    $quality = CP_WEBP_QUALITY;
    $keep_metadata = CP_WEBP_METADATA;

    // If the file is not an image, return
    if (!wp_attachment_is_image($attachment_id)) {
        return $metadata;
    }

    $file = get_attached_file($attachment_id);
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));

    // Check if the file is JPEG or PNG
    if (!in_array($extension, ['jpg', 'jpeg', 'png'])) {
        return $metadata;
    }

    // Ensure that the file is within the uploads directory
    $uploads_dir = wp_get_upload_dir()['basedir'];
    if (strpos($file, $uploads_dir) !== 0) {
        return $metadata;
    }

    // Get thumbnail sizes
    $thumbnail_sizes = array_merge(['full'], get_intermediate_image_sizes());
    $image = null;

    // Loop through each thumbnail size and convert it to WebP
    foreach ($thumbnail_sizes as $size) {
        // Get attachment file path for the specific size
        $attachment_file = wp_get_attachment_image_src($attachment_id, $size);

        // Check if the thumbnail file exists with exponential backoff
        $retry_count = 0;
        $max_retries = 3;
        while (!$attachment_file && $retry_count < $max_retries) {
            sleep(pow(2, $retry_count));
            $attachment_file = wp_get_attachment_image_src($attachment_id, $size);
            $retry_count++;
        }

        if (!$attachment_file) {
            continue;
        }

        $thumbnail_file = $attachment_file[0];
        $thumbnail_extension = strtolower(pathinfo($thumbnail_file, PATHINFO_EXTENSION));
        if (!in_array($thumbnail_extension, ['jpg', 'jpeg', 'png'])) {
            continue;
        }

        // Convert to local file path
        $local_file_path = str_replace(site_url('/'), ABSPATH, $thumbnail_file);

        if (!file_exists($local_file_path)) {
            continue;
        }

        // Open the file
        if ($thumbnail_extension === 'jpg' || $thumbnail_extension === 'jpeg') {
            $image = @imagecreatefromjpeg($local_file_path);
        } elseif ($thumbnail_extension === 'png') {
            $image = @imagecreatefrompng($local_file_path);
            if ($image) {
                imagepalettetotruecolor($image); 
                imagealphablending($image, false);
                imagesavealpha($image, true);
            }
        } else {
            continue;
        }

        if (!$image) {
            continue;
        }

        $webp_file_path = str_replace('/uploads/', '/' . CP_WEBP_PATH . '/', $local_file_path) . '.webp';
        $directory = dirname($webp_file_path);

        if (!is_dir($directory)) {
            if (!mkdir($directory, 0755, true)) {
                error_log("CP_WEBP: failed to create directory: $directory");
                imagedestroy($image);
                continue;
            }
        }

        // Save the thumbnail as WebP
        if (!imagewebp($image, $webp_file_path, $quality)) {
            error_log("CP_WEBP: failed to convert image to WebP: $local_file_path");
        }

        // Clear resources
        imagedestroy($image);
        $image = null;
    }

    return $metadata;
}