const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
    reportId: {
        type: String,
        required: true,
        unique: true
    },
    reporter: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    proofOfConcept: {
        type: String,
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    severity: {
        type: Number,
        enum: [1, 2, 3, 4, 5],
        default: null
    },
    reward: {
        type: String,
        default: '0'
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'claimed'],
        default: 'pending'
    },
    txHash: {
        type: String,
        required: true
    }
});

module.exports = mongoose.model('Report', ReportSchema); 