# Docker Build Scripts Usage Guide

This project includes two specialized build scripts for different purposes:

## 🏠 Local Development: `local_build.sh`

**Purpose**: Build and test locally without pushing to Docker Hub

### Quick Start
```bash
# Build and run for testing (default)
./local_build.sh

# Build only
./local_build.sh build

# View logs
./local_build.sh logs

# Stop container
./local_build.sh stop

# Clean everything
./local_build.sh clean
```

### Features
- ✅ **Fast builds** - Local architecture only
- ✅ **Live code changes** - Mounts `web-server/` directory
- ✅ **No Docker Hub** - Safe for testing
- ✅ **Port 8000** - Access at http://localhost:8000

---

## 🌍 Production Deployment: `live_build.sh`

**Purpose**: Build multi-platform and push to Docker Hub

### Quick Start
```bash
# Interactive deployment (recommended)
./live_build.sh v1.0.3

# Skip confirmation prompt
./live_build.sh --force v1.0.3
```

### Features
- ✅ **Multi-platform** - linux/amd64 + linux/arm64
- ✅ **Production ready** - Pushes to Docker Hub
- ✅ **Safety checks** - Confirmation prompts
- ✅ **Versioning** - Updates both versioned and latest tags

---

## 🚀 Recommended Workflow

1. **Develop & Test Locally**:
   ```bash
   # Make your code changes in web-server/
   ./local_build.sh test
   
   # Check logs if needed
   ./local_build.sh logs
   
   # Stop when done
   ./local_build.sh stop
   ```

2. **Deploy to Production**:
   ```bash
   # Once you're satisfied with local testing
   ./live_build.sh v1.0.4
   ```

3. **Use on Servers**:
   ```bash
   # Anyone can now pull and use your image
   docker pull exobytelabs/go-webserver:v1.0.4
   docker run -p 8000:8000 exobytelabs/go-webserver:v1.0.4
   ```

---

## 🛠️ Script Comparison

| Feature | `local_build.sh` | `live_build.sh` |
|---------|------------------|-----------------|
| **Speed** | ⚡ Fast (single platform) | 🐌 Slower (multi-platform) |
| **Docker Hub** | ❌ No push | ✅ Pushes to production |
| **Architecture** | 🏠 Local only | 🌍 amd64 + arm64 |
| **Safety** | ✅ No risk | ⚠️ Production deployment |
| **Volume Mount** | ✅ Auto-mounts web-server/ | ❌ Image only |
| **Use Case** | 🧪 Development & Testing | 🚀 Production Release |

---

## 💡 Tips

- **Always test locally first** before deploying to production
- **Use semantic versioning** (v1.0.1, v1.0.2, etc.)
- **Check logs** with `./local_build.sh logs` if something isn't working
- **Clean up** with `./local_build.sh clean` to free disk space

---

## 🔧 Requirements

- Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- Docker Hub account (for live builds)
- Login to Docker Hub: `docker login`