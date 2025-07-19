
class LetTest {
    test() : Int {
        let x : Int <- 5 + 3 * 2,
            y : Int <- if x < 10 then x else x * 2 fi,
            z : Int <- while y > 0 loop y <- y - 1 pool
        in x + y + z
    };
};

