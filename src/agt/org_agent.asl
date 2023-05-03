// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

// infers whether a role R has not been adopted by a suffient number of agents in a group
has_enough_players_for(R,G) :-
  role_cardinality(R, Min, Max) &
  .count(play(_,R,G), NP) &
  NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello world");
  
  //creates and joins workspace
  createWorkspace(OrgName);
  joinWorkspace(OrgName,WOrg);

  // init and focuses on OrgBoard artifact that represents a lab monitoring organization
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgArtId)[wid(WOrg)];
  focus(OrgArtId)[wid(WOrg)];
      
  // creates, inspects, and focuses on a GroupBoard artifact that represents a monitoring team
  createGroup(GroupName, monitoring_team, GrArtId);
  !inspect(GrArtId);
  focus(GrArtId)[wid(WOrg)];

  // creates, inspects, and focuses on a SchemeBoard artifact that represents a monitoring scheme
  createScheme(SchemeName, monitoring_scheme, SchArtId);
  !inspect(SchArtId);
  focus(SchArtId)[wid(WOrg)];

  // broadcasts a message about the deployment of a new organization
  .print("Broadcasting organization deployment of ", OrgName);
  .broadcast(tell, organization_deployed(OrgName));

  // creates an achievment-goal for managing the formation of the group represented by the artifact GrArtId
  !manage_formation(GrArtId); 

  // creates a test-goal for testing the formation status of the group represented by the artifact GrArtId
  // if the belief formationStatus(ok) is in the belief base the rest of the plan body is executed
  // otherwise, the agent executes the @test_formation_status_is_ok_plan
  ?formationStatus(ok)[artifact_id(GrArtId)];

  // once the formation status is ok, adds the scheme to the group represented by the GrArtId
  // i.e. the group becomes responsible for the scheme
  addScheme(SchemeName)[artifact_id(GrArtId)].

@manage_formation_status_nok
+!manage_formation(G) : group(GroupName,_,G)[artifact_name(_,OrgName)] &
  not formationStatus(ok)[artifact_id(G)] <-  
    .wait(15000);
    .findall(Role, role(Role, Super) & not has_enough_players_for(Role,GroupName), AvailableRoles);
    .print("Inferred the available roles of group ", GroupName, ": ", AvailableRoles);
    !broadcast_available_roles(AvailableRoles);
    !manage_formation(G).

@manage_formation_status_ok
-!manage_formation(G) : group(GroupName,_,G)[artifact_name(_,OrgName)] &
  formationStatus(ok)[artifact_id(G)] <-
  .print("Group ", GroupName, " is well-formed").

/* 
 * Plan for reacting to the addition of the goal !broadcast_available_roles([])
 * Triggering event: addition of goal !broadcast_available_roles([])
 * Context: true (the plan is always applicable)
 * Body: does nothing since the list is empty
*/
@broadcast_roles_empty_list_plan
+!broadcast_available_roles([]).

/* 
 * Plan for reacting to the addition of the goal !broadcast_available_roles([Role | AvailableRoles])
 * Triggering event: addition of goal !broadcast_available_roles([Role | AvailableRoles])
 * Context: true (the plan is always applicable)
 * Body: recursively broadcasts the availability of the fist role from the list. The remaining roles are stored in the list AvailableRoles
*/
@broadcast_roles_plan
+!broadcast_available_roles([Role | AvailableRoles]) : true <-
    .print("Broadcasting available role: ", Role);
    .broadcast(tell, available_role(Role));
    !broadcast_available_roles(AvailableRoles).

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }