// HireFlow Backend API — server.js
// Team 02 | Sprint #3

const http = require('http');

const FORM_VERSION = process.env.FORM_VERSION || 'v2.4.1';
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');

  // Health check endpoint — used by Kubernetes liveness probe
  if (req.url === '/health' || req.url === '/') {
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'healthy',
      service: 'hireflow-backend',
      version: FORM_VERSION,
      environment: NODE_ENV,
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // Form version endpoint — recruiters use this to check active form
  if (req.url === '/api/form-version') {
    res.writeHead(200);
    res.end(JSON.stringify({
      formVersion: FORM_VERSION,
      message: `Active form schema: ${FORM_VERSION}`
    }));
    return;
  }

  // Applications endpoint (simulated)
  if (req.url === '/api/applications') {
    res.writeHead(200);
    res.end(JSON.stringify({
      formVersion: FORM_VERSION,
      totalApplications: 847,
      message: 'Applications retrieved successfully'
    }));
    return;
  }

  // 404 for unknown routes
  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Route not found' }));
});

server.listen(PORT, () => {
  console.log(`[HireFlow] Server running on port ${PORT}`);
  console.log(`[HireFlow] Environment: ${NODE_ENV}`);
  console.log(`[HireFlow] Form version: ${FORM_VERSION}`);
  console.log(`[HireFlow] Health check: http://localhost:${PORT}/health`);
});