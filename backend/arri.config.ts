import { defineConfig, servers, generators } from "arri";
import { join } from "path";
import path from 'node:path';

export default defineConfig({
  server: servers.tsServer({
    entry: join(__dirname, "src/app.ts"),
    port: 5000,
  }),
  generators: [
    // Frontend client generation
    generators.dartClient({
      clientName: "ArriClient",
      outputFile: path.resolve(
        __dirname,
        "../frontend/lib/services/arri_client.rpc.dart"
      ),
    }),
  ],
});
