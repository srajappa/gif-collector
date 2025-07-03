const path = require('path');

const settings = {
    // Browser settings
    headless: process.env.HEADLESS === 'true',
    viewport: {
        width: parseInt(process.env.VIEWPORT_WIDTH) || 1280,
        height: parseInt(process.env.VIEWPORT_HEIGHT) || 720
    },
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',

    // Recording settings
    outputDir: process.env.OUTPUT_DIR || path.join(__dirname, '../../output'),
    defaultStepDelay: parseInt(process.env.STEP_DELAY) || 1500,

    // GIF conversion settings
    defaultGifOptions: {
        fps: 10,
        scale: '800:-1',
        quality: 'medium'
    },

    // Test app settings
    testAppUrl: process.env.TEST_APP_URL || 'http://localhost:3001',

    // API settings
    maxConcurrentRecordings: parseInt(process.env.MAX_CONCURRENT_RECORDINGS) || 3,
    requestTimeout: parseInt(process.env.REQUEST_TIMEOUT) || 300000, // 5 minutes

    // File settings
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 100 * 1024 * 1024, // 100MB
    allowedVideoFormats: ['.webm', '.mp4'],
    allowedGifFormats: ['.gif'],

    // Cleanup settings
    autoCleanup: process.env.AUTO_CLEANUP === 'true',
    maxAge: parseInt(process.env.MAX_FILE_AGE) || 7 * 24 * 60 * 60 * 1000, // 7 days

    // Development settings
    isDevelopment: process.env.NODE_ENV === 'development',
    logLevel: process.env.LOG_LEVEL || 'info'
};

module.exports = settings;