// acting agent

/* Initial beliefs and rules */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

/* 
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName
*/
@organization_deployed_plan
+organization_deployed(OrgName) : true <- 
	.print("Notified about organization deployment of ", OrgName);

	// joins the workspace
	joinWorkspace(OrgName, _);

	// looks up for, and focuses on the OrgArtifact that represents the organization
	lookupArtifact(OrgName, OrgId);
	focus(OrgId).

/* 
 * Plan for reacting to the addition of the belief available_role(Role)
 * Triggering event: addition of belief available_role(Role)
 * Context: true (the plan is always applicable)
 * Body: adopts the role Role
*/
@available_role_plan
+available_role(Role) : true <-
	.print("Adopting the role of ", Role);
	adoptRole(Role).

/* 
 * Plan for reacting to the addition of the belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Triggering event: addition of belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Context: true (the plan is always applicable)
 * Body: prints new interaction trust rating (relevant from Task 1 and on)
*/
+interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating): true <-
	.print("Interaction Trust Rating: (", TargetAgent, ", ", SourceAgent, ", ", MessageContent, ", ", ITRating, ")").

/* 
 * Plan for reacting to the addition of the certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Triggering event: addition of belief certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new certified reputation rating (relevant from Task 3 and on)
*/
+certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating): true <-
	.print("Certified Reputation Rating: (", CertificationAgent, ", ", SourceAgent, ", ", MessageContent, ", ", CRRating, ")").

/* 
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent,, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 5 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating): true <-
	.print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")").

/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celcius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celcius)
 * Context: true (the plan is always applicable)
 * Body: unifies the variable Celcius with the 1st temperature reading from the list TempReadings
*/
@select_reading_task_0_plan
+!select_reading(TempReadings, Celcius) : true <-
    .nth(0, TempReadings, Celcius).

// if selecting an agent from rogue agents
// +temperature(TempReading)[source(Ag)] : not Ag == sensing_agent_1 & not Ag == sensing_agent_2 & not Ag == sensing_agent_3 & not Ag == sensing_agent_4 <-
// 	.print("Temperature reading from ", Ag, ": ", TempReading);
// 	.findall(ITRating, interaction_trust(_, SensingAgent, _, ITRating) & SensingAgent == Ag, AgentRating);
// 	+i_trust(TempReading, math.average(AgentRating), Ag).

// if selecting an agent from all sensing agents
+temperature(TempReading)[source(Ag)] : true <-
	.print("Temperature reading from ", Ag, ": ", TempReading);
	.findall(ITRating, interaction_trust(_, SensingAgent, _, ITRating) & SensingAgent == Ag, AgentRating);
	+i_trust(TempReading, math.average(AgentRating), Ag).

+i_trust(TempReading, ITRating, Ag) : true <-
	.print("Interaction Trust Rating of Sensing Agent:",i_trust(TempReading, ITRating, Ag)).

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celcius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: selects a broadcasted temperature reading. Then, it converts the temperature 
 * from Celcius to binary degrees that are compatible with the movement of the robotic arm. 
 * Finally, it manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature : robot_td(Location) <-

	// creates list TempReadings with all the broadcasted temperature readings
	.findall(TempReading, temperature(TempReading)[source(Ag)], TempReadings);
	.print("Temperature readings to evaluate:", TempReadings);
	// creates goal to select one broadcasted reading to manifest
	// !select_reading(TempReadings, Celcius);

	.findall(AverageRating, i_trust( _, AverageRating, _), AverageRatings);
	.max(AverageRatings, MaxRating);
	.print("Highest value of IT rating is:", MaxRating);
	.findall(TempReading,i_trust(TempReading, AverageRating, _)& AverageRating == MaxRating,TempReadingwithMaxRating);
	// .member(CelciuswithMaxRating,TempReadingwithMaxRating);
	.nth(0, TempReadingwithMaxRating, Celcius);

	// manifests the selected reading stored in the variable Celcius
	// .print("Manifesting temperature (Celcius): ", Celcius);
	.print("Manifesting temperature (Celcius) with highest IT rating: ", Celcius);
	convert(Celcius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celcius to binary degress based on the input scale
	.print("Manifesting temperature (moving robotic arm to): ", Degrees);

	/* 
	 * If you want to test with the real robotic arm, 
	 * follow the instructions here: https://github.com/HSG-WAS-SS23/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
	 */
	// creates a ThingArtifact based on the TD of the robotic arm
	makeArtifact("leubot1", "wot.ThingArtifact", [Location, true], Leubot1Id); 
	
	// sets the API key for controlling the robotic arm as an authenticated user
	//setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(leubot1)];

	// invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
	invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(leubot1)].

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }

/* Import interaction trust ratings */
{ include("inc/interaction_trust_ratings.asl") }
