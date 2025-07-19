
class ErrorRecoveryTest {
    test() : Int {
        {
            let x : Int <- in x + 1;  -- Missing initializer
            if then 5 else 10 fi;     -- Missing condition
            while loop 1 pool;        -- Missing condition
            5;
        }
    };
};

