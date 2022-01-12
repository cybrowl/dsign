module {
    public type Profile = {
        name: Text;
        specialtyFields: Tags;
        created: Time;
        isTeam: Bool;
        isDesigner: Bool;
        teams: Tags;
        website: Text;
    };

    public type Tags = [Text];
};

