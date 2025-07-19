
class ShiftReduceTest {
    test() : Int {
        let x : Int <- 5,
            y : Int <- let z : Int <- 10 in z
        in x + y
    };
};

