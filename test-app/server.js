const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Mock user data
let users = [
    { id: 1, email: 'demo@example.com', password: 'demo123', name: 'Demo User' },
    { id: 2, email: 'test@example.com', password: 'test123', name: 'Test User' }
];

let items = [
    { id: 1, name: 'Sample Item 1', category: 'important', description: 'This is a sample item', public: true, userId: 1 },
    { id: 2, name: 'Sample Item 2', category: 'normal', description: 'Another sample item', public: false, userId: 1 }
];

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Home page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/index.html'));
});

// Login page
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/login.html'));
});

// Dashboard page
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/dashboard.html'));
});

// API Routes

// Login endpoint
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    const user = users.find(u => u.email === email && u.password === password);

    if (user) {
        res.json({
            success: true,
            user: { id: user.id, email: user.email, name: user.name },
            token: 'mock-jwt-token'
        });
    } else {
        res.status(401).json({
            success: false,
            error: 'Invalid credentials'
        });
    }
});

// Get user items
app.get('/api/items', (req, res) => {
    // Simulate authentication check
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    res.json({
        success: true,
        items: items
    });
});

// Create new item
app.post('/api/items', (req, res) => {
    const { name, category, description, public: isPublic } = req.body;

    const newItem = {
        id: items.length + 1,
        name,
        category,
        description,
        public: isPublic,
        userId: 1, // Mock user ID
        createdAt: new Date().toISOString()
    };

    items.push(newItem);

    res.status(201).json({
        success: true,
        item: newItem
    });
});

// Update item
app.put('/api/items/:id', (req, res) => {
    const itemId = parseInt(req.params.id);
    const itemIndex = items.findIndex(item => item.id === itemId);

    if (itemIndex === -1) {
        return res.status(404).json({
            success: false,
            error: 'Item not found'
        });
    }

    items[itemIndex] = { ...items[itemIndex], ...req.body };

    res.json({
        success: true,
        item: items[itemIndex]
    });
});

// Delete item
app.delete('/api/items/:id', (req, res) => {
    const itemId = parseInt(req.params.id);
    const itemIndex = items.findIndex(item => item.id === itemId);

    if (itemIndex === -1) {
        return res.status(404).json({
            success: false,
            error: 'Item not found'
        });
    }

    const deletedItem = items.splice(itemIndex, 1)[0];

    res.json({
        success: true,
        item: deletedItem
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).sendFile(path.join(__dirname, 'public/404.html'));
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🎯 Test App running on port ${PORT}`);
    console.log(`📱 Access at: http://localhost:${PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/health`);
});