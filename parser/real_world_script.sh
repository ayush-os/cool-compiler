#!/bin/bash

# This script tests your parser against real-world Cool programs

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory for test files
TEST_DIR="real_world_tests"
mkdir -p $TEST_DIR

# Track results
TOTAL=0
PASSED=0

# Function to run a test on a given file
test_file() {
    local filename=$1
    local description=$2
    
    echo -e "\n${BLUE}Testing: $filename - $description${NC}"
    TOTAL=$((TOTAL + 1))
    
    # Run your parser
    ./myparser "$filename" > "$TEST_DIR/my_output.txt" 2>&1
    MY_EXIT=$?
    
    # Run reference parser
    ./lexer "$filename" | /afs/ir/class/cs143/bin/parser > "$TEST_DIR/ref_output.txt" 2>&1
    REF_EXIT=$?
    
    # Compare exit codes
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes don't match! Your parser: $MY_EXIT, Reference: $REF_EXIT${NC}"
        return
    fi
    
    # Compare outputs
    if diff -q "$TEST_DIR/my_output.txt" "$TEST_DIR/ref_output.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match exactly${NC}"
        PASSED=$((PASSED + 1))
        return
    fi
    
    # Ignore line numbers in comparison
    grep -v "line" "$TEST_DIR/my_output.txt" > "$TEST_DIR/my_output_nolines.txt"
    grep -v "line" "$TEST_DIR/ref_output.txt" > "$TEST_DIR/ref_output_nolines.txt"
    
    if diff -q "$TEST_DIR/my_output_nolines.txt" "$TEST_DIR/ref_output_nolines.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match (ignoring line numbers)${NC}"
        PASSED=$((PASSED + 1))
        return
    else
        echo -e "${YELLOW}OUTPUTS DIFFER (beyond just line numbers)${NC}"
        echo -e "Your parser output:"
        cat "$TEST_DIR/my_output.txt"
        echo -e "\nReference parser output:"
        cat "$TEST_DIR/ref_output.txt"
        
        read -p "Manually verify: Are these differences acceptable? (y/n): " verify
        if [ "$verify" = "y" ]; then
            echo -e "${GREEN}PASS: Manually verified${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAIL: Test failed manual verification${NC}"
        fi
    fi
}

# Create some complex real-world Cool programs

# 1. List implementation
cat > "$TEST_DIR/list.cl" << 'EOL'
class List {
    isNil() : Bool { true };
    
    head()  : String { { abort(); ""; } };
    
    tail()  : List { { abort(); self; } };
    
    cons(i : String) : List {
        (new Cons).init(i, self)
    };
};

class Cons inherits List {
    car : String;
    cdr : List;
    
    isNil() : Bool { false };
    
    head()  : String { car };
    
    tail()  : List { cdr };
    
    init(i : String, rest : List) : List {
        {
            car <- i;
            cdr <- rest;
            self;
        }
    };
};

class Main {
    mylist : List;
    
    main() : Object {
        {
            mylist <- new List.cons("Hello").cons("World").cons("Cool");
            let current : List <- mylist in
                while (not current.isNil()) loop
                {
                    (new IO).out_string(current.head()).out_string("\n");
                    current <- current.tail();
                }
                pool;
        }
    };
};
EOL

# 2. Binary tree implementation
cat > "$TEST_DIR/binary_tree.cl" << 'EOL'
class BinaryTree {
    value : Int;
    left : BinaryTree;
    right : BinaryTree;
    
    init(v : Int) : BinaryTree {
        {
            value <- v;
            left <- new EmptyTree;
            right <- new EmptyTree;
            self;
        }
    };
    
    insert(v : Int) : BinaryTree {
        if v < value then
            {
                if left.isEmpty() then
                    left <- (new BinaryTree).init(v)
                else
                    left.insert(v)
                fi;
                self;
            }
        else
            {
                if right.isEmpty() then
                    right <- (new BinaryTree).init(v)
                else
                    right.insert(v)
                fi;
                self;
            }
        fi
    };
    
    isEmpty() : Bool { false };
    
    inorder() : Object {
        {
            if not left.isEmpty() then left.inorder() else 0 fi;
            (new IO).out_int(value).out_string(" ");
            if not right.isEmpty() then right.inorder() else 0 fi;
        }
    };
};

class EmptyTree inherits BinaryTree {
    isEmpty() : Bool { true };
    
    insert(v : Int) : BinaryTree {
        (new BinaryTree).init(v)
    };
    
    inorder() : Object { 0 };
};

class Main {
    tree : BinaryTree;
    
    main() : Object {
        {
            tree <- (new BinaryTree).init(50)
                .insert(30).insert(70).insert(20)
                .insert(40).insert(60).insert(80);
            tree.inorder();
            (new IO).out_string("\n");
        }
    };
};
EOL

# 3. Simple calculator with various expressions
cat > "$TEST_DIR/calculator.cl" << 'EOL'
class Calculator {
    io : IO <- new IO;
    
    add(x : Int, y : Int) : Int { x + y };
    
    subtract(x : Int, y : Int) : Int { x - y };
    
    multiply(x : Int, y : Int) : Int { x * y };
    
    divide(x : Int, y : Int) : Int {
        if y = 0 then {
            io.out_string("Error: Division by zero\n");
            0;
        } else
            x / y
        fi
    };
    
    run() : Object {
        let running : Bool <- true,
            x : Int,
            y : Int,
            op : String,
            result : Int
        in {
            while running loop {
                io.out_string("Enter first number: ");
                x <- (new A2I).a2i(io.in_string());
                
                io.out_string("Enter operator (+,-,*,/): ");
                op <- io.in_string();
                
                io.out_string("Enter second number: ");
                y <- (new A2I).a2i(io.in_string());
                
                if op = "+" then
                    result <- add(x, y)
                else if op = "-" then
                    result <- subtract(x, y)
                else if op = "*" then
                    result <- multiply(x, y)
                else if op = "/" then
                    result <- divide(x, y)
                else
                    io.out_string("Invalid operator\n")
                fi fi fi fi;
                
                io.out_string("Result: ").out_int(result).out_string("\n");
                
                io.out_string("Continue? (y/n): ");
                if io.in_string() = "n" then
                    running <- false
                else
                    0
                fi;
            } pool;
            
            io.out_string("Calculator terminated.\n");
        }
    };
};

class A2I {
    c2i(char : String) : Int {
        if char = "0" then 0 else
        if char = "1" then 1 else
        if char = "2" then 2 else
        if char = "3" then 3 else
        if char = "4" then 4 else
        if char = "5" then 5 else
        if char = "6" then 6 else
        if char = "7" then 7 else
        if char = "8" then 8 else
        if char = "9" then 9 else
        { abort(); 0; }
        fi fi fi fi fi fi fi fi fi fi
    };
    
    a2i(s : String) : Int {
        if s.length() = 0 then 0 else
        if s.substr(0, 1) = "-" then ~a2i_aux(s.substr(1, s.length() - 1)) else
        if s.substr(0, 1) = "+" then a2i_aux(s.substr(1, s.length() - 1)) else
           a2i_aux(s)
        fi fi fi
    };
    
    a2i_aux(s : String) : Int {
        let int : Int <- 0 in {
            let j : Int <- s.length() in
                let i : Int <- 0 in
                    while i < j loop {
                        int <- int * 10 + c2i(s.substr(i, 1));
                        i <- i + 1;
                    } pool;
            int;
        }
    };
};

class Main {
    main() : Object {
        (new Calculator).run()
    };
};
EOL

# 4. Complex inheritance and method dispatch
cat > "$TEST_DIR/inheritance.cl" << 'EOL'
class A {
    var : Int <- 10;
    
    method1() : Int { var };
    
    method2(x : Int) : Int { var + x };
};

class B inherits A {
    var2 : Int <- 20;
    
    method1() : Int { var * 2 };
    
    method3() : Int { var + var2 };
};

class C inherits B {
    var3 : Int <- 30;
    
    method4() : Int { var + var2 + var3 };
    
    method1() : Int { var * 3 };
};

class D {
    a_obj : A <- new A;
    b_obj : B <- new B;
    c_obj : C <- new C;
    
    test() : Object {
        let io : IO <- new IO in {
            io.out_string("A.method1(): ").out_int(a_obj.method1()).out_string("\n");
            io.out_string("B.method1(): ").out_int(b_obj.method1()).out_string("\n");
            io.out_string("C.method1(): ").out_int(c_obj.method1()).out_string("\n");
            io.out_string("A.method2(5): ").out_int(a_obj.method2(5)).out_string("\n");
            io.out_string("B.method3(): ").out_int(b_obj.method3()).out_string("\n");
            io.out_string("C.method4(): ").out_int(c_obj.method4()).out_string("\n");
        }
    };
};

class Main {
    main() : Object {
        (new D).test()
    };
};
EOL

# 5. Complex expressions with nested if/case/while
cat > "$TEST_DIR/complex_expressions.cl" << 'EOL'
class Complex {
    io : IO <- new IO;
    
    test_if_expressions(x : Int) : Int {
        if x < 0 then
            if x < -10 then
                -20
            else
                if x = -5 then
                    -5
                else
                    -10
                fi
            fi
        else
            if x = 0 then
                0
            else
                if x < 10 then
                    if x < 5 then
                        x * 2
                    else
                        x + 5
                    fi
                else
                    x
                fi
            fi
        fi
    };
    
    test_while(n : Int) : Int {
        let sum : Int <- 0,
            i : Int <- 1
        in {
            while i <= n loop {
                sum <- sum + i;
                i <- i + 1;
                while sum > 100 loop
                    sum <- sum - 10
                pool;
            } pool;
            sum;
        }
    };
    
    test_case(obj : Object) : String {
        case obj of
            i : Int => 
                if i = 0 then
                    "zero"
                else
                    if i > 0 then
                        "positive"
                    else
                        "negative"
                    fi
                fi;
            s : String =>
                case s.length() of
                    0 : Int => "empty";
                    1 : Int => "single character";
                    len : Int => 
                        if len < 5 then
                            "short"
                        else
                            if len < 10 then
                                "medium"
                            else
                                "long"
                            fi
                        fi;
                esac;
            b : Bool => 
                if b then "true" else "false" fi;
            o : Object => "unknown";
        esac
    };
    
    test_let() : Int {
        let 
            a : Int <- 5,
            b : Int <- let c : Int <- 10 in c * 2,
            d : Int <- 
                let e : Int <- 7,
                    f : Int <- 3
                in
                    let g : Int <- e + f in
                        g * a
        in a + b + d
    };
    
    run() : Object {
        {
            io.out_string("Test if expressions: ").out_int(test_if_expressions(7)).out_string("\n");
            io.out_string("Test while loop: ").out_int(test_while(10)).out_string("\n");
            io.out_string("Test case 1: ").out_string(test_case(5)).out_string("\n");
            io.out_string("Test case 2: ").out_string(test_case("hello")).out_string("\n");
            io.out_string("Test let: ").out_int(test_let()).out_string("\n");
        }
    };
};

class Main {
    main() : Object {
        (new Complex).run()
    };
};
EOL

# 6. Test with syntax errors for error recovery
cat > "$TEST_DIR/error_recovery.cl" << 'EOL'
class ErrorTest1 {
    -- Missing semicolon after attribute
    x : Int <- 10
    
    -- This should still be parsed after error recovery
    method1() : Int { x + 5 };
};

class ErrorTest2 {
    -- Correctly defined attribute
    y : Int <- 20;
    
    -- Error in method parameter
    method2(a : Int, b : ) : Int {
        a + b
    };
    
    -- This should be parsed after error recovery
    method3() : String { "recovery worked" };
};

class ErrorTest3 {
    -- Error in let expression
    test_let() : Int {
        let x : Int <- 5,
            y : <- 10  -- Missing type
        in x + y
    };
    
    -- This should still be parsed
    valid_method() : Int { 42 };
};

class Main {
    main() : Object {
        {
            -- Error in if expression
            if 5 > then
                (new IO).out_string("Error in if\n")
            else
                (new IO).out_string("Else branch\n")
            fi;
            
            -- Correctly formed expression
            (new IO).out_string("Program completed\n");
        }
    };
};
EOL

# Run the tests
echo -e "\n${YELLOW}Starting Real-World Cool Program Tests${NC}"

test_file "$TEST_DIR/list.cl" "List implementation with inheritance"
test_file "$TEST_DIR/binary_tree.cl" "Binary tree implementation"
test_file "$TEST_DIR/calculator.cl" "Calculator with various expressions"
test_file "$TEST_DIR/inheritance.cl" "Complex inheritance and method dispatch"
test_file "$TEST_DIR/complex_expressions.cl" "Nested if/case/while/let expressions"
test_file "$TEST_DIR/error_recovery.cl" "Error recovery tests"

# Summary
echo -e "\n${YELLOW}=== Test Summary ===${NC}"
echo -e "Total tests: $TOTAL"
echo -e "Passed tests: $PASSED"
echo -e "Failed tests: $((TOTAL - PASSED))"

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}All real-world tests passed!${NC}"
else
    echo -e "${RED}Some real-world tests failed.${NC}"
fi

# Cleanup
read -p "Do you want to keep the real-world test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $TEST_DIR
    echo "Test files cleaned up."
else
    echo "Test files kept in $TEST_DIR directory."
fi
