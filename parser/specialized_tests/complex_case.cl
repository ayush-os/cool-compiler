
class CaseTest {
    test(x : Object) : Object {
        case x of
            i : Int => 
                case i of
                    0 => "zero";
                    1 => "one";
                    n : Int => n + 100;
                esac;
            s : String => 
                if s.length() = 0 then
                    "empty"
                else
                    s
                fi;
            o : Object => o;
        esac
    };
};

