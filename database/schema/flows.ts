import {
    timestamp,
    pgTable,
    varchar,
    boolean,
    text,
    json
  } from "drizzle-orm/pg-core";
  
  import { relations } from "drizzle-orm";
  //
  import { defaultDateFields, ulidField } from "./common";
import { Users } from "./users";
  
  export const Flows = pgTable("flows", {
    ...defaultDateFields,
    id: ulidField("id").notNull().primaryKey(),
    userId: ulidField("user_id").notNull().references(() => Users.id),
    flowName: varchar("flow_name", { length: 255 }).notNull(),
    flow: json("flow").notNull(),
  });
  
  // Define relations
  export const flowsRelations = relations(Flows, ({ one }) => ({
    user: one(Users, {
      fields: [Flows.userId],
      references: [Users.id],
    }),
  }));
  
  export type NewFlows = typeof Flows.$inferInsert;
  export type Flows = typeof Flows.$inferSelect;
  

  