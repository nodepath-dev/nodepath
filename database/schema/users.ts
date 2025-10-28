import {
  timestamp,
  pgTable,
  varchar,
  boolean,
  text,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
//
import { defaultDateFields, ulidField } from "./common";
import { Flows } from "./flows";

export const Users = pgTable("users", {
  ...defaultDateFields,
  id: ulidField("id").notNull().primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  username: varchar("username", { length: 100 }).notNull().unique(),
  avatar: text("avatar"),
  password: varchar("password", { length: 255 }),
  emailVerified: boolean("email_verified").default(false),
  lastLoginAt: timestamp("last_login_at"),
});

// Define relations
export const usersRelations = relations(Users, ({ many }) => ({
  flows: many(Flows),
}));

export type NewUser = typeof Users.$inferInsert;
export type Users = typeof Users.$inferSelect;
