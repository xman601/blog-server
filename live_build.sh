#!/bin/bash

# Live Docker Build Script for Go Web Server
# This script builds and pushes a multi-platform Docker image to production

# Configuration
IMAGE_NAME="exobytelabs/go-webserver"
DOCKERFILE_PATH="Docker/Dockerfile"
BUILD_CONTEXT="."

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

# Function to check if user is logged in to Docker Hub
check_docker_login() {
    print_status "Checking Docker Hub authentication..."
    
    if ! docker info | grep -q "Username:"; then
        print_error "Not logged in to Docker Hub"
        print_status "Please run: docker login"
        exit 1
    fi
    
    print_success "Docker Hub authentication verified"
}

# Function to get version tag
get_version() {
    if [ -n "$1" ]; then
        echo "$1"
    else
        echo -n "Enter version tag (e.g., v1.0.3): "
        read -r version
        if [ -z "$version" ]; then
            print_error "Version tag is required for live builds"
            exit 1
        else
            echo "$version"
        fi
    fi
}

# Function to confirm deployment
confirm_deployment() {
    local version="$1"
    
    echo ""
    print_warning "⚠️  LIVE DEPLOYMENT WARNING ⚠️"
    echo "You are about to build and push to production:"
    echo "  Repository: $IMAGE_NAME"
    echo "  Version: $version"
    echo "  Platforms: linux/amd64, linux/arm64"
    echo ""
    echo -n "Are you sure you want to proceed? (yes/no): "
    read -r confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    print_status "Deployment confirmed, proceeding..."
}

# Function to setup buildx for multi-platform builds
setup_buildx() {
    print_status "Setting up Docker Buildx for multi-platform builds..."
    
    # Check if multiplatform builder exists
    if docker buildx inspect multiplatform &> /dev/null; then
        print_status "Using existing multiplatform builder"
        docker buildx use multiplatform
    else
        print_status "Creating new multiplatform builder"
        docker buildx create --name multiplatform --use
    fi
    
    print_success "Buildx setup complete"
}

# Function to build and push the image
build_and_push() {
    local version="$1"
    local platforms="linux/amd64,linux/arm64"
    
    print_status "Building multi-platform image for PRODUCTION deployment"
    print_status "Platforms: $platforms"
    print_status "Repository: $IMAGE_NAME"
    print_status "Version: $version"
    
    # Build command
    local build_cmd="docker buildx build \
        --platform $platforms \
        -f $DOCKERFILE_PATH \
        -t $IMAGE_NAME:$version \
        -t $IMAGE_NAME:latest \
        --push $BUILD_CONTEXT"
    
    print_status "Executing production build..."
    echo "$build_cmd"
    
    if eval "$build_cmd"; then
        print_success "Successfully built and pushed to production!"
        print_success "✅ $IMAGE_NAME:$version"
        print_success "✅ $IMAGE_NAME:latest"
    else
        print_error "Failed to build and push image"
        exit 1
    fi
}

# Function to verify the pushed image
verify_image() {
    local version="$1"
    
    print_status "Verifying pushed image..."
    
    if docker buildx imagetools inspect "$IMAGE_NAME:$version" &> /dev/null; then
        print_success "Image verification successful"
        echo ""
        print_status "Production image details:"
        docker buildx imagetools inspect "$IMAGE_NAME:$version"
    else
        print_warning "Could not verify image (but push might have succeeded)"
    fi
}

# Function to show deployment info
show_deployment_info() {
    local version="$1"
    
    echo ""
    print_success "🚀 PRODUCTION DEPLOYMENT COMPLETED! 🚀"
    echo ""
    print_status "Your image is now available worldwide:"
    echo "  📦 docker pull $IMAGE_NAME:$version"
    echo "  📦 docker pull $IMAGE_NAME:latest"
    echo ""
    print_status "To deploy on any server:"
    echo "  🖥️  docker run -p 8000:8000 $IMAGE_NAME:$version"
    echo ""
    print_status "For development with volume mounting:"
    echo "  💻 docker run -p 8000:8000 -v \$(pwd)/web-server:/app $IMAGE_NAME:$version"
    echo ""
    print_status "Docker Hub: https://hub.docker.com/r/exobytelabs/go-webserver"
}

# Function to test local build first
suggest_local_test() {
    echo ""
    print_warning "💡 Pro Tip:"
    print_status "Consider testing locally first with:"
    echo "  ./local_build.sh test"
    echo ""
}

# Main function
main() {
    local skip_confirmation="$1"
    local version_arg="$2"
    
    echo "🌍 Docker LIVE/PRODUCTION Build Script"
    echo "======================================"
    
    suggest_local_test
    
    # Check Docker and login
    check_docker
    check_docker_login
    
    # Get version
    if [ "$skip_confirmation" = "--force" ]; then
        VERSION=$(get_version "$version_arg")
    else
        VERSION=$(get_version "$1")
        # Confirm deployment unless --force is used
        confirm_deployment "$VERSION"
    fi
    
    # Setup buildx
    setup_buildx
    
    # Build and push
    build_and_push "$VERSION"
    
    # Verify
    verify_image "$VERSION"
    
    # Show deployment info
    show_deployment_info "$VERSION"
}

# Help function
show_help() {
    echo "Live/Production Docker Build Script for Go Web Server"
    echo ""
    echo "Usage: $0 [--force] [VERSION]"
    echo ""
    echo "Arguments:"
    echo "  --force     Skip confirmation prompt"
    echo "  VERSION     Version tag (required, e.g., v1.0.3)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode with confirmation"
    echo "  $0 v1.0.3            # Deploy version v1.0.3 with confirmation"
    echo "  $0 --force v1.0.3    # Deploy without confirmation prompt"
    echo ""
    echo "This script will:"
    echo "  - Build for both linux/amd64 and linux/arm64 platforms"
    echo "  - Push to Docker Hub repository: $IMAGE_NAME"
    echo "  - Update both versioned tag and 'latest' tag"
    echo "  - Verify the pushed image"
    echo ""
    echo "⚠️  WARNING: This pushes to production Docker Hub!"
    echo "    Test locally first with: ./local_build.sh test"
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"