const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');

async function convertToGif(videoPath, gifPath, options = {}) {
    return new Promise((resolve, reject) => {
        console.log(`🎨 Converting ${path.basename(videoPath)} to GIF...`);

        const {
            fps = 10,
            scale = '800:-1',
            quality = 'medium',
            startTime = 0,
            duration = null
        } = options;

        // Quality settings
        const qualitySettings = {
            low: { colors: 64, dither: 'sierra2_4a' },
            medium: { colors: 128, dither: 'floyd_steinberg' },
            high: { colors: 256, dither: 'floyd_steinberg' }
        };

        const settings = qualitySettings[quality] || qualitySettings.medium;
        const tempPalettePath = gifPath.replace('.gif', '_palette.png');

        // First pass: Generate palette
        const firstPassCommand = ffmpeg(videoPath)
            .fps(fps)
            .videoFilters([
                `scale=${scale}:flags=lanczos`,
                `palettegen=max_colors=${settings.colors}:stats_mode=diff`
            ])
            .output(tempPalettePath);

        // Add start time if specified
        if (startTime > 0) {
            firstPassCommand.seekInput(startTime);
        }

        // Add duration if specified
        if (duration) {
            firstPassCommand.duration(duration);
        }

        firstPassCommand
            .on('start', (commandLine) => {
                console.log('🎬 Generating palette:', commandLine);
            })
            .on('progress', (progress) => {
                if (progress.percent) {
                    console.log(`📊 Palette progress: ${Math.round(progress.percent)}%`);
                }
            })
            .on('end', () => {
                console.log('✅ Palette generated, creating GIF...');

                // Second pass: Create GIF with palette
                const secondPassCommand = ffmpeg(videoPath)
                    .input(tempPalettePath)
                    .fps(fps)
                    .videoFilters([
                        `scale=${scale}:flags=lanczos`,
                        `paletteuse=dither=${settings.dither}:bayer_scale=5:diff_mode=rectangle`
                    ])
                    .output(gifPath);

                // Add start time if specified
                if (startTime > 0) {
                    secondPassCommand.seekInput(startTime);
                }

                // Add duration if specified
                if (duration) {
                    secondPassCommand.duration(duration);
                }

                secondPassCommand
                    .on('start', (commandLine) => {
                        console.log('🎨 Creating GIF:', commandLine);
                    })
                    .on('progress', (progress) => {
                        if (progress.percent) {
                            console.log(`📊 GIF progress: ${Math.round(progress.percent)}%`);
                        }
                    })
                    .on('end', () => {
                        // Cleanup palette file
                        if (fs.existsSync(tempPalettePath)) {
                            fs.unlinkSync(tempPalettePath);
                        }

                        const stats = fs.statSync(gifPath);
                        const sizeInMB = (stats.size / 1024 / 1024).toFixed(2);

                        console.log(`✅ GIF created: ${path.basename(gifPath)} (${sizeInMB} MB)`);
                        resolve(gifPath);
                    })
                    .on('error', (err) => {
                        console.error('❌ GIF creation failed:', err);
                        // Cleanup palette file on error
                        if (fs.existsSync(tempPalettePath)) {
                            fs.unlinkSync(tempPalettePath);
                        }
                        reject(err);
                    })
                    .run();
            })
            .on('error', (err) => {
                console.error('❌ Palette generation failed:', err);
                reject(err);
            })
            .run();
    });
}

async function optimizeGif(inputPath, outputPath, options = {}) {
    return new Promise((resolve, reject) => {
        const {
            maxColors = 64,
            fuzz = '2%',
            coalesce = true
        } = options;

        console.log(`🔧 Optimizing GIF: ${path.basename(inputPath)}`);

        let command = ffmpeg(inputPath);

        if (coalesce) {
            command = command.videoFilters([
                `split[s0][s1];[s0]palettegen=max_colors=${maxColors}[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle`
            ]);
        }

        command
            .output(outputPath)
            .on('start', (commandLine) => {
                console.log('🔧 Optimization command:', commandLine);
            })
            .on('progress', (progress) => {
                if (progress.percent) {
                    console.log(`📊 Optimization progress: ${Math.round(progress.percent)}%`);
                }
            })
            .on('end', () => {
                const originalSize = fs.statSync(inputPath).size;
                const optimizedSize = fs.statSync(outputPath).size;
                const reduction = ((originalSize - optimizedSize) / originalSize * 100).toFixed(1);

                console.log(`✅ GIF optimized: ${reduction}% size reduction`);
                resolve(outputPath);
            })
            .on('error', (err) => {
                console.error('❌ GIF optimization failed:', err);
                reject(err);
            })
            .run();
    });
}

async function getVideoInfo(videoPath) {
    return new Promise((resolve, reject) => {
        ffmpeg.ffprobe(videoPath, (err, metadata) => {
            if (err) {
                reject(err);
            } else {
                const videoStream = metadata.streams.find(s => s.codec_type === 'video');
                resolve({
                    duration: metadata.format.duration,
                    width: videoStream.width,
                    height: videoStream.height,
                    fps: eval(videoStream.r_frame_rate),
                    bitrate: metadata.format.bit_rate,
                    size: metadata.format.size
                });
            }
        });
    });
}

module.exports = {
    convertToGif,
    optimizeGif,
    getVideoInfo
};