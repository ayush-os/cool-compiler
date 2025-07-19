
class ShadowTest {
    test(x : Int) : Int {
        let x : Int <- x + 1 in
            let y : Int <- x + 2 in
                x + y
    };
};

