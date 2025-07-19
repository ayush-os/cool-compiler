
class NestingTest {
    test() : Int {
        let a : Int <- 1 in
            let b : Int <- 2 in
                if a < b then
                    if a = 0 then
                        let c : Int <- 3 in
                            while c > 0 loop
                                c <- c - 1
                            pool
                    else
                        let d : Int <- 4 in
                            case d of
                                x : Int => x;
                                y : String => 0;
                            esac
                    fi
                else
                    let e : Int <- 5 in
                        e
                fi
    };
};

