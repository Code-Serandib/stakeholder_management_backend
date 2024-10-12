public type SEmetrics record {|
    float? power;
    float? legitimacy;
    float? urgency;
    string? stakeholder_type;
|};

public type CustomTable record {
    string[] players_names;
    int[] atr_count;
    string[] atr;
    int[] values;
};

public type StakeholderRelation record {
    float benefit;
    float cost;
};