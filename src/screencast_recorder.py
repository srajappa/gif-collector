"""
Playwright Screencast Recorder
A comprehensive toolkit for creating automated UI screencasts
"""

import asyncio
import os
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from playwright.async_api import async_playwright, Browser, BrowserContext, Page

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ScreencastRecorder:
    """Base class for creating automated screencasts with Playwright"""
    
    def __init__(
        self,
        output_dir: str = "output/screencasts",
        viewport_size: Tuple[int, int] = None,
        video_format: str = "webm"
    ):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Set viewport size with environment variable fallback
        if viewport_size is None:
            width = int(os.getenv('DEFAULT_VIEWPORT_WIDTH', '1920'))
            height = int(os.getenv('DEFAULT_VIEWPORT_HEIGHT', '1080'))
            self.viewport_size = (width, height)
        else:
            self.viewport_size = viewport_size
            
        self.video_format = video_format
        
        # Playwright instances
        self.playwright = None
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None
        
        # Recording state
        self.recording_name = None
        self.recording_path = None
        
        logger.info(f"Initialized ScreencastRecorder with output: {self.output_dir}")
        logger.info(f"Viewport size: {self.viewport_size}")
    
    async def setup_browser(
        self,
        headless: bool = False,
        slow_mo: int = 1000,
        browser_type: str = "chromium",
        recording_name: Optional[str] = None
    ) -> Page:
        """Initialize browser with video recording capabilities"""
        try:
            logger.info("Setting up browser...")
            
            # Start playwright
            self.playwright = await async_playwright().start()
            
            # Get browser launcher
            browser_launcher = getattr(self.playwright, browser_type)
            
            # Launch browser with recording-optimized settings
            self.browser = await browser_launcher.launch(
                headless=headless,
                slow_mo=slow_mo,
                args=[
                    '--disable-blink-features=AutomationControlled',
                    '--disable-web-security',
                    '--disable-features=VizDisplayCompositor',
                    '--disable-backgrounding-occluded-windows',
                    '--disable-renderer-backgrounding',
                    '--disable-background-timer-throttling',
                    '--disable-dev-shm-usage',
                    '--no-sandbox' if os.getenv('DOCKER_ENV') else ''
                ]
            )
            
            # Create recording path
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            self.recording_name = recording_name or f"screencast_{timestamp}"
            self.recording_path = self.output_dir / self.recording_name
            
            # Ensure viewport size is properly formatted and validated
            viewport_width, viewport_height = self.viewport_size
            
            # Validate viewport dimensions
            if not isinstance(viewport_width, int) or not isinstance(viewport_height, int):
                raise ValueError(f"Invalid viewport dimensions: {self.viewport_size}")
            
            if viewport_width <= 0 or viewport_height <= 0:
                raise ValueError(f"Viewport dimensions must be positive: {self.viewport_size}")
            
            logger.info(f"Using viewport: {viewport_width}x{viewport_height}")
            
            # Create browser context with video recording
            context_options = {
                'viewport': {
                    'width': viewport_width, 
                    'height': viewport_height
                },
                'user_agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
            
            # Only add video recording if we have a valid path
            if self.recording_path:
                context_options['record_video_dir'] = str(self.recording_path)
                context_options['record_video_size'] = {
                    'width': viewport_width,
                    'height': viewport_height
                }
                logger.info(f"Video recording enabled: {self.recording_path}")
            
            self.context = await self.browser.new_context(**context_options)
            
            # Create page
            self.page = await self.context.new_page()
            
            # Set up page event listeners
            await self._setup_page_listeners()
            
            logger.info(f"Browser setup complete. Recording to: {self.recording_path}")
            return self.page
            
        except Exception as e:
            logger.error(f"Failed to setup browser: {e}")
            await self.cleanup()
            raise
    
    async def _setup_page_listeners(self):
        """Set up event listeners for debugging and monitoring"""
        if not self.page:
            return
            
        # Log console messages
        self.page.on('console', lambda msg: logger.debug(f'Console: {msg.text}'))
        
        # Log page errors
        self.page.on('pageerror', lambda error: logger.error(f'Page error: {error}'))
        
        # Log network failures
        self.page.on('requestfailed', lambda request: logger.warning(f'Request failed: {request.url}'))
    
    async def cleanup(self):
        """Clean up browser resources and finalize recording"""
        try:
            logger.info("Cleaning up browser resources...")
            
            if self.context:
                await self.context.close()
                self.context = None
                
            if self.browser:
                await self.browser.close()
                self.browser = None
                
            if self.playwright:
                await self.playwright.stop()
                self.playwright = None
                
            # Log recording location
            if self.recording_path and self.recording_path.exists():
                video_files = list(self.recording_path.glob(f"*.{self.video_format}"))
                if video_files:
                    logger.info(f"Recording saved: {video_files[0]}")
                else:
                    logger.warning(f"No video files found in {self.recording_path}")
                    
        except Exception as e:
            logger.error(f"Error during cleanup: {e}")
    
    async def wait_and_highlight(
        self,
        selector: str,
        duration: int = 2000,
        highlight_color: str = "red",
        background_color: str = "yellow"
    ) -> object:
        """Highlight an element before interacting with it"""
        try:
            logger.debug(f"Highlighting element: {selector}")
            
            # Wait for element to be available
            element = await self.page.wait_for_selector(selector, timeout=10000)
            
            if not element:
                logger.warning(f"Element not found: {selector}")
                return None
            
            # Apply highlight styling
            await element.evaluate(f"""
                element => {{
                    element.style.border = '3px solid {highlight_color}';
                    element.style.backgroundColor = '{background_color}';
                    element.style.opacity = '0.9';
                    element.style.transition = 'all 0.3s ease';
                }}
            """)
            
            # Wait for specified duration
            await self.page.wait_for_timeout(duration)
            
            # Remove highlight
            await element.evaluate("""
                element => {
                    element.style.border = '';
                    element.style.backgroundColor = '';
                    element.style.opacity = '';
                    element.style.transition = '';
                }
            """)
            
            return element
            
        except Exception as e:
            logger.error(f"Failed to highlight element {selector}: {e}")
            return None
    
    async def smooth_scroll(self, pixels: int, duration: int = 1000):
        """Perform smooth scrolling animation"""
        try:
            await self.page.evaluate(f"""
                () => {{
                    window.scrollBy({{
                        top: {pixels},
                        behavior: 'smooth'
                    }});
                }}
            """)
            # Wait for scroll to complete
            await self.page.wait_for_timeout(duration)
            
        except Exception as e:
            logger.error(f"Failed to smooth scroll: {e}")
    
    async def take_screenshot(self, name: str = None) -> str:
        """Take a screenshot and save it"""
        try:
            if not name:
                name = f"screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            
            screenshot_path = self.recording_path / f"{name}.png"
            await self.page.screenshot(path=str(screenshot_path), full_page=True)
            
            logger.info(f"Screenshot saved: {screenshot_path}")
            return str(screenshot_path)
            
        except Exception as e:
            logger.error(f"Failed to take screenshot: {e}")
            return None


class YouTubeScreencast(ScreencastRecorder):
    """Specialized recorder for YouTube interactions"""
    
    async def visit_trending_section(self):
        """Record visiting YouTube trending section"""
        try:
            logger.info("Starting YouTube trending section screencast...")
            
            # Navigate to YouTube
            await self.page.goto('https://www.youtube.com', wait_until='networkidle')
            await self.page.wait_for_timeout(2000)
            
            # Handle potential cookie consent
            try:
                consent_selectors = [
                    '[aria-label*="Accept"]',
                    '[aria-label*="Agree"]',
                    'button:has-text("Accept")',
                    'button:has-text("I agree")',
                    '[data-testid="accept-button"]'
                ]
                
                for selector in consent_selectors:
                    try:
                        consent_button = await self.page.wait_for_selector(selector, timeout=3000)
                        if consent_button:
                            await consent_button.click()
                            await self.page.wait_for_timeout(1000)
                            logger.info("Accepted cookie consent")
                            break
                    except:
                        continue
                        
            except Exception as e:
                logger.debug(f"No cookie consent found or error: {e}")
            
            # Look for trending section with multiple fallback selectors
            trending_selectors = [
                'a[href*="trending"]',
                'a:has-text("Trending")',
                '[aria-label*="Trending"]',
                'yt-formatted-string:has-text("Trending")',
                '[title*="Trending"]'
            ]
            
            trending_element = None
            used_selector = None
            
            for selector in trending_selectors:
                try:
                    trending_element = await self.page.wait_for_selector(selector, timeout=5000)
                    if trending_element:
                        used_selector = selector
                        logger.info(f"Found trending element with selector: {selector}")
                        break
                except:
                    continue
            
            if trending_element and used_selector:
                # Highlight and click trending
                await self.wait_and_highlight(used_selector, duration=2000)
                await trending_element.click()
                await self.page.wait_for_timeout(3000)
                
                # Wait for page to load
                await self.page.wait_for_load_state('networkidle')
                
                # Scroll down to show trending content
                await self.smooth_scroll(400, 1500)
                await self.smooth_scroll(400, 1500)
                await self.smooth_scroll(400, 1500)
                
                # Take a final screenshot
                await self.take_screenshot("trending_final")
                
                logger.info("Successfully recorded YouTube trending section visit!")
                
            else:
                logger.warning("Could not find trending section - recording homepage instead")
                await self.smooth_scroll(300, 1000)
                await self.take_screenshot("youtube_homepage")
                await self.page.wait_for_timeout(3000)
                
        except Exception as e:
            logger.error(f"Error in YouTube trending screencast: {e}")
            raise
    
    async def search_and_play(self, search_term: str):
        """Search for a term and play the first video"""
        try:
            logger.info(f"Searching for: {search_term}")
            
            # Find search box
            search_selectors = [
                'input[name="search_query"]',
                '[aria-label*="Search"]',
                'input[type="search"]'
            ]
            
            search_element = None
            for selector in search_selectors:
                try:
                    search_element = await self.page.wait_for_selector(selector, timeout=5000)
                    if search_element:
                        break
                except:
                    continue
            
            if search_element:
                # Highlight and interact with search
                await self.wait_and_highlight(search_selectors[0])
                await search_element.click()
                await search_element.fill(search_term)
                await self.page.keyboard.press('Enter')
                
                # Wait for results
                await self.page.wait_for_load_state('networkidle')
                await self.page.wait_for_timeout(2000)
                
                # Click first video result
                first_video = await self.page.wait_for_selector('#contents ytd-video-renderer:first-child a', timeout=10000)
                if first_video:
                    await self.wait_and_highlight('#contents ytd-video-renderer:first-child a')
                    await first_video.click()
                    await self.page.wait_for_timeout(5000)
                    
                logger.info(f"Successfully searched and played video for: {search_term}")
                
        except Exception as e:
            logger.error(f"Error in YouTube search: {e}")
            raise


class WebsiteActionRecorder(ScreencastRecorder):
    """Generic recorder for any website with custom actions"""
    
    async def record_custom_action(self, url: str, actions: List[Dict]):
        """
        Record custom actions on any website
        
        Args:
            url: Website URL to visit
            actions: List of action dictionaries with keys:
                - action: 'click', 'type', 'scroll', 'wait', 'highlight', 'screenshot'
                - selector: CSS selector (for click, type, highlight)
                - text: Text to type (for type action)
                - pixels: Scroll pixels (for scroll action)
                - duration: Wait duration in ms (for wait action)
                - name: Screenshot name (for screenshot action)
        """
        try:
            logger.info(f"Starting custom screencast for {url}...")
            
            # Navigate to website
            await self.page.goto(url, wait_until='networkidle')
            await self.page.wait_for_timeout(2000)
            
            # Execute actions sequentially
            for i, action in enumerate(actions):
                action_type = action.get('action', '').lower()
                logger.info(f"Executing action {i+1}/{len(actions)}: {action_type}")
                
                try:
                    if action_type == 'click':
                        selector = action['selector']
                        element = await self.wait_and_highlight(selector)
                        if element:
                            await element.click()
                        
                    elif action_type == 'type':
                        selector = action['selector']
                        text = action['text']
                        element = await self.wait_and_highlight(selector)
                        if element:
                            await element.fill(text)
                        
                    elif action_type == 'scroll':
                        pixels = action.get('pixels', 300)
                        await self.smooth_scroll(pixels)
                        
                    elif action_type == 'wait':
                        duration = action.get('duration', 1000)
                        await self.page.wait_for_timeout(duration)
                        
                    elif action_type == 'highlight':
                        selector = action['selector']
                        duration = action.get('duration', 2000)
                        await self.wait_and_highlight(selector, duration)
                        
                    elif action_type == 'screenshot':
                        name = action.get('name', f'action_{i+1}')
                        await self.take_screenshot(name)
                        
                    elif action_type == 'hover':
                        selector = action['selector']
                        element = await self.page.wait_for_selector(selector)
                        if element:
                            await element.hover()
                            await self.page.wait_for_timeout(1000)
                            
                    elif action_type == 'select':
                        selector = action['selector']
                        value = action['value']
                        await self.page.select_option(selector, value)
                        
                    else:
                        logger.warning(f"Unknown action type: {action_type}")
                    
                    # Small delay between actions for better visibility
                    await self.page.wait_for_timeout(500)
                    
                except Exception as e:
                    logger.error(f"Failed to execute action {i+1} ({action_type}): {e}")
                    continue
            
            logger.info("Custom screencast completed successfully!")
            
        except Exception as e:
            logger.error(f"Error in custom screencast: {e}")
            raise


class EcommerceScreencast(ScreencastRecorder):
    """Specialized recorder for e-commerce interactions"""
    
    async def product_search_and_view(self, site_url: str, search_term: str):
        """Search for a product and view details"""
        try:
            logger.info(f"E-commerce screencast: searching for '{search_term}' on {site_url}")
            
            # Navigate to site
            await self.page.goto(site_url, wait_until='networkidle')
            await self.page.wait_for_timeout(3000)
            
            # Common search selectors for e-commerce sites
            search_selectors = [
                'input[type="search"]',
                'input[name="field-keywords"]',  # Amazon
                'input[data-testid="search-input"]',
                'input[placeholder*="Search"]',
                '#search',
                '.search-input'
            ]
            
            # Find and use search box
            search_element = None
            for selector in search_selectors:
                try:
                    search_element = await self.page.wait_for_selector(selector, timeout=3000)
                    if search_element:
                        await self.wait_and_highlight(selector)
                        await search_element.click()
                        await search_element.fill(search_term)
                        
                        # Try to submit search
                        await self.page.keyboard.press('Enter')
                        break
                except:
                    continue
            
            if search_element:
                # Wait for search results
                await self.page.wait_for_load_state('networkidle')
                await self.page.wait_for_timeout(3000)
                
                # Scroll through results
                await self.smooth_scroll(400, 1500)
                await self.smooth_scroll(400, 1500)
                
                # Try to click first product
                product_selectors = [
                    '[data-testid="product-item"] a:first-child',
                    '.product-item a:first-child',
                    '.s-result-item a',  # Amazon
                    '.product a:first-child'
                ]
                
                for selector in product_selectors:
                    try:
                        product = await self.page.wait_for_selector(selector, timeout=5000)
                        if product:
                            await self.wait_and_highlight(selector)
                            await product.click()
                            await self.page.wait_for_timeout(3000)
                            break
                    except:
                        continue
                
                # Take final screenshot
                await self.take_screenshot("product_details")
                
            logger.info("E-commerce screencast completed!")
            
        except Exception as e:
            logger.error(f"Error in e-commerce screencast: {e}")
            raise


# Utility functions for common operations
async def quick_screencast(url: str, actions: List[Dict], output_name: str = None):
    """Quick utility function to create a screencast"""
    recorder = WebsiteActionRecorder()
    
    try:
        await recorder.setup_browser(
            headless=os.getenv('HEADLESS_MODE', 'false').lower() == 'true',
            recording_name=output_name
        )
        await recorder.record_custom_action(url, actions)
        await recorder.page.wait_for_timeout(2000)  # Extra time at end
        
    finally:
        await recorder.cleanup()


async def test_basic_setup():
    """Test basic browser setup without video recording"""
    logger.info("Testing basic browser setup...")
    
    try:
        # Create a simple recorder
        recorder = ScreencastRecorder()
        
        # Start playwright manually without video recording
        recorder.playwright = await async_playwright().start()
        recorder.browser = await recorder.playwright.chromium.launch(headless=True)
        
        # Test context without video recording
        recorder.context = await recorder.browser.new_context(
            viewport={'width': 1920, 'height': 1080}
        )
        
        recorder.page = await recorder.context.new_page()
        await recorder.page.goto('data:text/html,<h1>Test Page</h1>')
        
        content = await recorder.page.content()
        success = 'Test Page' in content
        
        logger.info(f"Basic setup test: {'SUCCESS' if success else 'FAILED'}")
        return success
        
    except Exception as e:
        logger.error(f"Basic setup test failed: {e}")
        return False
    finally:
        if 'recorder' in locals():
            await recorder.cleanup()


async def test_video_recording():
    """Test video recording setup specifically"""
    logger.info("Testing video recording setup...")
    
    try:
        recorder = ScreencastRecorder()
        
        # Try the normal setup with video recording
        page = await recorder.setup_browser(headless=True, recording_name="test_recording")
        await page.goto('data:text/html,<h1>Video Test</h1>')
        await page.wait_for_timeout(2000)
        
        logger.info("Video recording test: SUCCESS")
        return True
        
    except Exception as e:
        logger.error(f"Video recording test failed: {e}")
        return False
    finally:
        if 'recorder' in locals():
            await recorder.cleanup()


async def test_video_recording():
    """Test video recording setup specifically"""
    logger.info("Testing video recording setup...")
    
    try:
        recorder = ScreencastRecorder()
        
        # Try the normal setup with video recording
        page = await recorder.setup_browser(headless=True, recording_name="test_recording")
        await page.goto('data:text/html,<h1>Video Test</h1>')
        await page.wait_for_timeout(2000)
        
        logger.info("Video recording test: SUCCESS")
        return True
        
    except Exception as e:
        logger.error(f"Video recording test failed: {e}")
        return False
    finally:
        if 'recorder' in locals():
            await recorder.cleanup()


# Example usage functions
async def demo_youtube_trending():
    """Demo: YouTube trending section"""
    recorder = YouTubeScreencast()
    try:
        await recorder.setup_browser(headless=False, recording_name="youtube_trending_demo")
        await recorder.visit_trending_section()
    finally:
        await recorder.cleanup()


async def demo_google_search():
    """Demo: Google search"""
    actions = [
        {'action': 'wait', 'duration': 2000},
        {'action': 'click', 'selector': 'input[name="q"]'},
        {'action': 'type', 'selector': 'input[name="q"]', 'text': 'playwright automation'},
        {'action': 'wait', 'duration': 1000},
        {'action': 'screenshot', 'name': 'search_typed'},
        {'action': 'click', 'selector': 'input[value="Google Search"], input[type="submit"]'},
        {'action': 'wait', 'duration': 3000},
        {'action': 'scroll', 'pixels': 400},
        {'action': 'screenshot', 'name': 'search_results'}
    ]
    
    await quick_screencast('https://www.google.com', actions, 'google_search_demo')


async def demo_ecommerce():
    """Demo: E-commerce product search"""
    recorder = EcommerceScreencast()
    try:
        await recorder.setup_browser(headless=False, recording_name="ecommerce_demo")
        await recorder.product_search_and_view('https://www.amazon.com', 'wireless headphones')
    finally:
        await recorder.cleanup()


# Simple test function for debugging
async def test_basic_setup():
    """Test basic browser setup without video recording"""
    recorder = ScreencastRecorder()
    try:
        logger.info("Testing basic browser setup...")
        
        # First try without video recording
        recorder.playwright = await async_playwright().start()
        recorder.browser = await recorder.playwright.chromium.launch(headless=True)
        
        # Test context without video recording
        recorder.context = await recorder.browser.new_context(
            viewport={'width': 1920, 'height': 1080}
        )
        
        recorder.page = await recorder.context.new_page()
        await recorder.page.goto('data:text/html,<h1>Test</h1>')
        
        logger.info("Basic setup successful!")
        return True
        
    except Exception as e:
        logger.error(f"Basic setup failed: {e}")
        return False
    finally:
        await recorder.cleanup()


if __name__ == "__main__":
    # Example: Run basic test
    asyncio.run(test_basic_setup())