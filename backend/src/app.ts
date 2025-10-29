// Import environment variables first
import '@env';

import { ArriApp } from '@arrirpc/server';

const app = new ArriApp({
    onRequest: (event) => {
        // Add CORS headers
        const origin = event.node.req.headers.origin;
        // Update this list with your frontend origins (exact scheme+host+port)
        const allowedOrigins = [
            'http://localhost:51934',
        ];

        // If you prefer to allow any origin without credentials, set this to true
        const allowAnyOriginWithoutCredentials = false;

        if (allowAnyOriginWithoutCredentials) {
            event.node.res.setHeader('Access-Control-Allow-Origin', '*');
            // Do NOT set Allow-Credentials when using '*'
        } else if (origin && allowedOrigins.includes(origin)) {
            event.node.res.setHeader('Access-Control-Allow-Origin', origin);
            event.node.res.setHeader('Vary', 'Origin');
            event.node.res.setHeader('Access-Control-Allow-Credentials', 'true');
        }

        event.node.res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        event.node.res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        event.node.res.setHeader('Access-Control-Max-Age', '86400');

        // Handle preflight requests
        if (event.node.req.method === 'OPTIONS') {
            event.node.res.statusCode = 204;
            event.node.res.end();
            return;
        }
        
        // const reqId = randomUUID().split('-').join('');
    },
    disableDefinitionRoute: false,
});

export default app;
