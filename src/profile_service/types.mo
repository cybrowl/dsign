module {
    public type Profile = {
        username: Text;
        specialtyFields: Tags;
        created: Time;
        website: Text;
    };

    public type Tags = [Text];
};

