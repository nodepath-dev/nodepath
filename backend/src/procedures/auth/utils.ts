import { createHash, randomBytes } from 'crypto';
import nodemailer from "nodemailer";
import { env } from "@env";

/**
 * Generate a simple ULID-like ID (in production, use a proper ULID library like 'ulid')
 * @returns A unique identifier string
 */
export function generateULID(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 15);
    return (timestamp + random).padEnd(30, '0').substring(0, 30);
}

/**
 * Hash a password using SHA-256 with salt
 * @param password - The plain text password
 * @returns The hashed password with salt
 */
export function hashPassword(password: string): string {
    const salt = randomBytes(16).toString('hex');
    const hash = createHash('sha256').update(password + salt).digest('hex');
    return `${salt}:${hash}`;
}

/**
 * Verify a password against a hashed password
 * @param password - The plain text password to verify
 * @param hashedPassword - The hashed password to check against
 * @returns True if password matches, false otherwise
 */
export function verifyPassword(password: string, hashedPassword: string): boolean {
    const [salt, hash] = hashedPassword.split(':');
    if (!salt || !hash) return false;
    
    const computedHash = createHash('sha256').update(password + salt).digest('hex');
    return computedHash === hash;
}

/**
 * Generate a random token for email verification or password reset
 * @param length - Length of the token (default: 32)
 * @returns Random token string
 */
export function generateToken(length: number = 32): string {
    return randomBytes(length).toString('hex');
}

/**
 * Validate email format
 * @param email - Email to validate
 * @returns True if email is valid, false otherwise
 */
export function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Validate password strength
 * @param password - Password to validate
 * @returns Object with isValid boolean and errors array
 */
export function validatePassword(password: string): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (password.length < 8) {
        errors.push('Password must be at least 8 characters long');
    }

    if (!/[A-Z]/.test(password)) {
        errors.push('Password must contain at least one uppercase letter');
    }

    if (!/[a-z]/.test(password)) {
        errors.push('Password must contain at least one lowercase letter');
    }

    if (!/\d/.test(password)) {
        errors.push('Password must contain at least one number');
    }

    return {
        isValid: errors.length === 0,
        errors
    };
}

/**
 * Send verification email to user
 * @param email - User's email address
 * @param token - Verification token
 */
export async function sendVerificationEmail(
    email: string,
    token: string
): Promise<void> {
    const transporter = nodemailer.createTransport({
        host: env.SMTP_HOST,
        port: parseInt(env.SMTP_PORT || "587"),
        secure: false, // true for 465, false for other ports
        auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
        },
    });

    const verificationUrl = `${env.FE_URL}/?token=${token}`;

    const mailOptions = {
        from: `"Node Path" <${env.FROM_EMAIL}>`, // 👈 display name added
        to: email,
        subject: "Verify Your Email Address",
        html: `
            <h1>Welcome!</h1>
            <p>Please click the link below to verify your email address:</p>
            <a href="${verificationUrl}">Verify Email</a>
            <p>If you didn't create an account, please ignore this email.</p>
        `,
    };

    await transporter.sendMail(mailOptions);
}
