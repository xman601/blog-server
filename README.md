# Blog Server Docker Guide

A dockerized Go web server that serves markdown blog posts with live file watching capabilities.

## Quick Start

### Build and Run with Docker Compose (Recommended)
```bash
# Build and start the container in the background
docker compose up -d --build

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

## Building Docker Image

### Basic Build Commands
```bash
# Basic build
docker build -t blog-server:latest .

# Build with no cache (force fresh build)
docker build --no-cache -t blog-server:latest .

# Build with custom tag
docker build -t my-blog:v1.0 .
```

### Using Docker Compose to Build
```bash
# Build and run
docker compose up -d --build

# Just build (without running)
docker compose build
```

### Verify the Build
```bash
# Check if image was created
docker images blog-server

# Check image size
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" blog-server
```

### Manual Docker Commands

#### 1. Build the Docker Image
```bash
docker build -t blog-server:latest .
```

#### 2. Run the Container
```bash
# Run in the background
docker run -d \
  --name blog-server \
  -p 8080:8000 \
  -v ./docs:/app/docs \
  -v ./public:/app/public \
  -v ./templates:/app/templates \
  blog-server:latest

# Run in foreground (see logs directly)
docker run --rm \
  --name blog-server \
  -p 8080:8000 \
  -v ./docs:/app/docs \
  -v ./public:/app/public \
  -v ./templates:/app/templates \
  blog-server:latest
```

#### 3. Container Management
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs blog-server

# Follow logs in real-time
docker logs -f blog-server

# Stop the container
docker stop blog-server

# Remove the container
docker rm blog-server

# Stop and remove in one command
docker rm -f blog-server
```

## Accessing Your Application

Once running, your blog server is available at:
- **Main Site**: http://localhost:8080
- **Posts API**: http://localhost:8080/api/posts
- **Individual Post**: http://localhost:8080/api/post/hello

## File Changes & Live Updates

### ✅ Files that UPDATE AUTOMATICALLY (no restart needed):
- **Markdown files** in `docs/` folder - New posts appear immediately
- **Static files** in `public/` folder - CSS, images, etc.
- **HTML templates** in `templates/` folder - Layout changes

These files are **volume mounted**, so changes on your host machine are immediately reflected in the container.

### ❌ Files that REQUIRE REBUILD:
- **Go source code** (`main.go`, `go.mod`, etc.)
- **Dockerfile changes**

For Go code changes, you need to rebuild and restart:
```bash
# Stop current container
docker compose down

# Rebuild and restart
docker compose up -d --build
```

## Development Workflow

### For Content Changes (Markdown, CSS, Templates):
1. Edit files in `docs/`, `public/`, or `templates/`
2. Refresh your browser - changes appear immediately! ✨

### For Code Changes:
1. Edit `main.go` or other Go files
2. Rebuild the container:
   ```bash
   docker compose down
   docker compose up -d --build
   ```

## Troubleshooting

### Port Already in Use
If you get "port already allocated" error:
```bash
# Find what's using port 8080
netstat -ano | findstr :8080

# Or change the port in docker-compose.yml:
ports:
  - "3000:8000"  # Use port 3000 instead
```

### Container Won't Start
```bash
# Check container status
docker ps -a

# View error logs
docker logs blog-server

# Remove problematic container
docker rm -f blog-server
```

### Volume Mount Issues
Make sure you're running Docker commands from the project root directory (`P:\DockerWebServer`) where your `docs/`, `public/`, and `templates/` folders are located.

## Docker Image Details

- **Base Image**: Alpine Linux (lightweight)
- **Final Size**: ~38MB
- **Security**: Runs as non-root user
- **Health Check**: Built-in monitoring
- **Multi-stage Build**: Optimized for production

## Useful Commands

```bash
# View image size
docker images blog-server

# Remove unused images
docker image prune

# Remove all containers and images (clean slate)
docker system prune -a

# Access container shell for debugging
docker exec -it blog-server sh
```