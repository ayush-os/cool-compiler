
class Chain {
    value : Int;
    
    init(v : Int) : Chain {
        {
            value <- v;
            self;
        }
    };
    
    add(x : Int) : Chain {
        (new Chain).init(value + x)
    };
    
    multiply(x : Int) : Chain {
        (new Chain).init(value * x)
    };
    
    getValue() : Int { value };
    
    test() : Int {
        (new Chain).init(5).add(3).multiply(2).add(1).getValue()
    };
};

