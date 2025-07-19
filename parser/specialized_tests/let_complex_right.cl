
class LetTest {
    test() : Int {
        let x : Int <- 5 in 
            x + (let y : Int <- 10 in y * 2) + 
            (let z : Int <- 15 in z / 3)
    };
};

