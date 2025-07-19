#!/bin/bash

# Script for extreme edge cases and stress testing the Cool parser
# These tests focus on pushing the limits of the parser beyond normal usage

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory for test files
EDGE_DIR="extreme_edge_cases"
mkdir -p $EDGE_DIR

# Counter for tests
TOTAL=0
PASSED=0

# Function to run test
run_test() {
    local test_name=$1
    local test_content=$2
    local test_file="$EDGE_DIR/$test_name.cl"
    
    echo -e "\n${CYAN}==== EXTREME TEST: $test_name ====${NC}"
    echo "$test_content" > "$test_file"
    TOTAL=$((TOTAL + 1))
    
    # Run your parser
    echo -e "${YELLOW}Running your parser...${NC}"
    ./myparser "$test_file" > "$EDGE_DIR/my_output.txt" 2>&1
    MY_EXIT=$?
    
    # Run reference parser
    echo -e "${YELLOW}Running reference parser...${NC}"
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$EDGE_DIR/ref_output.txt" 2>&1
    REF_EXIT=$?
    
    # Compare exit codes first
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes don't match! Your parser: $MY_EXIT, Reference: $REF_EXIT${NC}"
        return
    fi
    
    # If outputs match exactly, it's a clear pass
    if diff -q "$EDGE_DIR/my_output.txt" "$EDGE_DIR/ref_output.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match exactly${NC}"
        PASSED=$((PASSED + 1))
        return
    fi
    
    # Try ignoring line numbers
    grep -v "line" "$EDGE_DIR/my_output.txt" > "$EDGE_DIR/my_output_nolines.txt"
    grep -v "line" "$EDGE_DIR/ref_output.txt" > "$EDGE_DIR/ref_output_nolines.txt"
    
    if diff -q "$EDGE_DIR/my_output_nolines.txt" "$EDGE_DIR/ref_output_nolines.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match when ignoring line numbers${NC}"
        PASSED=$((PASSED + 1))
        return
    fi
    
    # Outputs differ - show details and ask for verification
    echo -e "${YELLOW}Outputs differ - manual verification needed${NC}"
    echo -e "Your parser output:"
    cat "$EDGE_DIR/my_output.txt"
    echo -e "\nReference parser output:"
    cat "$EDGE_DIR/ref_output.txt"
    
    read -p "Is this test passing despite the differences? (y/n): " manual_verify
    if [ "$manual_verify" = "y" ]; then
        echo -e "${GREEN}PASS: Manually verified${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL: Test failed manual verification${NC}"
    fi
}

# ===== EXTREME EDGE CASES =====

# 1. Extremely deeply nested expressions
echo "Extreme Test 1: Extremely deeply nested expressions"
run_test "extreme_nesting" "
class DeepNesting {
    test() : Int {
        1 + (2 * (3 + (4 * (5 + (6 * (7 + (8 * (9 + (10 * (11 + (12 * (13 + (14 * (15 + (16 * (17 + (18 * (19 + (20 * 21))))))))))))))))))
    };

    test2() : Int {
        if if if if if true then true else false fi then true else false fi then true else false fi then true else false fi then 1 else 0 fi
    };
    
    test3() : Int {
        let a : Int <- 1 in let b : Int <- 2 in let c : Int <- 3 in let d : Int <- 4 in let e : Int <- 5 in 
        let f : Int <- 6 in let g : Int <- 7 in let h : Int <- 8 in let i : Int <- 9 in let j : Int <- 10 in
        let k : Int <- 11 in let l : Int <- 12 in let m : Int <- 13 in let n : Int <- 14 in let o : Int <- 15 in
        a + b + c + d + e + f + g + h + i + j + k + l + m + n + o
    };
};
"

# 2. Maximum complexity class hierarchy
echo "Extreme Test 2: Maximum complexity class hierarchy"
run_test "extreme_hierarchy" "
class A {};
class B inherits A {};
class C inherits B {};
class D inherits C {};
class E inherits D {};
class F inherits E {};
class G inherits F {};
class H inherits G {};
class I inherits H {};
class J inherits I {};
class K inherits J {};
class L inherits K {};
class M inherits L {};
class N inherits M {};
class O inherits N {};
class P inherits O {};
class Q inherits P {};
class R inherits Q {};
class S inherits R {};
class T inherits S {};
class U inherits T {};
class V inherits U {};
class W inherits V {};
class X inherits W {};
class Y inherits X {};
class Z inherits Y {
    test() : SELF_TYPE { self };
};

class Main {
    z : Z <- new Z;
    test() : Object { z.test() };
};
"

# 3. Extremely long method parameter list
echo "Extreme Test 3: Extremely long method parameter list"
run_test "extreme_params" "
class LotsOfParams {
    longMethod(
        p1 : Int, p2 : Int, p3 : Int, p4 : Int, p5 : Int,
        p6 : Int, p7 : Int, p8 : Int, p9 : Int, p10 : Int,
        p11 : Int, p12 : Int, p13 : Int, p14 : Int, p15 : Int,
        p16 : Int, p17 : Int, p18 : Int, p19 : Int, p20 : Int,
        p21 : Int, p22 : Int, p23 : Int, p24 : Int, p25 : Int,
        p26 : Int, p27 : Int, p28 : Int, p29 : Int, p30 : Int,
        p31 : Int, p32 : Int, p33 : Int, p34 : Int, p35 : Int,
        p36 : Int, p37 : Int, p38 : Int, p39 : Int, p40 : Int,
        p41 : Int, p42 : Int, p43 : Int, p44 : Int, p45 : Int,
        p46 : Int, p47 : Int, p48 : Int, p49 : Int, p50 : Int
    ) : Int {
        p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9 + p10 +
        p11 + p12 + p13 + p14 + p15 + p16 + p17 + p18 + p19 + p20 +
        p21 + p22 + p23 + p24 + p25 + p26 + p27 + p28 + p29 + p30 +
        p31 + p32 + p33 + p34 + p35 + p36 + p37 + p38 + p39 + p40 +
        p41 + p42 + p43 + p44 + p45 + p46 + p47 + p48 + p49 + p50
    };
};
"

# 4. Extremely complex multiple let expressions
echo "Extreme Test 4: Extremely complex multiple let expressions with initialization"
run_test "extreme_let" "
class ComplexLet {
    test() : Int {
        let 
            a : Int <- let b : Int <- 1 in b + 1,
            c : Int <- let d : Int <- let e : Int <- 2 in e + 2 in d + 3,
            f : Int <- let g : Int <- let h : Int <- let i : Int <- 3 in i + 3 in h + 4 in g + 5,
            j : Int <- if let k : Int <- 4 in k < 5 then 6 else 7 fi,
            l : Int <- case let m : Int <- 5 in m of n : Int => n + 8; o : Object => 9; esac,
            p : Int <- while let q : Int <- 6 in q < 10 loop 11 pool,
            r : String <- let s : String <- \"hello\", t : String <- \" \" in s.concat(t).concat(\"world\"),
            u : Int <- ~(let v : Int <- 12 in v * 2),
            w : Int <- let x : Int <- 13, y : Int <- 14, z : Int <- 15 in x + y + z
        in
            a + c + f + j + l + p + r.length() + u + w
    };
};
"

# 5. Nested case expressions
echo "Extreme Test 5: Highly nested case expressions"
run_test "extreme_case" "
class NestedCase {
    test(o : Object) : Object {
        case o of
            a : Int => 
                case a of
                    1 => \"one\";
                    2 => case 2 of
                            x : Int => 
                                case x of
                                    y : Int => 
                                        case y of
                                            z : Int => z;
                                            z : Object => 0;
                                        esac;
                                    y : Object => 0;
                                esac;
                            x : Object => 0;
                         esac;
                    a : Object => 0;
                esac;
            b : String =>
                case b of
                    \"hello\" => case \"world\" of
                                    c : String => 
                                        case c.length() of
                                            d : Int => d;
                                            d : Object => 0;
                                        esac;
                                    c : Object => 0;
                                 esac;
                    b : Object => 0;
                esac;
            o : Object => 0;
        esac
    };
};
"

# 6. Massive number of classes and features
echo "Extreme Test 6: Massive number of classes and features"
run_test "massive_program" "
$(for i in {1..50}; do
    echo "class Class$i {"
    for j in {1..10}; do
        echo "    attr$j : Int <- $j;"
    done
    for j in {1..10}; do
        echo "    method$j() : Int { $j };"
    done
    echo "};"
    echo ""
done)

class Main {
    main() : Object { new Object };
};
"

# 7. Extreme mixed associativity test
echo "Extreme Test 7: Extreme mixed associativity"
run_test "extreme_associativity" "
class AssocTest {
    test() : Int {
        1 + 2 * 3 + 4 * 5 + 6 * 7 + 8 * 9 + 10 * 11 + 12 * 13 + 14 * 15 +
        16 * 17 + 18 * 19 + 20 * 21 + 22 * 23 + 24 * 25 + 26 * 27 + 28 * 29 +
        30 * 31 + 32 * 33 + 34 * 35 + 36 * 37 + 38 * 39 + 40 * 41 + 42 * 43 +
        44 * 45 + 46 * 47 + 48 * 49 + 50
    };
    
    test2() : Bool {
        1 < 2 && 3 < 4 || 5 < 6 && 7 < 8 || 9 < 10 && 11 < 12 || 13 < 14 &&
        15 < 16 || 17 < 18 && 19 < 20 || not 21 < 22 && 23 < 24 || 25 < 26
    };
};
"

# 8. Complex error cascade recovery
echo "Extreme Test 8: Complex error cascade recovery"
run_test "error_cascade" "
class ErrorClass1 {
    -- Missing semicolon
    a : Int <- 1
    -- Incorrect type
    b : Nonexistent <- 2;
    -- Missing type
    c : <- 3;
    
    -- Good method after errors
    good1() : Int { 1 };
};

class ErrorClass2 inherits ErrorClass1 {
    -- Error in method signature - missing type
    bad1(x : Int, y : ) : Int { x + y };
    
    -- Error in method body
    bad2() : Int { 1 + * 3 };
    
    -- Good method after errors
    good2() : Int { 2 };
};

class ErrorClass3 {
    -- Multiple compounding errors
    test() : Int {
        {
            -- Missing then keyword
            if x < 5 x + 1 else x - 1 fi;
            
            -- Incorrect loop structure
            while x < 10 x <- x + 1 pool;
            
            -- Incorrect case syntax
            case x
                y : Int => y;
                z : Object => 0;
            esac;
            
            -- Good expression after errors
            42;
        }
    };
    
    -- Good method after errors
    good3() : Int { 3 };
};

class Main {
    main() : Object {
        {
            -- Complex errors in let
            let 
                a : Int <- 1,
                b : <- 2,  -- Missing type
                c : Int    -- Missing assignment
            in a + b + c;
            
            -- Good expression after errors
            let x : Int <- 42 in x;
        }
    };
};
"

# 9. Extreme mixed precedence test
echo "Extreme Test 9: Extreme mixed precedence"
run_test "extreme_precedence" "
class PrecedenceTest {
    test() : Int {
        ~isvoid 1 + ~2 * 3 / ~4 - 5 * (6 + 7) * (8 + 9 * 10) / (11 + ~12 * 13) -
        14 + 15 * 16 / 17 - 18 * (19 + 20) * (21 + 22 * 23) / (24 + ~25 * 26)
    };
    
    test2() : Bool {
        not 1 < 2 && 3 <= 4 || 5 = 6 && not 7 < 8 || not 9 <= 10 && 11 = 12 ||
        not 13 < 14 && 15 <= 16 || 17 = 18 && not 19 < 20 || not 21 <= 22 && 23 = 24
    };
};
"

# 10. Maximum block nesting
echo "Extreme Test 10: Maximum block nesting"
run_test "extreme_blocks" "
class BlockNesting {
    test() : Int {
        {
            {
                {
                    {
                        {
                            {
                                {
                                    {
                                        {
                                            {
                                                {
                                                    {
                                                        {
                                                            {
                                                                {
                                                                    {
                                                                        {
                                                                            {
                                                                                {
                                                                                    {
                                                                                        42;
                                                                                    };
                                                                                };
                                                                            };
                                                                        };
                                                                    };
                                                                };
                                                            };
                                                        };
                                                    };
                                                };
                                            };
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
        }
    };
};
"

# 11. Combination of complex let and case
echo "Extreme Test 11: Combination of complex let and case"
run_test "complex_let_case" "
class LetAndCase {
    test(o : Object) : Object {
        let 
            a : Int <- case o of
                        x : Int => 
                            let y : Int <- x * 2 in
                                if y < 10 then y else y - 5 fi;
                        x : String => 
                            let len : Int <- x.length() in
                                case len of
                                    0 : Int => 0;
                                    l : Int => l * 2;
                                esac;
                        x : Object => 0;
                      esac,
            b : String <- let c : String <- \"hello\" in
                            case c of
                                \"hello\" => \"world\";
                                s : String => s;
                                o : Object => \"unknown\";
                            esac,
            c : Int <- let 
                        d : Int <- 5,
                        e : Int <- case d of
                                    5 => 10;
                                    i : Int => i;
                                    o : Object => 0;
                                  esac
                       in d + e
        in
            case a of
                10 => b;
                i : Int => 
                    let s : String <- 
                        case i of
                            5 => \"five\";
                            10 => \"ten\";
                            n : Int => (new A2I).i2a(n);
                            o : Object => \"zero\";
                        esac
                    in s;
                o : Object => \"unknown\";
            esac
    };
};

class A2I {
    i2a(i : Int) : String {
        if i = 0 then \"0\" else
        if i < 0 then \"-\".concat(i2a_aux(~i)) else
           i2a_aux(i)
        fi fi
    };
    
    i2a_aux(i : Int) : String {
        if i = 0 then \"\" else
            i2a_aux(i / 10).concat(
                if i = 0 then \"0\" else
                if i = 1 then \"1\" else
                if i = 2 then \"2\" else
                if i = 3 then \"3\" else
                if i = 4 then \"4\" else
                if i = 5 then \"5\" else
                if i = 6 then \"6\" else
                if i = 7 then \"7\" else
                if i = 8 then \"8\" else
                if i = 9 then \"9\" else
                    { abort(); \"\"; }
                fi fi fi fi fi fi fi fi fi fi
            )
        fi
    };
};
"

# 12. Self-referential classes and methods
echo "Extreme Test 12: Self-referential classes and methods"
run_test "self_reference" "
class SelfRef {
    attr1 : SelfRef;
    attr2 : SELF_TYPE;
    
    init() : SELF_TYPE {
        {
            attr1 <- new SelfRef;
            attr2 <- self;
            self;
        }
    };
    
    test1() : SelfRef { attr1 };
    test2() : SELF_TYPE { attr2 };
    test3() : SELF_TYPE { self.init().test2().init() };
    
    test4(x : Int) : SELF_TYPE {
        if x = 0 then
            self
        else
            self.test4(x - 1)
        fi
    };
    
    test5() : Object {
        let x : SELF_TYPE <- self,
            y : SelfRef <- x.test1()
        in
            y.test3().test4(5)
    };
};

class Main {
    main() : Object {
        (new SelfRef).init().test5()
    };
};
"

# 13. Maximum string and identifier length
echo "Extreme Test 13: Maximum string and identifier length"
run_test "max_length" "
class VeryLongClassName$(printf '%080d' 0 | tr '0' 'A') {
    $(printf '%080d' 0 | tr '0' 'a')VeryLongAttributeName : Int;
    
    $(printf '%080d' 0 | tr '0' 'a')VeryLongMethodName($(printf '%080d' 0 | tr '0' 'a')VeryLongParameterName : Int) : Int {
        let $(printf '%080d' 0 | tr '0' 'a')VeryLongLocalVariable : Int <- $(printf '%080d' 0 | tr '0' 'a')VeryLongParameterName in 
            $(printf '%080d' 0 | tr '0' 'a')VeryLongLocalVariable + 1
    };
    
    testLongString() : String {
        \"$(printf '%0500d' 0 | tr '0' 'X')\"
    };
};
"

# 14. Complex method dispatch chains
echo "Extreme Test 14: Complex method dispatch chains"
run_test "dispatch_chains" "
class DispatchTest {
    a() : DispatchTest { self };
    b() : DispatchTest { self };
    c() : DispatchTest { self };
    d() : DispatchTest { self };
    e() : DispatchTest { self };
    f() : DispatchTest { self };
    g() : DispatchTest { self };
    h() : DispatchTest { self };
    i() : DispatchTest { self };
    j() : DispatchTest { self };
    
    value() : Int { 42 };
    
    test() : Int {
        self.a().b().c().d().e().f().g().h().i().j().value()
    };
    
    test2() : Int {
        (new DispatchChild).a().b().c().d().e().f().g().h().i().j().value()
    };
    
    test3(x : Int) : Int {
        if x = 0 then
            self.value()
        else
            self.a().test3(x - 1)
        fi
    };
};

class DispatchChild inherits DispatchTest {
    value() : Int { 100 };
    
    k() : DispatchTest { self };
    
    test4() : Int {
        self.a().b().c().d().e().f().g().h().i().j().k().value()
    };
};

class Main {
    main() : Object {
        {
            (new DispatchTest).test();
            (new DispatchTest).test2();
            (new DispatchTest).test3(10);
            (new DispatchChild).test4();
        }
    };
};
"

# 15. Extreme feature count in a class
echo "Extreme Test 15: Extreme feature count in a class"
run_test "extreme_features" "
class FeatureTest {
$(for i in {1..100}; do
    echo "    attr$i : Int;"
done)

$(for i in {1..100}; do
    echo "    method$i() : Int { $i };"
done)
};

class Main {
    obj : FeatureTest <- new FeatureTest;
    
    main() : Object {
        {
$(for i in {1..20}; do
    echo "            obj.method$i();"
done)
        }
    };
};
"

# 16. Extremely complex multi-type expressions
echo "Extreme Test 16: Extremely complex multi-type expressions"
run_test "complex_expressions" "
class ExprTest {
    io : IO <- new IO;
    
    test() : Object {
        let
            a : Int <- 10,
            b : String <- \"hello\",
            c : Bool <- true,
            d : Object <- self,
            e : IO <- new IO
        in {
            if c then
                if a < 20 then
                    while a < 20 loop {
                        a <- a + 1;
                        io.out_int(a).out_string(\" \");
                    } pool
                else
                    case d of
                        o : ExprTest => o.test();
                        o : IO => o.out_string(\"IO object\\n\");
                        o : Object => io.out_string(\"unknown\\n\");
                    esac
                fi
            else
                io.out_string(b).out_string(\"\\n\")
            fi;
            
            case a + 5 * (if c then 2 else 3 fi) of
                15 : Int => io.out_string(\"fifteen\\n\");
                20 : Int => io.out_string(\"twenty\\n\");
                i : Int => io.out_string(\"number: \").out_int(i).out_string(\"\\n\");
                o : Object => io.out_string(\"not a number\\n\");
            esac;
            
            let f : Int <-
                case b of
                    \"hello\" => b.length() * 2;
                    \"world\" => b.length();
                    s : String => s.length() / 2;
                    o : Object => 0;
                esac
            in
                while f > 0 loop {
                    f <- f - 1;
                    io.out_string(\".\");
                } pool;
            
            io.out_string(\"\\n\");
        }
    };
};

class Main {
    main() : Object {
        (new ExprTest).test()
    };
};
"

# 17. Let with maximal complex initializers
echo "Extreme Test 17: Let with maximal complex initializers"
run_test "complex_initializers" "
class InitTest {
    test() : Int {
        let
            a : Int <- 5 + 10 * 15 / 3 - 7 + 2 * (8 - 4) + ~3 * 6,
            b : Int <- if 5 < 10 then 15 else 20 fi + if true then 25 else 30 fi,
            c : Int <- case \"hello\" of
                        \"hello\" => 10;
                        \"world\" => 20;
                        s : String => s.length();
                        o : Object => 0;
                      esac,
            d : Int <- let e : Int <- 5, f : Int <- 10 in e * f + let g : Int <- 15 in g,
            h : Int <- while false loop 10 pool + 20,
            i : String <- \"hello\".concat(\" \").concat(\"world\"),
            j : Int <- i.length(),
            k : Int <- (new IO).out_string(\"initializing\\n\").out_int(100).out_string(\"\\n\").in_int(),
            l : Int <- {
                let m : Int <- 5, n : Int <- 10 in m + n;
                let o : Int <- 15 in o * 2;
                25;
            },
            p : Int <- (
                6 * 7 + 8 * 9 +
                10 * 11 + 12 * 13 +
                14 * 15 + 16 * 17 +
                18 * 19 + 20 * 21
            )
        in
            a + b + c + d + h + j + k + l + p
    };
};

class Main {
    main() : Object {
        (new InitTest).test()
    };
};
"

# 18. Multiple error recovery at different levels
echo "Extreme Test 18: Multiple error recovery at different levels"
run_test "multi_level_errors" "
-- Error in class definition - missing closing brace
class ErrorClass1 {
    a : Int;
    b : Int;
    
    method1() : Int { a + b };

-- But parser should recover and parse this class
class ErrorClass2 {
    -- Error in attribute
    c : Int 
    
    -- Error in method parameter
    method2(x : Int, y : ) : Int { x + y };
    
    -- Error in let expression
    method3() : Int {
        let a : Int <- 5,
            b : <- 10,
            c : Int
        in a + b + c
    };
    
    -- Error in if expression
    method4() : Int {
        if then 5 else 10 fi
    };
    
    -- But this should still be parsed
    method5() : Int { 42 };
};

-- Another class with error - inherits from non-existent class
class ErrorClass3 inherits NonExistentClass {
    -- Multiple expression errors in one method body
    method1() : Int {
        {
            1 + ;  -- Error in expression
            if 5 < 10 5 else 10 fi;  -- Error in if syntax
            let a : Int <- in a + 1;  -- Error in let
            5 + * 3;  -- Error in binary operation
            
            -- But this should be parsed correctly
            42;
        }
    };
    
    -- This should be parsed correctly despite previous errors
    method2() : Int { 100 };
};

-- This class should be parsed correctly
class Main {
    main() : Object {
        (new IO).out_string(\"Program completed\\n\")
    };
};
"

# 19. Complex recursive type expressions
echo "Extreme Test 19: Complex recursive type expressions"
run_test "recursive_types" "
class List {};

class Cons inherits List {
    head : Object;
    tail : List;
    
    init(h : Object, t : List) : Cons {
        {
            head <- h;
            tail <- t;
            self;
        }
    };
};

class Tree {};

class Node inherits Tree {
    value : Object;
    left : Tree;
    right : Tree;
    
    init(v : Object, l : Tree, r : Tree) : Node {
        {
            value <- v;
            left <- l;
            right <- r;
            self;
        }
    };
};

class Complex {
    -- A tree of lists of trees
    treeOfLists : Tree;
    
    -- A list of trees of lists
    listOfTrees : List;
    
    -- Initialize complex structures
    init() : Complex {
        {
            -- Create a tree of lists
            let list1 : List <- (new Cons).init(new Node, new List),
                list2 : List <- (new Cons).init(new Node, new List),
                list3 : List <- (new Cons).init(new Node, new List)
            in {
                treeOfLists <- (new Node).init(list1, 
                                (new Node).init(list2, new Tree, new Tree),
                                (new Node).init(list3, new Tree, new Tree));
            };
            
            -- Create a list of trees
            let tree1 : Tree <- (new Node).init(new List, new Tree, new Tree),
                tree2 : Tree <- (new Node).init(new List, new Tree, new Tree),
                tree3 : Tree <- (new Node).init(new List, new Tree, new Tree)
            in {
                listOfTrees <- (new Cons).init(tree1, 
                                (new Cons).init(tree2,
                                (new Cons).init(tree3, new List)));
            };
            
            self;
        }
    };
};

class Main {
    main() : Object {
        (new Complex).init()
    };
};
"

# 20. Maximum parenthesized expression
echo "Extreme Test 20: Maximum parenthesized expression"
run_test "max_parentheses" "
class ParenTest {
    test() : Int {
        (((((((((((((((((((((((((((((((((((((((((((((((((
            5 + 10
        )))))))))))))))))))))))))))))))))))))))))))))))
    };
    
    test2() : Int {
        (5 + (4 * (3 - (2 / (1 + (0 * (1 - (2 + (3 * (4 - (5 + (6 * (7 - (8 + (9 * (10 - (11 + (12 * 13)))))))))))))))))))
    };
};

class Main {
    main() : Object {
        (new ParenTest).test() + (new ParenTest).test2()
    };
};
"

# 21. Complex mixed dispatch, new, and operations
echo "Extreme Test 21: Complex mixed dispatch, new, and operations"
run_test "mixed_operations" "
class ComplexOps {
    x : Int <- 10;
    y : Int <- 20;
    
    getX() : Int { x };
    getY() : Int { y };
    
    setX(newX : Int) : ComplexOps { { x <- newX; self; } };
    setY(newY : Int) : ComplexOps { { y <- newY; self; } };
    
    add() : Int { x + y };
    multiply() : Int { x * y };
};

class Calculator {
    a : ComplexOps;
    b : ComplexOps;
    
    init() : Calculator {
        {
            a <- new ComplexOps;
            b <- new ComplexOps;
            self;
        }
    };
    
    complexCalculation() : Int {
        a.setX(b.getY() * 2 - a.getX() / 2).setY(a.getX() + b.getY()).add() *
        b.setX(a.getY() / 2 + b.getX() * 2).setY(b.getY() - a.getX()).multiply() +
        (new ComplexOps).setX(a.getX() + b.getX()).setY(a.getY() + b.getY()).add() -
        (new ComplexOps).setX(a.getX() * b.getX()).setY(a.getY() * b.getY()).multiply()
    };
};

class Main {
    main() : Object {
        (new Calculator).init().complexCalculation()
    };
};
"

# 22. Extreme let with expression interaction
echo "Extreme Test 22: Extreme let with expression interaction"
run_test "let_expressions" "
class LetExprTest {
    test() : Int {
        -- Let inside if condition
        if let x : Int <- 5 in x < 10 then
            -- Let inside then branch
            let y : Int <- 10 in
                -- Let inside else condition of nested if
                if let z : Int <- 15 in z > y then
                    y * 2
                else
                    -- Let inside nested else branch
                    let w : Int <- 20 in w
                fi
        else
            -- Let inside case expression in else branch
            case let v : Int <- 25 in v of
                25 => 
                    -- Let inside case branch
                    let u : Int <- 30 in u;
                i : Int => 
                    -- Let inside while condition
                    while let j : Int <- i in j > 0 loop
                        -- Let inside loop body
                        let k : Int <- j - 1 in { i <- k; k; }
                    pool;
                o : Object => 0;
            esac
        fi
    };
};

class Main {
    main() : Object {
        (new LetExprTest).test()
    };
};
"

# 23. Maximum operator chain
echo "Extreme Test 23: Maximum operator chain"
run_test "operator_chain" "
class OperatorTest {
    test() : Int {
        1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 +
        11 + 12 + 13 + 14 + 15 + 16 + 17 + 18 + 19 + 20 +
        21 + 22 + 23 + 24 + 25 + 26 + 27 + 28 + 29 + 30 +
        31 + 32 + 33 + 34 + 35 + 36 + 37 + 38 + 39 + 40 +
        41 + 42 + 43 + 44 + 45 + 46 + 47 + 48 + 49 + 50
    };
    
    test2() : Bool {
        1 < 2 && 3 < 4 && 5 < 6 && 7 < 8 && 9 < 10 &&
        11 < 12 && 13 < 14 && 15 < 16 && 17 < 18 && 19 < 20 &&
        21 < 22 && 23 < 24 && 25 < 26 && 27 < 28 && 29 < 30
    };
    
    test3() : Bool {
        1 < 2 || 3 < 4 || 5 < 6 || 7 < 8 || 9 < 10 ||
        11 < 12 || 13 < 14 || 15 < 16 || 17 < 18 || 19 < 20
    };
};

class Main {
    main() : Object {
        {
            (new OperatorTest).test();
            if (new OperatorTest).test2() then 1 else 0 fi;
            if (new OperatorTest).test3() then 1 else 0 fi;
        }
    };
};
"

# 24. Extreme unary operator sequence
echo "Extreme Test 24: Extreme unary operator sequence"
run_test "unary_operators" "
class UnaryTest {
    test() : Int {
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5
    };
    
    test2() : Bool {
        not not not not not not not not not not true
    };
    
    test3() : Bool {
        isvoid isvoid isvoid isvoid isvoid new Object
    };
};

class Main {
    main() : Object {
        {
            (new UnaryTest).test();
            if (new UnaryTest).test2() then 1 else 0 fi;
            if (new UnaryTest).test3() then 1 else 0 fi;
        }
    };
};
"

# 25. Extreme combination of all Cool language features
echo "Extreme Test 25: Extreme combination of all Cool language features"
run_test "all_features_combined" "
class A {};
class B inherits A {};
class C inherits B {
    attr1 : Int <- 10;
    attr2 : String <- \"hello\";
    attr3 : Bool <- true;
    attr4 : SELF_TYPE;
    attr5 : A <- new A;
    attr6 : B <- new B;
    
    method1() : Int { attr1 };
    method2() : String { attr2 };
    method3() : Bool { attr3 };
    method4() : SELF_TYPE { { attr4 <- self; attr4; } };
    method5() : A { attr5 };
    method6() : B { attr6 };
    
    method7(p1 : Int, p2 : String, p3 : Bool, p4 : A, p5 : B, p6 : C) : Int {
        {
            let 
                v1 : Int <- p1 + 5,
                v2 : String <- p2.concat(\" world\"),
                v3 : Bool <- not p3,
                v4 : A <- p4,
                v5 : B <- p5,
                v6 : C <- p6
            in {
                if v3 then
                    while v1 > 0 loop
                        v1 <- v1 - 1
                    pool
                else
                    case v4 of
                        a : A => 1;
                        b : B => 2;
                        c : C => 3;
                        o : Object => 0;
                    esac
                fi;
                
                case v2 of
                    \"hello world\" => 
                        if v1 < 10 then
                            let temp : Int <- v1 * 2 in
                                if temp < 15 then
                                    temp
                                else
                                    temp - 5
                                fi
                        else
                            v1
                        fi;
                    s : String => s.length();
                    o : Object => 0;
                esac;
                
                v6.method1() + v6.method7(v1, v2, v3, v4, v5, v6);
            };
        }
    };
};

class ComplexDataStructure {
    root : Node;
    
    init() : SELF_TYPE {
        {
            root <- (new Node).init(
                \"root\",
                (new Node).init(
                    \"left\",
                    (new Node).init(\"left-left\", new Leaf, new Leaf),
                    (new Node).init(\"left-right\", new Leaf, new Leaf)
                ),
                (new Node).init(
                    \"right\",
                    (new Node).init(\"right-left\", new Leaf, new Leaf),
                    (new Node).init(\"right-right\", new Leaf, new Leaf)
                )
            );
            self;
        }
    };
    
    traverse() : Object {
        let io : IO <- new IO in
            root.print(io)
    };
};

class TreeNode {
    print(io : IO) : Object { io };
};

class Leaf inherits TreeNode {
    print(io : IO) : Object { io.out_string(\".\\n\") };
};

class Node inherits TreeNode {
    value : String;
    left : TreeNode;
    right : TreeNode;
    
    init(v : String, l : TreeNode, r : TreeNode) : Node {
        {
            value <- v;
            left <- l;
            right <- r;
            self;
        }
    };
    
    print(io : IO) : Object {
        {
            io.out_string(value).out_string(\":\\n\");
            io.out_string(\"  left: \");
            left.print(io);
            io.out_string(\"  right: \");
            right.print(io);
            io;
        }
    };
};

class Main {
    main() : Object {
        {
            let 
                a : A <- new A,
                b : B <- new B,
                c : C <- new C,
                complex : ComplexDataStructure <- (new ComplexDataStructure).init(),
                unary : UnaryTest <- new UnaryTest,
                result : Int
            in {
                result <- c.method7(
                    10,
                    \"hello\",
                    true,
                    a, b, c
                );
                
                if result < 100 then
                    complex.traverse()
                else
                    {
                        unary.test();
                        unary.test2();
                        unary.test3();
                    }
                fi;
            };
        }
    };
};
"

# Print summary
echo -e "\n${YELLOW}=== Extreme Edge Case Test Summary ===${NC}"
echo -e "Total tests: $TOTAL"
echo -e "Passed tests: $PASSED"
echo -e "Failed tests: $((TOTAL - PASSED))"

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}All extreme edge case tests passed!${NC}"
else
    echo -e "${RED}Some extreme edge case tests failed.${NC}"
fi

# Cleanup option
read -p "Do you want to keep the extreme test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $EDGE_DIR
    echo "Test files cleaned up."
else
    echo "Test files kept in $EDGE_DIR directory."
fi
