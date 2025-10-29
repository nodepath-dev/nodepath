import type { Config } from 'drizzle-kit';
import { config } from '@dotenvx/dotenvx';

// Load environment variables from .env file
config();

const DATABASE_URL = process.env['DATABASE_URL'];

if (!DATABASE_URL) {
    throw new Error('Missing required environment var DATABASE_URL');
}

// import env from './libs/env-vars/src/index';

export default {
    schema: './database/index.ts',
    out: '.drizzle',
    dialect: 'postgresql',
    dbCredentials: {
        url: DATABASE_URL,
    },
} satisfies Config;

