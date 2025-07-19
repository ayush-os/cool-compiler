
class AttributeTest {
    counter : Int <- 0;
    name : String <- "test";
    
    self_ref : AttributeTest <- self;
    complex_attr : Int <- {
        let temp : Int <- 5 in
            if temp < 10 then
                temp * 2
            else
                temp + 10
            fi;
    };
};

