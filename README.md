# 🎬 gif-collector

An automated solution for generating GIFs of web application interactions, perfect for creating comprehensive user documentation.

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Git

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd web-interaction-gif-generator
```

2. **Run the setup script:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

3. **Access the applications:**
- 📱 **GIF Generator Interface**: http://localhost:3000
- 🎯 **Test Application**: http://localhost:3001

## 🏗️ Architecture

### Services

| Service | Port | Description |
|---------|------|-------------|
| `gif-generator` | 3000 | Main application with web interface and API |
| `test-app` | 3001 | Sample web application for testing recordings |

### Project Structure

```
web-interaction-gif-generator/
├── 📁 src/                    # Main application source
│   ├── 📁 api/               # REST API routes
│   ├── 📁 recorder/          # Recording engine
│   ├── 📁 config/            # Configuration files
│   └── 📁 web/               # Web interface
├── 📁 test-app/              # Sample application
├── 📁 output/                # Generated videos and GIFs
├── 📁 scripts/               # Utility scripts
└── 📁 docs/                  # Documentation
```

## 🎯 Features

### Core Capabilities
- ✅ **Automated Browser Control** - Uses Playwright for reliable automation
- ✅ **High-Quality GIF Generation** - FFmpeg-powered conversion with optimization
- ✅ **RESTful API** - Complete API for flow management and execution
- ✅ **Web Interface** - User-friendly interface for creating and managing flows
- ✅ **Docker Deployment** - Containerized for easy deployment and scaling
- ✅ **Flow Configuration** - JSON-based flow definitions with validation

### Supported Actions
- `click` - Click on elements
- `type` - Fill form fields
- `hover` - Hover over elements
- `scroll` - Scroll pages
- `wait` - Wait for elements or timeouts
- `navigate` - Navigate to URLs
- `select` - Dropdown selections
- `check/uncheck` - Checkbox interactions
- `screenshot` - Capture screenshots
- `keypress` - Keyboard interactions
- `drag` - Drag and drop operations

## 📖 Usage

### 1. Using the Web Interface

1. Visit http://localhost:3000
2. Create or select a flow configuration
3. Execute the flow to generate GIF
4. Download the generated assets

### 2. Using the API

#### Create a Flow
```bash
curl -X POST http://localhost:3000/api/flows \
  -H "Content-Type: application/json" \
  -d '{
    "id": "my_flow",
    "name": "My Demo Flow",
    "baseUrl": "http://test-app:3001",
    "steps": [
      {
        "action": "click",
        "selector": "#login-btn",
        "description": "Click login button"
      }
    ]
  }'
```

#### Execute a Flow
```bash
curl -X POST http://localhost:3000/api/flows/my_flow/execute
```

### 3. Using Node.js

```javascript
const { WebInteractionRecorder } = require('./src/recorder/WebInteractionRecorder');

const recorder = new WebInteractionRecorder();
await recorder.initialize();

const result = await recorder.recordUserFlow({
  name: 'login_demo',
  baseUrl: 'http://localhost:3001',
  steps: [
    { action: 'click', selector: '#login-btn' },
    { action: 'type', selector: '#email', value: 'demo@example.com' },
    { action: 'type', selector: '#password', value: 'demo123' },
    { action: 'click', selector: '#submit-login' }
  ]
});

await recorder.close();
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HEADLESS` | `true` | Run browser in headless mode |
| `VIEWPORT_WIDTH` | `1280` | Browser viewport width |
| `VIEWPORT_HEIGHT` | `720` | Browser viewport height |
| `OUTPUT_DIR` | `/app/output` | Output directory for files |
| `STEP_DELAY` | `1500` | Default delay between steps (ms) |
| `MAX_CONCURRENT_RECORDINGS` | `3` | Maximum parallel recordings |

### Flow Configuration

```json
{
  "id": "unique_flow_id",
  "name": "Human-readable name",
  "description": "Flow description",
  "baseUrl": "https://your-app.com",
  "steps": [
    {
      "action": "click",
      "selector": "#element-id",
      "description": "Step description",
      "delay": 1500,
      "options": {}
    }
  ],
  "options": {
    "gif": {
      "fps": 10,
      "scale": "800:-1",
      "quality": "medium"
    }
  }
}
```

### GIF Quality Settings

| Quality | Colors | File Size | Use Case |
|---------|--------|-----------|----------|
| `low` | 64 | Smallest | Quick previews |
| `medium` | 128 | Balanced | General documentation |
| `high` | 256 | Largest | Detailed tutorials |

## 🛠️ Development

### Local Development

```bash
# Install dependencies
npm install

# Start in development mode
npm run dev

# Run tests
npm test

# Run specific flow
npm run run-flows
```

### Docker Commands

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart
```

### Adding New Actions

1. Update the `WebInteractionRecorder.executeStep()` method
2. Add validation in `src/api/routes/flows.js`
3. Update the schema in flow validation
4. Add documentation and examples

## 📊 API Reference

### Flows API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/flows` | GET | List all flows |
| `/api/flows` | POST | Create new flow |
| `/api/flows/:id` | GET | Get specific flow |
| `/api/flows/:id` | PUT | Update flow |
| `/api/flows/:id` | DELETE | Delete flow |
| `/api/flows/:id/execute` | POST | Execute flow |
| `/api/flows/validate` | POST | Validate flow config |

### Recordings API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/recordings` | GET | List recordings |
| `/api/recordings/:id` | GET | Get recording details |
| `/api/recordings/:id` | DELETE | Delete recording |

## 🔍 Troubleshooting

### Common Issues

**1. Container fails to start**
```bash
# Check logs
docker-compose logs gif-generator

# Verify ports are available
netstat -tlnp | grep :3000
```

**2. GIF generation fails**
```bash
# Check FFmpeg installation in container
docker-compose exec gif-generator ffmpeg -version

# Verify output directory permissions
docker-compose exec gif-generator ls -la /app/output
```

**3. Browser automation issues**
```bash
# Test with headless=false for debugging
curl -X POST http://localhost:3000/api/flows/demo_login/execute \
  -H "Content-Type: application/json" \
  -d '{"headless": false}'
```

**4. Selector not found**
- Use browser dev tools to verify selectors
- Add explicit waits for dynamic content
- Check for iframe context issues

### Performance Optimization

1. **Reduce GIF file sizes:**
   - Lower FPS (8-12 is usually sufficient)
   - Reduce scale dimensions
   - Use 'medium' or 'low' quality

2. **Improve recording reliability:**
   - Add appropriate delays between steps
   - Use explicit waits for dynamic content
   - Verify selectors in browser dev tools

3. **Scale for production:**
   - Increase `MAX_CONCURRENT_RECORDINGS`
   - Use headless mode (`HEADLESS=true`)
   - Set up automated cleanup

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📜 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- [Playwright](https://playwright.dev/) - Browser automation
- [FFmpeg](https://ffmpeg.org/) - Video processing and GIF conversion
- [Express.js](https://expressjs.com/) - Web framework
- [Docker](https://www.docker.com/) - Containerization

## 📚 Additional Resources

- [API Documentation](./docs/API.md)
- [Flow Configuration Guide](./docs/FLOWS.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)
- [Troubleshooting Guide](./docs/TROUBLESHOOTING.md)

---

**Happy GIF Generation! 🎬✨**