import { config } from '@dotenvx/dotenvx';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load environment variables from .env file in root directory
// The env.ts file is compiled to .output, so we need to go up to the root
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

class Env {
  DATABASE_URL: string;
  SMTP_HOST: string | undefined;
  SMTP_PORT: string | undefined;
  SMTP_USER: string | undefined;
  SMTP_PASS: string | undefined;
  FE_URL: string | undefined;
  FROM_EMAIL: string | undefined;

  constructor() {
    this.DATABASE_URL = process.env['DATABASE_URL']!;
    this.SMTP_HOST = process.env['SMTP_HOST'];
    this.SMTP_PORT = process.env['SMTP_PORT'];
    this.SMTP_USER = process.env['SMTP_USER'];
    this.SMTP_PASS = process.env['SMTP_PASS'];
    this.FE_URL = process.env['FE_URL'];
    this.FROM_EMAIL = process.env['FROM_EMAIL'];

    if (!this.DATABASE_URL) {
      throw new Error('Missing required environment var DATABASE_URL');
    }
  }
}

export const env = new Env();
