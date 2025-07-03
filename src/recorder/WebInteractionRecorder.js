const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { convertToGif } = require('./utils/ffmpeg');
const settings = require('../config/settings');

class WebInteractionRecorder {
    constructor(options = {}) {
        this.browser = null;
        this.page = null;
        this.recording = false;
        this.recordingId = null;
        this.outputDir = options.outputDir || settings.outputDir;
        this.videoDir = path.join(this.outputDir, 'videos');
        this.gifDir = path.join(this.outputDir, 'gifs');
        this.headless = options.headless !== undefined ? options.headless : settings.headless;

        this.ensureDirectories();
    }

    ensureDirectories() {
        [this.outputDir, this.videoDir, this.gifDir].forEach(dir => {
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
        });
    }

    async initialize() {
        if (this.browser) {
            await this.close();
        }

        console.log('🎬 Initializing browser...');

        this.browser = await chromium.launch({
            headless: this.headless,
            args: [
                '--no-sandbox',
                '--disable-dev-shm-usage',
                '--disable-web-security',
                '--disable-features=VizDisplayCompositor',
                '--disable-background-networking',
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-breakpad',
                '--disable-component-extensions-with-background-pages',
                '--disable-extensions',
                '--disable-features=TranslateUI',
                '--disable-ipc-flooding-protection',
                '--disable-renderer-backgrounding',
                '--enable-features=NetworkService,NetworkServiceInProcess',
                '--force-color-profile=srgb',
                '--metrics-recording-only',
                '--no-first-run'
            ]
        });

        this.page = await this.browser.newPage();

        // Set viewport for consistent recordings
        await this.page.setViewportSize({
            width: settings.viewport.width,
            height: settings.viewport.height
        });

        // Set user agent
        await this.page.setUserAgent(settings.userAgent);

        console.log('✅ Browser initialized successfully');
        return this;
    }

    async recordUserFlow(flowConfig) {
        if (!this.page) {
            throw new Error('Browser not initialized. Call initialize() first.');
        }

        const { name, baseUrl, steps, options = {} } = flowConfig;
        this.recordingId = uuidv4();

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const fileName = `${name}_${timestamp}`;
        const videoPath = path.join(this.videoDir, `${fileName}.webm`);
        const gifPath = path.join(this.gifDir, `${fileName}.gif`);

        console.log(`🎬 Starting recording: ${name} (ID: ${this.recordingId})`);

        const recordingInfo = {
            id: this.recordingId,
            name,
            status: 'recording',
            startTime: new Date().toISOString(),
            videoPath,
            gifPath,
            steps: steps.length
        };

        try {
            this.recording = true;

            // Start screen recording
            await this.page.video.start({
                dir: this.videoDir,
                size: {
                    width: settings.viewport.width,
                    height: settings.viewport.height
                }
            });

            // Navigate to base URL
            console.log(`🌐 Navigating to: ${baseUrl}`);
            await this.page.goto(baseUrl, {
                waitUntil: 'networkidle',
                timeout: 30000
            });

            // Wait for initial page load
            await this.page.waitForTimeout(2000);

            // Execute each step
            for (let i = 0; i < steps.length; i++) {
                const step = steps[i];
                console.log(`⚡ Step ${i + 1}/${steps.length}: ${step.description || step.action}`);

                await this.executeStep(step);

                // Wait between steps for smooth recording
                const delay = step.delay || options.stepDelay || settings.defaultStepDelay;
                await this.page.waitForTimeout(delay);
            }

            // Final wait before stopping recording
            await this.page.waitForTimeout(2000);

            // Stop recording
            const videoFile = await this.page.video.stop();

            // Move video to proper location if needed
            if (videoFile !== videoPath) {
                fs.renameSync(videoFile, videoPath);
            }

            console.log(`📹 Video saved: ${videoPath}`);

            // Convert to GIF
            console.log(`🎨 Converting to GIF...`);
            await convertToGif(videoPath, gifPath, options.gif || settings.defaultGifOptions);

            console.log(`🎉 GIF created: ${gifPath}`);

            recordingInfo.status = 'completed';
            recordingInfo.endTime = new Date().toISOString();
            recordingInfo.videoSize = fs.statSync(videoPath).size;
            recordingInfo.gifSize = fs.statSync(gifPath).size;

            this.recording = false;

            return recordingInfo;

        } catch (error) {
            console.error(`❌ Error recording ${name}:`, error);

            recordingInfo.status = 'failed';
            recordingInfo.error = error.message;
            recordingInfo.endTime = new Date().toISOString();

            this.recording = false;
            throw error;
        }
    }

    async executeStep(step) {
        const { action, selector, value, options = {} } = step;

        try {
            switch (action) {
                case 'click':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.click(selector, options);
                    break;

                case 'type':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.fill(selector, value, options);
                    break;

                case 'hover':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.hover(selector);
                    break;

                case 'scroll':
                    await this.page.evaluate((scrollOptions) => {
                        window.scrollBy(
                            scrollOptions.x || 0,
                            scrollOptions.y || 500
                        );
                    }, options);
                    break;

                case 'wait':
                    if (selector) {
                        await this.page.waitForSelector(selector, {
                            timeout: options.timeout || 30000
                        });
                    } else {
                        await this.page.waitForTimeout(value || 1000);
                    }
                    break;

                case 'navigate':
                    await this.page.goto(value, {
                        waitUntil: 'networkidle',
                        timeout: 30000
                    });
                    break;

                case 'screenshot':
                    const screenshotPath = path.join(
                        this.outputDir,
                        `${step.name || 'screenshot'}.png`
                    );
                    await this.page.screenshot({
                        path: screenshotPath,
                        fullPage: options.fullPage || false
                    });
                    break;

                case 'select':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.selectOption(selector, value);
                    break;

                case 'check':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.check(selector);
                    break;

                case 'uncheck':
                    await this.page.waitForSelector(selector, { timeout: 10000 });
                    await this.page.uncheck(selector);
                    break;

                case 'keypress':
                    await this.page.keyboard.press(value);
                    break;

                case 'drag':
                    await this.page.dragAndDrop(selector, value);
                    break;

                default:
                    console.warn(`⚠️ Unknown action: ${action}`);
            }
        } catch (error) {
            console.error(`❌ Failed to execute step ${action}:`, error.message);
            throw error;
        }
    }

    async close() {
        if (this.recording) {
            console.log('⏹️ Stopping ongoing recording...');
            this.recording = false;
        }

        if (this.browser) {
            await this.browser.close();
            this.browser = null;
            this.page = null;
            console.log('🔒 Browser closed');
        }
    }

    getStatus() {
        return {
            initialized: !!this.browser,
            recording: this.recording,
            recordingId: this.recordingId
        };
    }
}

module.exports = { WebInteractionRecorder };