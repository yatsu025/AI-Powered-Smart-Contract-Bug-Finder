const express = require('express');
const cors = require('cors');
const ethers = require('ethers');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Contract ABI and address
const BugHuntrABI = require('./contracts/BugHuntr.json').abi;
const contractAddress = process.env.CONTRACT_ADDRESS;

// Initialize provider and contract
const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(contractAddress, BugHuntrABI, wallet);

// Routes
app.post('/api/reports', async (req, res) => {
    try {
        const { description, proofOfConcept } = req.body;
        const tx = await contract.submitBugReport(description, proofOfConcept);
        await tx.wait();
        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/reports/:address', async (req, res) => {
    try {
        const { address } = req.params;
        const reports = await contract.getUserReports(address);
        const formattedReports = await Promise.all(reports.map(async (reportId) => {
            const report = await contract.getBugReport(reportId);
            return {
                id: reportId.toString(),
                reporter: report.reporter,
                description: report.description,
                proofOfConcept: report.proofOfConcept,
                timestamp: report.timestamp.toString(),
                severity: report.severity.toString(),
                reward: report.reward.toString(),
                isApproved: report.isApproved,
                isRejected: report.isRejected,
                isClaimed: report.isClaimed
            };
        }));
        res.json(formattedReports);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/reports/:id/approve', async (req, res) => {
    try {
        const { id } = req.params;
        const { severity } = req.body;
        const tx = await contract.approveBugReport(id, severity);
        await tx.wait();
        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/reports/:id/reject', async (req, res) => {
    try {
        const { id } = req.params;
        const tx = await contract.rejectBugReport(id);
        await tx.wait();
        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/reports/:id/claim', async (req, res) => {
    try {
        const { id } = req.params;
        const tx = await contract.claimReward(id);
        await tx.wait();
        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
}); 