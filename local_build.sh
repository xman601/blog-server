#!/bin/bash

# Local Docker Build Script for Go Web Server
# This script builds the image locally for testing without pushing to Docker Hub

# Configuration
IMAGE_NAME="blog-server-local"
DOCKERFILE_PATH="Docker/Dockerfile"
BUILD_CONTEXT="."
LOCAL_PORT="8000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is available
check_docker() {
    print_status "Checking Docker availability..."
    
    # Add Docker to PATH if on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_success "Docker is available"
}

# Function to get version tag
get_version() {
    if [ -n "$1" ]; then
        echo "$1"
    else
        echo -n "Enter version tag (e.g., v1.0.2, or press Enter for 'test'): "
        read -r version
        if [ -z "$version" ]; then
            echo "test"
        else
            echo "$version"
        fi
    fi
}

# Function to stop existing container
stop_existing_container() {
    local container_name="blog-server-local-test"
    
    if docker ps -q -f name="$container_name" | grep -q .; then
        print_status "Stopping existing container: $container_name"
        docker stop "$container_name" &> /dev/null
    fi
    
    if docker ps -aq -f name="$container_name" | grep -q .; then
        print_status "Removing existing container: $container_name"
        docker rm "$container_name" &> /dev/null
    fi
}

# Function to build the image locally
build_local() {
    local version="$1"
    local full_image_name="$IMAGE_NAME:$version"
    
    print_status "Building local image: $full_image_name"
    
    # Build command for local architecture only
    local build_cmd="docker build -f $DOCKERFILE_PATH -t $full_image_name $BUILD_CONTEXT"
    
    print_status "Executing: $build_cmd"
    
    if eval "$build_cmd"; then
        print_success "Successfully built local image: $full_image_name"
        return 0
    else
        print_error "Failed to build local image"
        return 1
    fi
}

# Function to run the container locally
run_local() {
    local version="$1"
    local full_image_name="$IMAGE_NAME:$version"
    local container_name="blog-server-local-test"
    
    print_status "Running local container..."
    
    # Stop any existing container
    stop_existing_container
    
    # Check if port is already in use
    if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port $LOCAL_PORT is already in use"
        echo -n "Do you want to continue anyway? (y/N): "
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            print_status "Aborted by user"
            exit 0
        fi
    fi
    
    # Run with web-server directory mounted
    local run_cmd="docker run -d \
        --name $container_name \
        -p $LOCAL_PORT:8000 \
        -v \$(pwd)/web-server:/app \
        $full_image_name"
    
    print_status "Executing: $run_cmd"
    
    if eval "$run_cmd"; then
        print_success "Container started successfully!"
        echo ""
        print_status "Container details:"
        docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        print_success "🚀 Your Go web server is running!"
        print_status "Access your server at: http://localhost:$LOCAL_PORT"
        print_status "Logs: docker logs $container_name"
        print_status "Stop: docker stop $container_name"
        echo ""
        print_status "Your web-server directory is mounted, so code changes will be reflected when you restart the container."
    else
        print_error "Failed to start container"
        return 1
    fi
}

# Function to show logs
show_logs() {
    local container_name="blog-server-local-test"
    
    if docker ps -q -f name="$container_name" | grep -q .; then
        print_status "Showing logs for $container_name (Press Ctrl+C to exit):"
        docker logs -f "$container_name"
    else
        print_error "Container $container_name is not running"
        return 1
    fi
}

# Function to clean up
cleanup() {
    local version="$1"
    local container_name="blog-server-local-test"
    local full_image_name="$IMAGE_NAME:$version"
    
    print_status "Cleaning up local resources..."
    
    # Stop and remove container
    stop_existing_container
    
    # Remove image if it exists
    if docker images -q "$full_image_name" | grep -q .; then
        print_status "Removing image: $full_image_name"
        docker rmi "$full_image_name" &> /dev/null
        print_success "Image removed"
    fi
    
    print_success "Cleanup completed"
}

# Main function
main() {
    local action="$1"
    local version_arg="$2"
    
    echo "🏠 Docker Local Build & Test Script"
    echo "=================================="
    echo ""
    
    case "$action" in
        "build")
            check_docker
            VERSION=$(get_version "$version_arg")
            if build_local "$VERSION"; then
                echo ""
                print_success "✅ Local build completed!"
                print_status "To run: ./local_build.sh run $VERSION"
            fi
            ;;
        "run")
            check_docker
            VERSION=$(get_version "$version_arg")
            run_local "$VERSION"
            ;;
        "logs")
            check_docker
            show_logs
            ;;
        "stop")
            check_docker
            stop_existing_container
            print_success "Container stopped"
            ;;
        "clean")
            check_docker
            VERSION=$(get_version "$version_arg")
            cleanup "$VERSION"
            ;;
        "test"|"")
            # Default: build and run
            check_docker
            VERSION=$(get_version "$version_arg")
            if build_local "$VERSION"; then
                echo ""
                run_local "$VERSION"
            fi
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Help function
show_help() {
    echo "Local Docker Build & Test Script for Go Web Server"
    echo ""
    echo "Usage: $0 [ACTION] [VERSION]"
    echo ""
    echo "Actions:"
    echo "  test        Build and run locally (default)"
    echo "  build       Build image only"
    echo "  run         Run existing image"
    echo "  logs        Show container logs"
    echo "  stop        Stop running container"
    echo "  clean       Stop container and remove image"
    echo ""
    echo "Arguments:"
    echo "  VERSION     Optional version tag (default: 'test')"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build and run with 'test' tag"
    echo "  $0 test v1.0.2       # Build and run with v1.0.2 tag"
    echo "  $0 build             # Build only with 'test' tag"
    echo "  $0 run v1.0.2        # Run existing v1.0.2 image"
    echo "  $0 logs              # Show container logs"
    echo "  $0 stop              # Stop running container"
    echo "  $0 clean             # Clean up everything"
    echo ""
    echo "Features:"
    echo "  - Builds for local architecture only (faster)"
    echo "  - Mounts web-server directory for live code changes"
    echo "  - Runs on http://localhost:$LOCAL_PORT"
    echo "  - No Docker Hub push (local testing only)"
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"