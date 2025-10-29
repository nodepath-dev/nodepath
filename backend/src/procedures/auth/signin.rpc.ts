import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { Users } from "@database/schema/users";
import { eq } from "drizzle-orm";
import { verifyPassword, generateToken, sendVerificationEmail } from "./utils";

// User Login/Signin RPC
export const loginUser = defineRpc({
  params: a.object("LoginUserParams", {
    email: a.string(),
    password: a.string(),
    username: a.optional(a.string()),
  }),
  response: a.object("LoginUserResponse", {
    success: a.boolean(),
    message: a.string(),
    token: a.string(),
    userId: a.string(),
    isNewUser: a.boolean(),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Find user by email or username
      let user: any | null = null;
      if (params.email && params.email.trim().length > 0) {
        const usersByEmail = await db
          .select()
          .from(Users)
          .where(eq(Users.email, params.email))
          .limit(1);
        user = usersByEmail[0] ?? null;
      }
      if (!user && params.username && params.username.trim().length > 0) {
        const usersByUsername = await db
          .select()
          .from(Users)
          .where(eq(Users.username, params.username))
          .limit(1);
        user = usersByUsername[0] ?? null;
      }

      if (!user) {
        return {
          success: false,
          message: "Invalid email or password",
          token: "",
          userId: "",
          isNewUser: false,
        };
      }

      // Verify password
      if (!user.password || !verifyPassword(params.password, user.password)) {
        return {
          success: false,
          message: "Invalid email or password",
          token: "",
          userId: "",
          isNewUser: false,
        };
      }

      // Check if email is verified
      if (!user.emailVerified) {
        // Send verification email again
        try {
          await sendVerificationEmail(user.email, user.emailVerificationToken || "");
        } catch (emailError) {
          console.error("Failed to send verification email:", emailError);
        }

        return {
          success: false,
          message: "Please verify your email before signing in. A new verification email has been sent.",
          token: "",
          userId: "",
          isNewUser: false,
        };
      }

      // Update last login time
      await db
        .update(Users)
        .set({ lastLoginAt: new Date() })
        .where(eq(Users.id, user.id));

      // Generate session token
      const token = generateToken(32);

      return {
        success: true,
        message: "Login successful",
        token,
        userId: user.id,
        isNewUser: false,
      };
    } catch (error) {
      console.error("Login error:", error);
      return {
        success: false,
        message: "Login failed. Please try again.",
        token: "",
        userId: "",
        isNewUser: false,
      };
    }
  },
});

export default loginUser;
