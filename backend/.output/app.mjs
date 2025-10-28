// .arri/__arri_app.ts
import sourceMapSupport from "source-map-support";

// ../env.ts
import { config } from "dotenv";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
var __filename = fileURLToPath(import.meta.url);
var __dirname = dirname(__filename);
config({ path: join(__dirname, "..", "..", ".env") });
var DATABASE_URL = process.env["DATABASE_URL"];
if (!DATABASE_URL) {
  throw new Error("Missing required environment var DATABASE_URL");
}

// src/app.ts
import { ArriApp } from "@arrirpc/server";
var app = new ArriApp({
  onRequest: (event) => {
    const origin = event.node.req.headers.origin;
    const allowedOrigins = [
      "http://localhost:63600",
      "http://localhost:50182",
      "http://192.168.141.133:3000"
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

// src/procedures/auth/signin.rpc.ts
import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";

// ../database/postgres.ts
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
var db;
var client;
function getDrizzle() {
  if (db) return db;
  if (!client) {
    client = postgres(DATABASE_URL);
  }
  db = drizzle(client);
  return db;
}

// ../database/schema/users.ts
import {
  timestamp as timestamp3,
  pgTable as pgTable2,
  varchar as varchar3,
  boolean as boolean2,
  text as text2
} from "drizzle-orm/pg-core";
import { relations as relations2 } from "drizzle-orm";

// ../database/schema/common.ts
import { timestamp, varchar } from "drizzle-orm/pg-core";
var ulidField = (name) => varchar(name, { length: 36 });
var defaultDateFields = {
  createdAt: timestamp("created_at", { mode: "date" }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { mode: "date" }).notNull().$onUpdate(() => /* @__PURE__ */ new Date()).defaultNow()
};

// ../database/schema/flows.ts
import {
  pgTable,
  varchar as varchar2,
  json
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
var Flows = pgTable("flows", {
  ...defaultDateFields,
  id: ulidField("id").notNull().primaryKey(),
  userId: ulidField("user_id").notNull().references(() => Users.id),
  flowName: varchar2("flow_name", { length: 255 }).notNull(),
  flow: json("flow").notNull()
});
var flowsRelations = relations(Flows, ({ one }) => ({
  user: one(Users, {
    fields: [Flows.userId],
    references: [Users.id]
  })
}));

// ../database/schema/users.ts
var Users = pgTable2("users", {
  ...defaultDateFields,
  id: ulidField("id").notNull().primaryKey(),
  email: varchar3("email", { length: 255 }).notNull().unique(),
  username: varchar3("username", { length: 100 }).notNull().unique(),
  avatar: text2("avatar"),
  password: varchar3("password", { length: 255 }),
  emailVerified: boolean2("email_verified").default(false),
  lastLoginAt: timestamp3("last_login_at")
});
var usersRelations = relations2(Users, ({ many }) => ({
  flows: many(Flows)
}));

// src/procedures/auth/signin.rpc.ts
import { eq } from "drizzle-orm";

// src/procedures/auth/utils.ts
import { createHash, randomBytes } from "crypto";
function hashPassword(password) {
  const salt = randomBytes(16).toString("hex");
  const hash = createHash("sha256").update(password + salt).digest("hex");
  return `${salt}:${hash}`;
}
function verifyPassword(password, hashedPassword) {
  const [salt, hash] = hashedPassword.split(":");
  if (!salt || !hash) return false;
  const computedHash = createHash("sha256").update(password + salt).digest("hex");
  return computedHash === hash;
}
function generateToken(length = 32) {
  return randomBytes(length).toString("hex");
}
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
function validatePassword(password) {
  const errors = [];
  if (password.length < 8) {
    errors.push("Password must be at least 8 characters long");
  }
  if (!/[A-Z]/.test(password)) {
    errors.push("Password must contain at least one uppercase letter");
  }
  if (!/[a-z]/.test(password)) {
    errors.push("Password must contain at least one lowercase letter");
  }
  if (!/\d/.test(password)) {
    errors.push("Password must contain at least one number");
  }
  return {
    isValid: errors.length === 0,
    errors
  };
}

// src/procedures/auth/signin.rpc.ts
var loginUser = defineRpc({
  params: a.object("LoginUserParams", {
    email: a.string(),
    password: a.string(),
    username: a.optional(a.string())
  }),
  response: a.object("LoginUserResponse", {
    success: a.boolean(),
    message: a.string(),
    token: a.string(),
    userId: a.string(),
    isNewUser: a.boolean()
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      let user = null;
      if (params.email && params.email.trim().length > 0) {
        const usersByEmail = await db2.select().from(Users).where(eq(Users.email, params.email)).limit(1);
        user = usersByEmail[0] ?? null;
      }
      if (!user && params.username && params.username.trim().length > 0) {
        const usersByUsername = await db2.select().from(Users).where(eq(Users.username, params.username)).limit(1);
        user = usersByUsername[0] ?? null;
      }
      if (!user) {
        return {
          success: false,
          message: "Invalid email or password",
          token: "",
          userId: "",
          isNewUser: false
        };
      }
      if (!user.password || !verifyPassword(params.password, user.password)) {
        return {
          success: false,
          message: "Invalid email or password",
          token: "",
          userId: "",
          isNewUser: false
        };
      }
      await db2.update(Users).set({ lastLoginAt: /* @__PURE__ */ new Date() }).where(eq(Users.id, user.id));
      const token = generateToken(32);
      return {
        success: true,
        message: "Login successful",
        token,
        userId: user.id,
        isNewUser: false
      };
    } catch (error) {
      console.error("Login error:", error);
      return {
        success: false,
        message: "Login failed. Please try again.",
        token: "",
        userId: "",
        isNewUser: false
      };
    }
  }
});
var signin_rpc_default = loginUser;

// src/procedures/auth/signup.rpc.ts
import { a as a2 } from "@arrirpc/schema";
import { defineRpc as defineRpc2 } from "@arrirpc/server";
import { eq as eq2 } from "drizzle-orm";
function generateULID() {
  const timestamp4 = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 15);
  return (timestamp4 + random).padEnd(30, "0").substring(0, 30);
}
var registerUser = defineRpc2({
  params: a2.object("RegisterUserParams", {
    email: a2.string(),
    username: a2.string(),
    password: a2.string()
  }),
  response: a2.object("RegisterUserResponse", {
    success: a2.boolean(),
    message: a2.string()
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      if (!isValidEmail(params.email)) {
        return {
          success: false,
          message: "Invalid email format"
        };
      }
      const passwordValidation = validatePassword(params.password);
      if (!passwordValidation.isValid) {
        return {
          success: false,
          message: `Password validation failed: ${passwordValidation.errors.join(", ")}`
        };
      }
      const existingEmail = await db2.select().from(Users).where(eq2(Users.email, params.email)).limit(1);
      if (existingEmail.length > 0) {
        return {
          success: false,
          message: "Email already exists"
        };
      }
      const existingUsername = await db2.select().from(Users).where(eq2(Users.username, params.username)).limit(1);
      if (existingUsername.length > 0) {
        return {
          success: false,
          message: "Username already exists"
        };
      }
      const hashedPassword = hashPassword(params.password);
      const userId = generateULID();
      await db2.insert(Users).values({
        id: userId,
        email: params.email,
        username: params.username,
        password: hashedPassword,
        emailVerified: false
      });
      return {
        success: true,
        message: "User registered successfully"
      };
    } catch (error) {
      console.error("Registration error:", error);
      return {
        success: false,
        message: "Registration failed. Please try again."
      };
    }
  }
});
var signup_rpc_default = registerUser;

// src/procedures/flows/createFlow.rpc.ts
import { a as a3 } from "@arrirpc/schema";
import { defineRpc as defineRpc3 } from "@arrirpc/server";
import { eq as eq3 } from "drizzle-orm";
import { v4 as uuid } from "uuid";
var createFlow = defineRpc3({
  params: a3.object("CreateFlowParams", {
    userId: a3.string(),
    flowName: a3.string(),
    flow: a3.any()
    // JSON flow data
  }),
  response: a3.object("CreateFlowResponse", {
    success: a3.boolean(),
    message: a3.string(),
    flowId: a3.optional(a3.string())
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      if (!params.userId || !params.flowName || !params.flow) {
        return {
          success: false,
          message: "Missing required fields: userId, flowName, and flow are required"
        };
      }
      if (params.flowName.length > 255) {
        return {
          success: false,
          message: "Flow name must be 255 characters or less"
        };
      }
      const existingUser = await db2.select().from(Users).where(eq3(Users.id, params.userId)).limit(1);
      if (existingUser.length === 0) {
        return {
          success: false,
          message: "User not found"
        };
      }
      const flowId = uuid();
      await db2.insert(Flows).values({
        id: flowId,
        userId: params.userId,
        flowName: params.flowName,
        flow: params.flow
      });
      return {
        success: true,
        message: "Flow created successfully",
        flowId
      };
    } catch (error) {
      console.error("Flow creation error:", error);
      if (error instanceof Error) {
        if (error.message.includes("unique constraint")) {
          return {
            success: false,
            message: "A flow with this data already exists"
          };
        }
      }
      return {
        success: false,
        message: "Flow creation failed. Please try again."
      };
    }
  }
});
var createFlow_rpc_default = createFlow;

// src/procedures/flows/getFlow.rpc.ts
import { a as a4 } from "@arrirpc/schema";
import { defineRpc as defineRpc4 } from "@arrirpc/server";
import { eq as eq4 } from "drizzle-orm";
var getFlow = defineRpc4({
  params: a4.object("GetFlowParams", {
    flowId: a4.string()
  }),
  response: a4.object("GetFlowResponse", {
    success: a4.boolean(),
    message: a4.string(),
    flow: a4.optional(a4.any()),
    // JSON flow data
    flowName: a4.optional(a4.string())
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      if (!params.flowId) {
        return {
          success: false,
          message: "Missing required field: flowId is required"
        };
      }
      const flow = await db2.select().from(Flows).where(eq4(Flows.id, params.flowId)).limit(1);
      if (flow.length === 0) {
        return {
          success: false,
          message: "Flow not found"
        };
      }
      const flowData = flow[0];
      return {
        success: true,
        message: "Flow retrieved successfully",
        flow: flowData.flow,
        flowName: flowData.flowName
      };
    } catch (error) {
      console.error("Get flow error:", error);
      return {
        success: false,
        message: "Failed to retrieve flow. Please try again."
      };
    }
  }
});
var getFlow_rpc_default = getFlow;

// src/procedures/flows/listFlows.rpc.ts
import { a as a5 } from "@arrirpc/schema";
import { defineRpc as defineRpc5 } from "@arrirpc/server";
import { eq as eq5, desc } from "drizzle-orm";
var listFlows = defineRpc5({
  params: a5.object("ListFlowsParams", {
    userId: a5.string()
  }),
  response: a5.object("ListFlowsResponse", {
    success: a5.boolean(),
    message: a5.string(),
    flows: a5.array(a5.object("FlowItem", {
      id: a5.string(),
      flowName: a5.string(),
      createdAt: a5.string(),
      updatedAt: a5.string()
    }))
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      if (!params.userId) {
        return {
          success: false,
          message: "Missing required field: userId is required",
          flows: []
        };
      }
      const existingUser = await db2.select().from(Users).where(eq5(Users.id, params.userId)).limit(1);
      if (existingUser.length === 0) {
        return {
          success: false,
          message: "User not found",
          flows: []
        };
      }
      const userFlows = await db2.select({
        id: Flows.id,
        flowName: Flows.flowName,
        createdAt: Flows.createdAt,
        updatedAt: Flows.updatedAt
      }).from(Flows).where(eq5(Flows.userId, params.userId)).orderBy(desc(Flows.updatedAt));
      return {
        success: true,
        message: "Flows retrieved successfully",
        flows: userFlows.map((flow) => ({
          id: flow.id,
          flowName: flow.flowName,
          createdAt: flow.createdAt.toISOString(),
          updatedAt: flow.updatedAt.toISOString()
        }))
      };
    } catch (error) {
      console.error("Flow listing error:", error);
      return {
        success: false,
        message: "Failed to retrieve flows. Please try again.",
        flows: []
      };
    }
  }
});
var listFlows_rpc_default = listFlows;

// src/procedures/flows/updateFlow.rpc.ts
import { a as a6 } from "@arrirpc/schema";
import { defineRpc as defineRpc6 } from "@arrirpc/server";
import { eq as eq6 } from "drizzle-orm";
var updateFlow = defineRpc6({
  params: a6.object("UpdateFlowParams", {
    flowId: a6.string(),
    flow: a6.any()
    // JSON flow data
  }),
  response: a6.object("UpdateFlowResponse", {
    success: a6.boolean(),
    message: a6.string(),
    flowId: a6.optional(a6.string())
  }),
  async handler({ params }) {
    const db2 = getDrizzle();
    try {
      if (!params.flowId) {
        return {
          success: false,
          message: "Missing required field: flowId is required"
        };
      }
      if (!params.flow) {
        return {
          success: false,
          message: "Flow data is required"
        };
      }
      const existingFlow = await db2.select().from(Flows).where(eq6(Flows.id, params.flowId)).limit(1);
      if (existingFlow.length === 0) {
        return {
          success: false,
          message: "Flow not found"
        };
      }
      const updateData = {
        flow: params.flow
      };
      await db2.update(Flows).set(updateData).where(eq6(Flows.id, params.flowId));
      return {
        success: true,
        message: "Flow updated successfully",
        flowId: params.flowId
      };
    } catch (error) {
      console.error("Flow update error:", error);
      if (error instanceof Error) {
        if (error.message.includes("unique constraint")) {
          return {
            success: false,
            message: "A flow with this data already exists"
          };
        }
      }
      return {
        success: false,
        message: "Flow update failed. Please try again."
      };
    }
  }
});
var updateFlow_rpc_default = updateFlow;

// .arri/__arri_app.ts
sourceMapSupport.install();
app_default.rpc("auth.signin", signin_rpc_default);
app_default.rpc("auth.signup", signup_rpc_default);
app_default.rpc("flows.createFlow", createFlow_rpc_default);
app_default.rpc("flows.getFlow", getFlow_rpc_default);
app_default.rpc("flows.listFlows", listFlows_rpc_default);
app_default.rpc("flows.updateFlow", updateFlow_rpc_default);
var arri_app_default = app_default;
export {
  arri_app_default as default
};
//# sourceMappingURL=app.mjs.map
