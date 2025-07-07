"""
Test suite for Playwright Screencast Recorder
"""

import pytest
import asyncio
import tempfile
import shutil
from pathlib import Path
from unittest.mock import AsyncMock, patch

# Import the modules to test
import sys
sys.path.append('/app')
from src.screencast_recorder import (
    ScreencastRecorder,
    YouTubeScreencast,
    WebsiteActionRecorder,
    EcommerceScreencast
)


class TestScreencastRecorder:
    """Test cases for base ScreencastRecorder class"""
    
    @pytest.fixture
    def temp_output_dir(self):
        """Create a temporary output directory for tests"""
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)
    
    @pytest.fixture
    def recorder(self, temp_output_dir):
        """Create a ScreencastRecorder instance for testing"""
        return ScreencastRecorder(output_dir=temp_output_dir)
    
    def test_init(self, recorder, temp_output_dir):
        """Test recorder initialization"""
        assert recorder.output_dir == Path(temp_output_dir)
        assert recorder.viewport_size == (1920, 1080)
        assert recorder.video_format == "webm"
        assert recorder.browser is None
        assert recorder.context is None
        assert recorder.page is None
    
    def test_custom_viewport(self, temp_output_dir):
        """Test recorder with custom viewport size"""
        recorder = ScreencastRecorder(
            output_dir=temp_output_dir,
            viewport_size=(1280, 720)
        )
        assert recorder.viewport_size == (1280, 720)
    
    @pytest.mark.asyncio
    async def test_cleanup_when_not_initialized(self, recorder):
        """Test cleanup when browser is not initialized"""
        # Should not raise any exceptions
        await recorder.cleanup()
    
    def test_output_directory_creation(self, temp_output_dir):
        """Test that output directory is created"""
        # Remove the directory
        shutil.rmtree(temp_output_dir)
        assert not Path(temp_output_dir).exists()
        
        # Create recorder - should recreate directory
        recorder = ScreencastRecorder(output_dir=temp_output_dir)
        assert Path(temp_output_dir).exists()


class TestWebsiteActionRecorder:
    """Test cases for WebsiteActionRecorder class"""
    
    @pytest.fixture
    def temp_output_dir(self):
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)
    
    @pytest.fixture
    def recorder(self, temp_output_dir):
        return WebsiteActionRecorder(output_dir=temp_output_dir)
    
    def test_init(self, recorder):
        """Test WebsiteActionRecorder initialization"""
        assert isinstance(recorder, ScreencastRecorder)
    
    @pytest.mark.asyncio
    async def test_record_custom_action_with_mock(self, recorder):
        """Test record_custom_action with mocked browser"""
        # Mock the browser setup
        mock_page = AsyncMock()
        recorder.page = mock_page
        
        actions = [
            {'action': 'wait', 'duration': 1000},
            {'action': 'scroll', 'pixels': 300}
        ]
        
        with patch.object(recorder, 'smooth_scroll', new_callable=AsyncMock) as mock_scroll:
            await recorder.record_custom_action('https://example.com', actions)
            
            # Verify page.goto was called
            mock_page.goto.assert_called_once_with('https://example.com', wait_until='networkidle')
            
            # Verify wait_for_timeout was called
            assert mock_page.wait_for_timeout.call_count >= 2
            
            # Verify smooth_scroll was called
            mock_scroll.assert_called_once_with(300)


class TestYouTubeScreencast:
    """Test cases for YouTubeScreencast class"""
    
    @pytest.fixture
    def temp_output_dir(self):
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)
    
    @pytest.fixture
    def recorder(self, temp_output_dir):
        return YouTubeScreencast(output_dir=temp_output_dir)
    
    def test_init(self, recorder):
        """Test YouTubeScreencast initialization"""
        assert isinstance(recorder, ScreencastRecorder)
    
    @pytest.mark.asyncio
    async def test_visit_trending_section_with_mock(self, recorder):
        """Test visit_trending_section with mocked browser"""
        mock_page = AsyncMock()
        recorder.page = mock_page
        
        # Mock finding trending element
        mock_element = AsyncMock()
        mock_page.wait_for_selector.return_value = mock_element
        
        with patch.object(recorder, 'wait_and_highlight', new_callable=AsyncMock) as mock_highlight, \
             patch.object(recorder, 'smooth_scroll', new_callable=AsyncMock) as mock_scroll, \
             patch.object(recorder, 'take_screenshot', new_callable=AsyncMock) as mock_screenshot:
            
            await recorder.visit_trending_section()
            
            # Verify YouTube was visited
            mock_page.goto.assert_called_once_with('https://www.youtube.com', wait_until='networkidle')
            
            # Verify trending element was highlighted and clicked
            mock_highlight.assert_called()
            mock_element.click.assert_called_once()
            
            # Verify scrolling occurred
            assert mock_scroll.call_count >= 3
            
            # Verify screenshot was taken
            mock_screenshot.assert_called_once_with("trending_final")


class TestEcommerceScreencast:
    """Test cases for EcommerceScreencast class"""
    
    @pytest.fixture
    def temp_output_dir(self):
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)
    
    @pytest.fixture
    def recorder(self, temp_output_dir):
        return EcommerceScreencast(output_dir=temp_output_dir)
    
    def test_init(self, recorder):
        """Test EcommerceScreencast initialization"""
        assert isinstance(recorder, ScreencastRecorder)
    
    @pytest.mark.asyncio
    async def test_product_search_with_mock(self, recorder):
        """Test product_search_and_view with mocked browser"""
        mock_page = AsyncMock()
        recorder.page = mock_page
        
        # Mock search element
        mock_search = AsyncMock()
        mock_page.wait_for_selector.return_value = mock_search
        
        with patch.object(recorder, 'wait_and_highlight', new_callable=AsyncMock) as mock_highlight, \
             patch.object(recorder, 'smooth_scroll', new_callable=AsyncMock) as mock_scroll, \
             patch.object(recorder, 'take_screenshot', new_callable=AsyncMock) as mock_screenshot:
            
            await recorder.product_search_and_view('https://example-shop.com', 'test product')
            
            # Verify site was visited
            mock_page.goto.assert_called_once_with('https://example-shop.com', wait_until='networkidle')
            
            # Verify search was performed
            mock_search.click.assert_called()
            mock_search.fill.assert_called_with('test product')
            
            # Verify screenshot was taken
            mock_screenshot.assert_called_once_with("product_details")


class TestIntegration:
    """Integration tests that might require actual browser instances"""
    
    @pytest.mark.slow
    @pytest.mark.asyncio
    async def test_basic_browser_setup(self):
        """Test actual browser setup (slow test)"""
        with tempfile.TemporaryDirectory() as temp_dir:
            recorder = ScreencastRecorder(output_dir=temp_dir)
            
            try:
                # This will actually launch a browser
                page = await recorder.setup_browser(headless=True, slow_mo=0)
                assert page is not None
                assert recorder.browser is not None
                assert recorder.context is not None
                
                # Navigate to a simple page
                await page.goto('data:text/html,<h1>Test Page</h1>')
                assert 'Test Page' in await page.content()
                
            finally:
                await recorder.cleanup()
    
    @pytest.mark.slow
    @pytest.mark.asyncio
    async def test_screenshot_functionality(self):
        """Test screenshot taking functionality"""
        with tempfile.TemporaryDirectory() as temp_dir:
            recorder = ScreencastRecorder(output_dir=temp_dir)
            
            try:
                await recorder.setup_browser(headless=True, slow_mo=0)
                await recorder.page.goto('data:text/html,<h1>Screenshot Test</h1>')
                
                screenshot_path = await recorder.take_screenshot('test_screenshot')
                assert screenshot_path is not None
                assert Path(screenshot_path).exists()
                
            finally:
                await recorder.cleanup()


# Test fixtures and utilities
@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


# Pytest configuration
def pytest_configure(config):
    """Configure pytest with custom markers"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )


if __name__ == "__main__":
    # Run tests when script is executed directly
    pytest.main([__file__, "-v"])