import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "../../../../database/postgres";
import { Flows } from "../../../../database/schema/flows";
import { eq } from "drizzle-orm";

// Flow Update RPC
export const updateFlow = defineRpc({
  params: a.object("UpdateFlowParams", {
    flowId: a.string(),
    flow: a.any(), // JSON flow data
  }),
  response: a.object("UpdateFlowResponse", {
    success: a.boolean(),
    message: a.string(),
    flowId: a.optional(a.string()),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Validate required fields
      if (!params.flowId) {
        return {
          success: false,
          message: "Missing required field: flowId is required",
        };
      }

      // Validate flow data is provided
      if (!params.flow) {
        return {
          success: false,
          message: "Flow data is required",
        };
      }

      // Check if flow exists
      const existingFlow = await db
        .select()
        .from(Flows)
        .where(eq(Flows.id, params.flowId))
        .limit(1);

      if (existingFlow.length === 0) {
        return {
          success: false,
          message: "Flow not found",
        };
      }

      // Prepare update data - only update the flow data
      const updateData = {
        flow: params.flow,
      };

      // Update flow
      await db.update(Flows).set(updateData).where(eq(Flows.id, params.flowId));

      return {
        success: true,
        message: "Flow updated successfully",
        flowId: params.flowId,
      };
    } catch (error) {
      console.error("Flow update error:", error);

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
        message: "Flow update failed. Please try again.",
      };
    }
  },
});

export default updateFlow;
