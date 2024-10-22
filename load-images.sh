#!/bin/bash
# load-images.sh

# Define expected images and their .tar filenames
declare -A image_files=(
    ["nuwcdivnpt/stig-manager-auth"]="stig-manager-auth.tar"
    ["nuwcdivnpt/stig-manager"]="stig-manager.tar"
    ["mysql:8.0"]="mysql.tar"
)

# Function to check if image exists in Docker
image_exists() {
    docker image inspect "$1" >/dev/null 2>&1
    return $?
}

# Function to load image from tar if available
load_image() {
    local image_name=$1
    local tar_file=$2
    
    if [ -f "/app/images/$tar_file" ]; then
        echo "Found local tar for $image_name, loading..."
        docker load -i "/app/images/$tar_file"
        return $?
    fi
    return 1
}

# Main logic for each required image
for image in "${!image_files[@]}"; do
    if ! image_exists "$image"; then
        echo "Image $image not found in local Docker"
        if ! load_image "$image" "${image_files[$image]}"; then
            echo "No local tar found for $image, will use registry version"
        fi
    else
        echo "Image $image already exists in Docker, using existing version"
    fi
done
