import H "mo:base/HashMap";
import B "mo:base/Buffer";
import Principal "mo:base/Principal";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

import Types "./types";

actor class Snap() = this {
    type CreateSnapArgs = Types.CreateSnapArgs;
    type ImageID =  Types.ImageID;
    type Snap = Types.Snap;
    type SnapID = Types.SnapID;
    type UserPrincipal = Types.UserPrincipal;

    private let rr = XorShift.toReader(XorShift.XorShift64(null));
    private let se = Source.Source(rr, 0);

    var snaps : H.HashMap<SnapID, Snap> = H.HashMap(0, Text.equal, Text.hash);

    //TODO: only allow main to accesss methods

    public query func version() : async Text {
        return "0.0.1";
    };

    public query func get_canister_id() : async Text {
        return Principal.toText(Principal.fromActor(this));
    };

    public shared ({caller}) func create(args: CreateSnapArgs, imageIds: [ImageID], userPrincipal: UserPrincipal) : async SnapID {
        let snapID =  ULID.toText(se.new());

        let snap : Snap = {
            id = snapID;
            coverLocation = args.coverImageLocation;
            created = Time.now();
            creator = userPrincipal;
            images = imageIds;
            isPublic = args.isPublic;
            likes = 0;
            projects = null;
            title = args.title;
            views = 0;
        };

        snaps.put(snapID, snap);

        return snapID;
    };

    public query func get_all(listOfSnapIds: [SnapID]) : async [Snap] {
        var snapList = B.Buffer<Snap>(0);

        for (snapId in listOfSnapIds.vals()){
            switch (snaps.get(snapId)){
                case null {};
                case (?snapResult) {
                   snapList.add(snapResult); 
                };
                
            }
        };

        return snapList.toArray();
    };
};