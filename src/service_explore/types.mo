import ProjectTypes "../service_projects/types";

module {
	public type ProjectPublic = ProjectTypes.ProjectPublic;
	public type SnapPublic = ProjectTypes.SnapPublic;
	public type Project = ProjectTypes.Project;
	public type ProjectRef = ProjectTypes.ProjectRef;
	public type ProjectActor = ProjectTypes.ProjectActor;

	public type ProjectCanisterId = Text;
	public type ProjectID = Text;
};
