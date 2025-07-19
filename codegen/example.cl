class A {
    get_min (x : Int, y : Int) : Int {
        if x < y then x else y fi
    };
};

class Main inherits IO {
    main () : SELF_TYPE {
        out_int((new A).get_min(5, 10))
    };
};