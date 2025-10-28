import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "../../../../database/postgres";
import { Flows } from "../../../../database/schema/flows";
import { Users } from "../../../../database/schema/users";
import { eq } from "drizzle-orm";
import { v4 as uuid } from "uuid";

// Flow Creation RPC
export const createFlow = defineRpc({
  params: a.object("CreateFlowParams", {
    userId: a.string(),
    flowName: a.string(),
    flow: a.any(), // JSON flow data
  }),
  response: a.object("CreateFlowResponse", {
    success: a.boolean(),
    message: a.string(),
    flowId: a.optional(a.string()),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Validate required fields
      if (!params.userId || !params.flowName || !params.flow) {
        return {
          success: false,
          message:
            "Missing required fields: userId, flowName, and flow are required",
        };
      }

      // Validate flow name length
      if (params.flowName.length > 255) {
        return {
          success: false,
          message: "Flow name must be 255 characters or less",
        };
      }

      // Check if user exists
      const existingUser = await db
        .select()
        .from(Users)
        .where(eq(Users.id, params.userId))
        .limit(1);

      if (existingUser.length === 0) {
        return {
          success: false,
          message: "User not found",
        };
      }

      // Generate UUID for the flow
      const flowId = uuid();

      // Create flow
      await db.insert(Flows).values({
        id: flowId,
        userId: params.userId,
        flowName: params.flowName,
        flow: params.flow,
      });

      return {
        success: true,
        message: "Flow created successfully",
        flowId: flowId,
      };
    } catch (error) {
      console.error("Flow creation error:", error);

      // Handle specific database errors
      if (error instanceof Error) {
        if (error.message.includes("unique constraint")) {
          return {
            success: false,
            message: "A flow with this data already exists",
          };
        }
      }

      return {
        success: false,
        message: "Flow creation failed. Please try again.",
      };
    }
  },
});

export default createFlow;
