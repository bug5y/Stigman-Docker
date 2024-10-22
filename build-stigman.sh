#!/bin/bash
# build-stigman.sh

# Configuration
BASE_IMAGE="docker:latest"
WRAPPER_IMAGE="stigman-wrapper-persistent"

# Check for base image
check_base_image() {
    if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
        echo "Base image $BASE_IMAGE not found locally"
        if [ -f "images/docker-base.tar" ]; then
            echo "Loading base image from local tar..."
            docker load -i "images/docker-base.tar"
            if [ $? -ne 0 ]; then
                echo "Failed to load base image from tar, will pull from registry"
                docker pull "$BASE_IMAGE"
            fi
        else
            echo "No local tar found, using registry image..."
            docker pull "$BASE_IMAGE"
        fi
    else
        echo "Base image $BASE_IMAGE already exists locally"
    fi
}

# Create Dockerfile
create_dockerfile() {
    cat > Dockerfile.tmp << EOF
FROM ${BASE_IMAGE}

# Install required tools
RUN apk add --no-cache \
    py-pip \
    python3 \
    docker-compose \
    bash

WORKDIR /app

# Copy docker-compose file and scripts
COPY docker-compose.yml .
COPY load-images.sh .

RUN chmod +x /app/load-images.sh

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo '/app/load-images.sh' >> /app/start.sh && \
    echo 'docker volume create --name mysql_data' >> /app/start.sh && \
    echo 'docker volume create --name keycloak_data' >> /app/start.sh && \
    echo 'docker volume create --name api_data' >> /app/start.sh && \
    echo 'docker-compose up' >> /app/start.sh && \
    chmod +x /app/start.sh

CMD ["/app/start.sh"]
EOF
}

# Main build process
main() {
    check_base_image
    create_dockerfile
    echo "Building $WRAPPER_IMAGE..."
    docker build -t "$WRAPPER_IMAGE" -f Dockerfile.tmp .
    rm Dockerfile.tmp
    echo "Build complete!"
}

main
