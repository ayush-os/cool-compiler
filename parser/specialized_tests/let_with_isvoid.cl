
class IsvoidTest {
    test() : Bool {
        let x : Int <- 5 in isvoid x || 
        let y : Object <- null in isvoid y &&
        let z : Int <- 10 in not isvoid z
    };
};

