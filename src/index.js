const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const { WebInteractionRecorder } = require('./recorder/WebInteractionRecorder');
const settings = require('./config/settings');

// Import routes
const flowsRouter = require('./api/routes/flows');
const recordingsRouter = require('./api/routes/recordings');
const healthRouter = require('./api/routes/health');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files
app.use('/web', express.static(path.join(__dirname, 'web')));
app.use('/output', express.static(path.join(__dirname, '../output')));

// API Routes
app.use('/api/flows', flowsRouter);
app.use('/api/recordings', recordingsRouter);
app.use('/health', healthRouter);

// Main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'web/index.html'));
});

// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Initialize output directories
function initializeDirectories() {
    const dirs = [
        path.join(__dirname, '../output'),
        path.join(__dirname, '../output/videos'),
        path.join(__dirname, '../output/gifs')
    ];

    dirs.forEach(dir => {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
            console.log(`Created directory: ${dir}`);
        }
    });
}

// Start server
async function startServer() {
    try {
        initializeDirectories();

        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 GIF Generator Server running on port ${PORT}`);
            console.log(`📱 Web Interface: http://localhost:${PORT}`);
            console.log(`📊 API Docs: http://localhost:${PORT}/api/docs`);
            console.log(`🎬 Test App: http://localhost:3001`);
            console.log(`📁 Output Directory: ${path.join(__dirname, '../output')}`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down gracefully...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Shutting down gracefully...');
    process.exit(0);
});

startServer();