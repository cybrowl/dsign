import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";
import ProjectTypes "../service_projects/types";

module {
	public type AssetRef = AssetTypes.AssetRef;
	public type AssetsActor = AssetTypes.AssetsActor;

	public type SnapCanisterId = Text;
	public type SnapID = Text;
	public type Username = Text;
	public type Time = Int;
	public type Project = ProjectTypes.Project;

	public type ImageRef = ImgAssetTypes.ImageRef;

	public type Snap = {
		canister_id : Text;
		created : Time;
		file_asset : AssetRef;
		id : SnapID;
		image_cover_location : Nat8;
		images : [ImageRef];
		project : ?Project;
		tags : ?[Text];
		title : Text;
		username : Username;
		owner : Principal;
		metrics : {
			likes : Nat;
			views : Nat;
		};
	};
};
