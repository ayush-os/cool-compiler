
class LetTest {
    test() : Int {
        let x : Int <- 5 in
            if x < 10 then 
                let y : Int <- 20 in
                    if y > x then y else x fi
            else
                0
            fi
    };
};

