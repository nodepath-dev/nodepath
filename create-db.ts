import { config } from 'dotenv';

// Load environment variables from .env file
config();

const DATABASE_URL = process.env['DATABASE_URL'];

if (!DATABASE_URL) {
    throw new Error('Missing required environment var DATABASE_URL');
}

import postgres from "postgres";

async function main() {
  try {
    console.log('Ensuring database exists...');

    // Parse DATABASE_URL to extract components
    const url = new URL(DATABASE_URL!);
    const host = url.hostname;
    const port = parseInt(url.port);
    const user = url.username;
    const password = url.password;
    const dbName = url.pathname.slice(1); // Remove leading '/'

    // Connect to the default 'postgres' database to create the target database if needed
    const adminClient = postgres({
      host,
      port,
      user,
      password,
      database: 'postgres',
    });

    try {
      // Check if the database exists, and create it if not
      const result = await adminClient`SELECT 1 FROM pg_database WHERE datname = ${dbName}`;
      if (result.length === 0) {
        console.log(`Creating database "${dbName}"...`);
        await adminClient`CREATE DATABASE ${adminClient.unsafe(dbName)}`;
        console.log(`Database "${dbName}" created successfully`);
      } else {
        console.log(`Database "${dbName}" already exists`);
      }
    } finally {
      await adminClient.end();
    }

    console.log('Database setup complete');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();