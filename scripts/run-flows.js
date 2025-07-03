#!/usr/bin/env node

/**
 * Script to run predefined flows for testing and demonstration
 */

const fs = require('fs');
const path = require('path');
const { WebInteractionRecorder } = require('../src/recorder/WebInteractionRecorder');

const flowsPath = path.join(__dirname, '../src/config/flows.json');

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

function colorLog(color, message) {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function printHeader(title) {
    const border = '='.repeat(60);
    colorLog('cyan', border);
    colorLog('cyan', `🎬 ${title}`);
    colorLog('cyan', border);
}

function printStep(step, current, total) {
    colorLog('blue', `\n📋 Step ${current}/${total}: ${step}`);
}

function printSuccess(message) {
    colorLog('green', `✅ ${message}`);
}

function printError(message) {
    colorLog('red', `❌ ${message}`);
}

function printWarning(message) {
    colorLog('yellow', `⚠️  ${message}`);
}

function readFlows() {
    try {
        const data = fs.readFileSync(flowsPath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        printError(`Failed to read flows: ${error.message}`);
        return { flows: [] };
    }
}

async function runFlow(recorder, flow, index, total) {
    printStep(`Running flow: ${flow.name}`, index + 1, total);

    try {
        const startTime = Date.now();
        const result = await recorder.recordUserFlow(flow);
        const duration = ((Date.now() - startTime) / 1000).toFixed(1);

        printSuccess(`Flow "${flow.name}" completed in ${duration}s`);
        printSuccess(`Video: ${result.videoPath}`);
        printSuccess(`GIF: ${result.gifPath}`);

        // Display file sizes
        if (fs.existsSync(result.videoPath)) {
            const videoSize = (fs.statSync(result.videoPath).size / 1024 / 1024).toFixed(2);
            console.log(`   📹 Video size: ${videoSize} MB`);
        }

        if (fs.existsSync(result.gifPath)) {
            const gifSize = (fs.statSync(result.gifPath).size / 1024 / 1024).toFixed(2);
            console.log(`   🎨 GIF size: ${gifSize} MB`);
        }

        return { success: true, result, duration };
    } catch (error) {
        printError(`Flow "${flow.name}" failed: ${error.message}`);
        return { success: false, error: error.message };
    }
}

async function waitForTestApp() {
    const testAppUrl = process.env.TEST_APP_URL || 'http://localhost:3001';
    const maxRetries = 30;
    let retries = 0;

    printStep('Waiting for test app to be ready...', 1, 1);

    while (retries < maxRetries) {
        try {
            const response = await fetch(`${testAppUrl}/health`);
            if (response.ok) {
                printSuccess('Test app is ready');
                return true;
            }
        } catch (error) {
            // Continue trying
        }

        retries++;
        await new Promise(resolve => setTimeout(resolve, 1000));
        process.stdout.write('.');
    }

    printError('Test app is not responding');
    return false;
}

async function main() {
    const args = process.argv.slice(2);
    const selectedFlowId = args[0];
    const headless = !args.includes('--no-headless');

    printHeader('Web Interaction GIF Generator - Flow Runner');

    console.log(`🔧 Configuration:`);
    console.log(`   Headless mode: ${headless}`);
    console.log(`   Selected flow: ${selectedFlowId || 'All flows'}`);
    console.log(`   Output directory: ${path.join(__dirname, '../output')}`);
    console.log('');

    // Check if test app is running
    if (!(await waitForTestApp())) {
        printError('Please ensure the test app is running: docker-compose up test-app');
        process.exit(1);
    }

    // Read flow configurations
    const flowsData = readFlows();
    if (flowsData.flows.length === 0) {
        printError('No flows found in configuration');
        process.exit(1);
    }

    // Filter flows if specific flow is requested
    let flowsToRun = flowsData.flows;
    if (selectedFlowId) {
        flowsToRun = flowsData.flows.filter(f => f.id === selectedFlowId);
        if (flowsToRun.length === 0) {
            printError(`Flow "${selectedFlowId}" not found`);
            console.log('Available flows:');
            flowsData.flows.forEach(f => console.log(`  - ${f.id}: ${f.name}`));
            process.exit(1);
        }
    }

    colorLog('magenta', `\n🎯 Found ${flowsToRun.length} flow(s) to execute\n`);

    // Initialize recorder
    let recorder = null;
    const results = [];

    try {
        recorder = new WebInteractionRecorder({ headless });
        await recorder.initialize();

        // Run each flow
        for (let i = 0; i < flowsToRun.length; i++) {
            const flow = flowsToRun[i];
            const result = await runFlow(recorder, flow, i, flowsToRun.length);
            results.push({ flow: flow.name, ...result });

            // Add delay between flows
            if (i < flowsToRun.length - 1) {
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        }

    } catch (error) {
        printError(`Setup failed: ${error.message}`);
        process.exit(1);
    } finally {
        if (recorder) {
            await recorder.close();
        }
    }

    // Print summary
    printHeader('Execution Summary');

    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;

    console.log(`📊 Results:`);
    console.log(`   ✅ Successful: ${successful}`);
    console.log(`   ❌ Failed: ${failed}`);
    console.log(`   📁 Output directory: ${path.join(__dirname, '../output')}`);

    if (failed > 0) {
        console.log('\n❌ Failed flows:');
        results.filter(r => !r.success).forEach(r => {
            console.log(`   - ${r.flow}: ${r.error}`);
        });
    }

    if (successful > 0) {
        console.log('\n✅ Successful flows:');
        results.filter(r => r.success).forEach(r => {
            console.log(`   - ${r.flow} (${r.duration}s)`);
        });

        console.log('\n🎉 GIFs are ready for use in your documentation!');
    }

    process.exit(failed > 0 ? 1 : 0);
}

// Handle process termination
process.on('SIGINT', () => {
    printWarning('\nReceived SIGINT, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    printWarning('\nReceived SIGTERM, shutting down gracefully...');
    process.exit(0);
});

// Run the script
if (require.main === module) {
    main().catch(error => {
        printError(`Unexpected error: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    });
}