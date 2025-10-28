import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "../../../../database/postgres";
import { Users } from "../../../../database/schema/users";
import { eq } from "drizzle-orm";
import { hashPassword, isValidEmail, validatePassword } from "./utils";

// Simple ULID-like ID generator (in production, use a proper ULID library like 'ulid')
function generateULID(): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 15);
  return (timestamp + random).padEnd(30, "0").substring(0, 30);
}

// User Registration RPC
export const registerUser = defineRpc({
  params: a.object("RegisterUserParams", {
    email: a.string(),
    username: a.string(),
    password: a.string(),
  }),
  response: a.object("RegisterUserResponse", {
    success: a.boolean(),
    message: a.string(),
  }),
  async handler({ params }) {
    const db = getDrizzle();

    try {
      // Validate email format
      if (!isValidEmail(params.email)) {
        return {
          success: false,
          message: "Invalid email format",
        };
      }

      // Validate password strength
      const passwordValidation = validatePassword(params.password);
      if (!passwordValidation.isValid) {
        return {
          success: false,
          message: `Password validation failed: ${passwordValidation.errors.join(
            ", "
          )}`,
        };
      }

      // Check if email already exists
      const existingEmail = await db
        .select()
        .from(Users)
        .where(eq(Users.email, params.email))
        .limit(1);

      if (existingEmail.length > 0) {
        return {
          success: false,
          message: "Email already exists",
        };
      }

      // Check if username already exists
      const existingUsername = await db
        .select()
        .from(Users)
        .where(eq(Users.username, params.username))
        .limit(1);

      if (existingUsername.length > 0) {
        return {
          success: false,
          message: "Username already exists",
        };
      }

      // Hash password
      const hashedPassword = hashPassword(params.password);

      // Generate ULID
      const userId = generateULID();

      // Create user
      await db.insert(Users).values({
        id: userId,
        email: params.email,
        username: params.username,
        password: hashedPassword,
        emailVerified: false,
      });

      return {
        success: true,
        message: "User registered successfully",
      };
    } catch (error) {
      console.error("Registration error:", error);
      return {
        success: false,
        message: "Registration failed. Please try again.",
      };
    }
  },
});

export default registerUser;
