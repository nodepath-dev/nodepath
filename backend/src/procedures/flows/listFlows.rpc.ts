import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { Flows } from "@database/schema/flows";
import { Users } from "@database/schema/users";
import { eq, desc } from "drizzle-orm";

// Flow List RPC
export const listFlows = defineRpc({
  params: a.object("ListFlowsParams", {
    userId: a.string(),
  }),
  response: a.object("ListFlowsResponse", {
    success: a.boolean(),
    message: a.string(),
    flows: a.array(
      a.object("FlowItem", {
        id: a.string(),
        flowName: a.string(),
        createdAt: a.string(),
        updatedAt: a.string(),
      })
    ),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Validate required fields
      if (!params.userId) {
        return {
          success: false,
          message: "Missing required field: userId is required",
          flows: [],
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
          flows: [],
        };
      }

      // Get flows for the user, ordered by most recent first
      const userFlows = await db
        .select({
          id: Flows.id,
          flowName: Flows.flowName,
          createdAt: Flows.createdAt,
          updatedAt: Flows.updatedAt,
        })
        .from(Flows)
        .where(eq(Flows.userId, params.userId))
        .orderBy(desc(Flows.updatedAt));

      return {
        success: true,
        message: "Flows retrieved successfully",
        flows: userFlows.map((flow) => ({
          id: flow.id,
          flowName: flow.flowName,
          createdAt: flow.createdAt.toISOString(),
          updatedAt: flow.updatedAt.toISOString(),
        })),
      };
    } catch (error) {
      console.error("Flow listing error:", error);

      return {
        success: false,
        message: "Failed to retrieve flows. Please try again.",
        flows: [],
      };
    }
  },
});

export default listFlows;
