const express = require('express');
const fs = require('fs');
const path = require('path');
const Joi = require('joi');
const { WebInteractionRecorder } = require('../../recorder/WebInteractionRecorder');

const router = express.Router();
const flowsPath = path.join(__dirname, '../../config/flows.json');

// Validation schemas
const stepSchema = Joi.object({
    action: Joi.string().valid('click', 'type', 'hover', 'scroll', 'wait', 'navigate', 'screenshot', 'select', 'check', 'uncheck', 'keypress', 'drag').required(),
    selector: Joi.string().when('action', {
        is: Joi.string().valid('click', 'type', 'hover', 'select', 'check', 'uncheck'),
        then: Joi.required(),
        otherwise: Joi.optional()
    }),
    value: Joi.alternatives().try(Joi.string(), Joi.number()).optional(),
    description: Joi.string().optional(),
    delay: Joi.number().min(0).max(10000).optional(),
    options: Joi.object().optional()
});

const flowSchema = Joi.object({
    id: Joi.string().required(),
    name: Joi.string().required(),
    description: Joi.string().optional(),
    baseUrl: Joi.string().uri().required(),
    steps: Joi.array().items(stepSchema).min(1).required(),
    options: Joi.object({
        gif: Joi.object({
            fps: Joi.number().min(1).max(30).optional(),
            scale: Joi.string().optional(),
            quality: Joi.string().valid('low', 'medium', 'high').optional()
        }).optional(),
        stepDelay: Joi.number().min(0).max(5000).optional()
    }).optional()
});

// Helper functions
function readFlows() {
    try {
        const data = fs.readFileSync(flowsPath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading flows:', error);
        return { flows: [] };
    }
}

function writeFlows(data) {
    try {
        fs.writeFileSync(flowsPath, JSON.stringify(data, null, 2));
        return true;
    } catch (error) {
        console.error('Error writing flows:', error);
        return false;
    }
}

// Routes

// GET /api/flows - Get all flows
router.get('/', (req, res) => {
    try {
        const data = readFlows();
        res.json({
            success: true,
            flows: data.flows,
            count: data.flows.length
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to read flows'
        });
    }
});

// GET /api/flows/:id - Get specific flow
router.get('/:id', (req, res) => {
    try {
        const data = readFlows();
        const flow = data.flows.find(f => f.id === req.params.id);

        if (!flow) {
            return res.status(404).json({
                success: false,
                error: 'Flow not found'
            });
        }

        res.json({
            success: true,
            flow
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to read flow'
        });
    }
});

// POST /api/flows - Create new flow
router.post('/', (req, res) => {
    try {
        const { error, value } = flowSchema.validate(req.body);

        if (error) {
            return res.status(400).json({
                success: false,
                error: 'Validation failed',
                details: error.details
            });
        }

        const data = readFlows();

        // Check if flow ID already exists
        if (data.flows.find(f => f.id === value.id)) {
            return res.status(409).json({
                success: false,
                error: 'Flow with this ID already exists'
            });
        }

        data.flows.push(value);

        if (!writeFlows(data)) {
            return res.status(500).json({
                success: false,
                error: 'Failed to save flow'
            });
        }

        res.status(201).json({
            success: true,
            flow: value,
            message: 'Flow created successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to create flow'
        });
    }
});

// PUT /api/flows/:id - Update flow
router.put('/:id', (req, res) => {
    try {
        const { error, value } = flowSchema.validate({ ...req.body, id: req.params.id });

        if (error) {
            return res.status(400).json({
                success: false,
                error: 'Validation failed',
                details: error.details
            });
        }

        const data = readFlows();
        const flowIndex = data.flows.findIndex(f => f.id === req.params.id);

        if (flowIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Flow not found'
            });
        }

        data.flows[flowIndex] = value;

        if (!writeFlows(data)) {
            return res.status(500).json({
                success: false,
                error: 'Failed to update flow'
            });
        }

        res.json({
            success: true,
            flow: value,
            message: 'Flow updated successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to update flow'
        });
    }
});

// DELETE /api/flows/:id - Delete flow
router.delete('/:id', (req, res) => {
    try {
        const data = readFlows();
        const flowIndex = data.flows.findIndex(f => f.id === req.params.id);

        if (flowIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Flow not found'
            });
        }

        const deletedFlow = data.flows.splice(flowIndex, 1)[0];

        if (!writeFlows(data)) {
            return res.status(500).json({
                success: false,
                error: 'Failed to delete flow'
            });
        }

        res.json({
            success: true,
            flow: deletedFlow,
            message: 'Flow deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to delete flow'
        });
    }
});

// POST /api/flows/:id/execute - Execute a flow
router.post('/:id/execute', async (req, res) => {
    let recorder = null;

    try {
        const data = readFlows();
        const flow = data.flows.find(f => f.id === req.params.id);

        if (!flow) {
            return res.status(404).json({
                success: false,
                error: 'Flow not found'
            });
        }

        // Initialize recorder
        recorder = new WebInteractionRecorder({
            headless: req.body.headless !== false // Default to true unless explicitly set to false
        });

        await recorder.initialize();

        // Execute the flow
        const result = await recorder.recordUserFlow(flow);

        res.json({
            success: true,
            recording: result,
            message: 'Flow executed successfully'
        });

    } catch (error) {
        console.error('Flow execution error:', error);
        res.status(500).json({
            success: false,
            error: 'Flow execution failed',
            details: error.message
        });
    } finally {
        if (recorder) {
            await recorder.close();
        }
    }
});

// POST /api/flows/validate - Validate flow configuration
router.post('/validate', (req, res) => {
    try {
        const { error, value } = flowSchema.validate(req.body);

        if (error) {
            return res.status(400).json({
                success: false,
                valid: false,
                error: 'Validation failed',
                details: error.details
            });
        }

        res.json({
            success: true,
            valid: true,
            flow: value,
            message: 'Flow configuration is valid'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Validation failed'
        });
    }
});

module.exports = router;