import sourceMapSupport from "source-map-support";
sourceMapSupport.install();
import app from "../src/app";
import authSignin from "./../src/procedures/auth/signin.rpc";
import authSignup from "./../src/procedures/auth/signup.rpc";
import flowsCreateFlow from "./../src/procedures/flows/createFlow.rpc";
import flowsGetFlow from "./../src/procedures/flows/getFlow.rpc";
import flowsListFlows from "./../src/procedures/flows/listFlows.rpc";
import flowsUpdateFlow from "./../src/procedures/flows/updateFlow.rpc";

app.rpc("auth.signin", authSignin);
app.rpc("auth.signup", authSignup);
app.rpc("flows.createFlow", flowsCreateFlow);
app.rpc("flows.getFlow", flowsGetFlow);
app.rpc("flows.listFlows", flowsListFlows);
app.rpc("flows.updateFlow", flowsUpdateFlow);

export default app;
