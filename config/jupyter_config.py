"""
Jupyter Lab Configuration for Playwright Screencast Environment
"""

import os

# Basic server configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True

# Security settings
c.ServerApp.token = os.environ.get('JUPYTER_TOKEN', 'docker-screencast-token')
c.ServerApp.password = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True

# Enable JupyterLab interface
c.LabApp.default_url = '/lab'

# Set working directories
c.ServerApp.notebook_dir = '/app/notebooks'
c.ServerApp.root_dir = '/app'

# Logging configuration
c.ServerApp.log_level = 'INFO'
c.ServerApp.log_file = '/app/logs/jupyter.log'

# Enable extensions
c.ServerApp.jpserver_extensions = {
    'jupyterlab': True,
}

# Resource limits
c.ServerApp.max_buffer_size = 268435456  # 256MB
c.ServerApp.iopub_data_rate_limit = 10000000

# Session and kernel management
c.MappingKernelManager.default_kernel_name = 'python3'
c.KernelManager.shutdown_wait_time = 30.0

# Content management
c.ContentsManager.allow_hidden = True
c.FileContentsManager.delete_to_trash = False

# Terminal settings
c.ServerApp.terminals_enabled = True

# Custom settings for Playwright environment
c.LabApp.user_settings_dir = '/home/jupyter/.jupyter/lab/user-settings'
c.LabApp.workspaces_dir = '/home/jupyter/.jupyter/lab/workspaces'