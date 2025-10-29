// .arri/__arri_app.ts
import sourceMapSupport from "source-map-support";

// env.ts
import { config } from "@dotenvx/dotenvx";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
var __filename = fileURLToPath(import.meta.url);
var __dirname = dirname(__filename);
config({ path: join(__dirname, "..", ".env") });
var DATABASE_URL = process.env["DATABASE_URL"];
var SMTP_HOST = process.env["SMTP_HOST"];
var SMTP_PORT = process.env["SMTP_PORT"];
var SMTP_USER = process.env["SMTP_USER"];
var SMTP_PASS = process.env["SMTP_PASS"];
var BASE_URL = process.env["BASE_URL"];
if (!DATABASE_URL) {
  throw new Error("Missing required environment var DATABASE_URL");
}

// backend/src/app.ts
import { ArriApp } from "@arrirpc/server";
var app = new ArriApp({
  onRequest: (event) => {
    const origin = event.node.req.headers.origin;
    const allowedOrigins = [
      "http://localhost:51738"
    ];
    const allowAnyOriginWithoutCredentials = false;
    if (allowAnyOriginWithoutCredentials) {
      event.node.res.setHeader("Access-Control-Allow-Origin", "*");
    } else if (origin && allowedOrigins.includes(origin)) {
      event.node.res.setHeader("Access-Control-Allow-Origin", origin);
      event.node.res.setHeader("Vary", "Origin");
      event.node.res.setHeader("Access-Control-Allow-Credentials", "true");
    }
    event.node.res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    event.node.res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
    event.node.res.setHeader("Access-Control-Max-Age", "86400");
    if (event.node.req.method === "OPTIONS") {
      event.node.res.statusCode = 204;
      event.node.res.end();
      return;
    }
  },
  disableDefinitionRoute: false
});
var app_default = app;

// .arri/__arri_app.ts
sourceMapSupport.install();
var arri_app_default = app_default;
export {
  arri_app_default as default
};
//# sourceMappingURL=app.mjs.map
