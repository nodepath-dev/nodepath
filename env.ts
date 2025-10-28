import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load environment variables from .env file in root directory
// The env.ts file is compiled to .output, so we need to go up to the root
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

// Export environment variables for use in other modules
export const DATABASE_URL = process.env['DATABASE_URL'];

if (!DATABASE_URL) {
    throw new Error('Missing required environment var DATABASE_URL');
}
