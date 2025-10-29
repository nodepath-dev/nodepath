import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { Users } from "@database/schema/users";
import { eq } from "drizzle-orm";

// Email Verification RPC
export const verifyEmail = defineRpc({
  params: a.object("VerifyEmailParams", {
    token: a.string(),
  }),
  response: a.object("VerifyEmailResponse", {
    success: a.boolean(),
    message: a.string(),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Find user with matching verification token
      const user = await db
        .select()
        .from(Users)
        .where(eq(Users.emailVerificationToken, params.token))
        .limit(1);

      if (user.length === 0) {
        return {
          success: false,
          message: "Invalid or expired verification token",
        };
      }

      // Update user to mark email as verified and clear token
      await db
        .update(Users)
        .set({
          emailVerified: true,
          emailVerificationToken: null,
        })
        .where(eq(Users.id, user[0]!.id));

      return {
        success: true,
        message: "Email verified successfully",
      };
    } catch (error) {
      console.error("Email verification error:", error);
      return {
        success: false,
        message: "Email verification failed. Please try again.",
      };
    }
  },
});

export default verifyEmail;