import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { Flows } from "@database/schema/flows";
import { eq } from "drizzle-orm";

// Get Flow by ID RPC
export const getFlow = defineRpc({
  params: a.object("GetFlowParams", {
    flowId: a.string(),
  }),
  response: a.object("GetFlowResponse", {
    success: a.boolean(),
    message: a.string(),
    flow: a.optional(a.any()), // JSON flow data
    flowName: a.optional(a.string()),
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

      // Get flow by ID
      const flow = await db
        .select()
        .from(Flows)
        .where(eq(Flows.id, params.flowId))
        .limit(1);

      if (flow.length === 0) {
        return {
          success: false,
          message: "Flow not found",
        };
      }

      const flowData = flow[0]!;

      return {
        success: true,
        message: "Flow retrieved successfully",
        flow: flowData.flow,
        flowName: flowData.flowName,
      };
    } catch (error) {
      console.error("Get flow error:", error);

      return {
        success: false,
        message: "Failed to retrieve flow. Please try again.",
      };
    }
  },
});

export default getFlow;
