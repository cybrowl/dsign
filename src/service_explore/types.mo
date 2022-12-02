import AssetTypes "../service_assets/types";
import ImgAssetTypes "../service_assets_img/types";
import ProjectTypes "../service_projects/types";
import SnapTypes "../service_snaps/types";

module {
	public type AssetRef = AssetTypes.AssetRef;
	public type AssetsActor = AssetTypes.AssetsActor;
	public type ImageRef = ImgAssetTypes.ImageRef;
	public type Project = ProjectTypes.Project;
	public type Snap = SnapTypes.Snap;

	public type SnapCanisterId = Text;
	public type SnapID = Text;
	public type Time = Int;
	public type Username = Text;
};
