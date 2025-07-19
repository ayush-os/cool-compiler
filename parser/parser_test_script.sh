#!/bin/bash

# Comprehensive Test Suite for Cool Parser
# This script tests various aspects of the Cool parser including:
# - Basic class definitions
# - Features (methods and attributes)
# - Error recovery
# - Let expressions and their ambiguity
# - Nested let expressions
# - Expressions and operations with proper precedence

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Create temporary directory for test files
TEMP_DIR="parser_test_temp"
mkdir -p $TEMP_DIR

# Function to compare parser outputs and handle line number differences
compare_outputs() {
    local test_name=$1
    local test_file=$2
    
    echo -e "\n${YELLOW}Running test: ${test_name}${NC}"
    
    # Run your parser and the reference parser
    ./myparser "$test_file" > "$TEMP_DIR/my_output.txt" 2>&1
    MY_EXIT_CODE=$?
    
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$TEMP_DIR/ref_output.txt" 2>&1
    REF_EXIT_CODE=$?
    
    # Check if exit codes match
    if [ $MY_EXIT_CODE -ne $REF_EXIT_CODE ]; then
        echo -e "${RED}FAIL: Exit codes don't match. Your parser: $MY_EXIT_CODE, Reference: $REF_EXIT_CODE${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        return
    fi
    
    # Compare outputs
    if diff -q "$TEMP_DIR/my_output.txt" "$TEMP_DIR/ref_output.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match exactly${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        # Remove line numbers from both outputs for comparison
        grep -v "line" "$TEMP_DIR/my_output.txt" > "$TEMP_DIR/my_output_no_line.txt"
        grep -v "line" "$TEMP_DIR/ref_output.txt" > "$TEMP_DIR/ref_output_no_line.txt"
        
        if diff -q "$TEMP_DIR/my_output_no_line.txt" "$TEMP_DIR/ref_output_no_line.txt" > /dev/null; then
            echo -e "${GREEN}PASS: Outputs match (ignoring line numbers)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
        else
            echo -e "${RED}FAIL: Outputs don't match even ignoring line numbers${NC}"
            echo "Your parser output:"
            cat "$TEMP_DIR/my_output.txt"
            echo -e "\nReference parser output:"
            cat "$TEMP_DIR/ref_output.txt"
            
            read -p "Do you want to manually verify this test? (y/n): " manual_verify
            if [ "$manual_verify" = "y" ]; then
                read -p "Is this test passing despite the differences? (y/n): " is_passing
                if [ "$is_passing" = "y" ]; then
                    echo -e "${GREEN}Manually verified as PASS${NC}"
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                else
                    echo -e "${RED}Manually verified as FAIL${NC}"
                fi
            else
                echo -e "${RED}Test marked as FAIL${NC}"
            fi
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
        fi
    fi
}

# Function to create a test file and run the test
create_and_test() {
    local test_name=$1
    local test_content=$2
    local test_file="$TEMP_DIR/$test_name.cl"
    
    echo "$test_content" > "$test_file"
    compare_outputs "$test_name" "$test_file"
}

# ===== TEST CASES =====

# 1. Basic class definition
echo "Test 1: Basic class definition"
create_and_test "basic_class" "
class Main {
    main() : Int { 0 };
};
"

# 2. Multiple classes
echo "Test 2: Multiple classes"
create_and_test "multiple_classes" "
class A {
    a : Int;
    method1() : Int { 1 };
};

class B inherits A {
    b : String;
    method2(x : Int) : Int { x + 1 };
};

class Main {
    main() : Int { 0 };
};
"

# 3. Class with features
echo "Test 3: Class with various features"
create_and_test "class_features" "
class Complex {
    x : Int <- 0;
    y : Int <- 0;
    
    init(a : Int, b : Int) : Complex {
        {
            x <- a;
            y <- b;
            self;
        }
    };
    
    add(other : Complex) : Complex {
        (new Complex).init(x + other.getX(), y + other.getY())
    };
    
    getX() : Int { x };
    getY() : Int { y };
};
"

# 4. Error in class definition but with recovery
echo "Test 4: Error recovery in class definition"
create_and_test "error_class_recovery" "
class A {
    a : Int
    method1() : Int { 1 };
};

class B {
    b : String;
    method2() : Int { 2 };
};
"

# 5. Error in feature but with recovery
echo "Test 5: Error recovery in feature"
create_and_test "error_feature_recovery" "
class TestFeatureError {
    x : Int <- 0;
    
    broken_method(a : Int, b Int) : Int {
        a + b
    };
    
    good_method() : Int { 0 };
};
"

# 6. Let expression
echo "Test 6: Let expression"
create_and_test "let_expression" "
class LetTest {
    test() : Int {
        let x : Int <- 5 in x + 3
    };
};
"

# 7. Let with multiple variables
echo "Test 7: Let with multiple variables"
create_and_test "let_multiple" "
class LetMultiple {
    test() : Int {
        let x : Int <- 5, y : Int <- 10 in x + y
    };
};
"

# 8. Nested let expressions
echo "Test 8: Nested let expressions"
create_and_test "nested_let" "
class NestedLet {
    test() : Int {
        let x : Int <- 5 in
            let y : Int <- x * 2 in
                let z : Int <- y + 3 in
                    x + y + z
    };
};
"

# 9. Let ambiguity test
echo "Test 9: Let ambiguity"
create_and_test "let_ambiguity" "
class LetAmbiguity {
    test() : Int {
        let x : Int <- 5 in x + let y : Int <- 10 in y
    };
};
"

# 10. Expression precedence test
echo "Test 10: Expression precedence"
create_and_test "expr_precedence" "
class ExprPrecedence {
    test() : Int {
        ~5 * 3 + 4 / 2 - 1
    };
    
    test2() : Bool {
        5 <= 3 + 2 && not 4 = 3 || true
    };
};
"

# 11. If-then-else expressions
echo "Test 11: If-then-else expressions"
create_and_test "if_then_else" "
class IfTest {
    test(x : Int) : Int {
        if x < 0 then ~x else x fi
    };
    
    test2(x : Int, y : Int) : Int {
        if x < y then
            if x < 0 then 0 else x fi
        else
            if y < 0 then 0 else y fi
        fi
    };
};
"

# 12. While loop expressions
echo "Test 12: While loop expressions"
create_and_test "while_loop" "
class WhileTest {
    countdown(x : Int) : Int {
        {
            let count : Int <- x in
                while 0 < count loop
                    count <- count - 1
                pool;
            0;
        }
    };
};
"

# 13. Complex expression with block
echo "Test 13: Complex expression with block"
create_and_test "complex_block" "
class BlockTest {
    test() : Int {
        {
            let x : Int <- 5 in
                x + 3;
            let y : String <- \"hello\" in
                y.length();
            if true then 1 else 0 fi;
            42;
        }
    };
};
"

# 14. Case expression
echo "Test 14: Case expression"
create_and_test "case_expr" "
class CaseTest {
    test(x : Object) : Int {
        case x of
            i : Int => i;
            s : String => s.length();
            o : Object => 0;
        esac
    };
};
"

# 15. Error in expression block with recovery
echo "Test 15: Error recovery in expression block"
create_and_test "error_expr_recovery" "
class ExprErrorTest {
    test() : Int {
        {
            let x : Int <- 5 in
                x + *;  -- Error here
            42;
        }
    };
};
"

# 16. Error in let binding with recovery
echo "Test 16: Error recovery in let binding"
create_and_test "error_let_recovery" "
class LetErrorTest {
    test() : Int {
        let x : Int <- 5, y : = 10 in  -- Error here
            x + 10
    };
};
"

# 17. Combining all features
echo "Test 17: Combining all features"
create_and_test "all_features" "
class Main {
    main() : Int {
        {
            let x : Int <- 5,
                y : Int <- 10,
                z : Int <- x + y
            in
                if z < 20 then
                    while z < 20 loop
                        z <- z + 1
                    pool
                else
                    case z of
                        i : Int => i;
                        s : String => 0;
                    esac
                fi;
            
            (new IO).out_string(\"Hello, world!\");
            0;
        }
    };
};

class Misc {
    attr1 : Int <- 0;
    attr2 : String;
    
    method1(a : Int, b : Int) : Int {
        a + b
    };
    
    method2() : Bool {
        attr1 <= 0 && not (attr2.length() = 0)
    };
};
"

# 18. Deeply nested expressions
echo "Test 18: Deeply nested expressions"
create_and_test "deep_nesting" "
class DeepNest {
    test() : Int {
        1 + (2 * (3 + (4 * (5 + (6 * 7)))))
    };
};
"

# 19. Very long identifier names
echo "Test 19: Very long identifier names"
create_and_test "long_identifiers" "
class VeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongClassName {
    veryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongAttributeName : Int;
    
    veryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongMethodName(
        veryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongParameterName : Int
    ) : Int {
        veryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryVeryLongParameterName + 1
    };
};
"

# 20. Empty class
echo "Test 20: Empty class"
create_and_test "empty_class" "
class Empty {
};
"

# Print summary
echo -e "\n${YELLOW}========== TEST SUMMARY ==========${NC}"
echo -e "Total tests: $TOTAL_TESTS"
echo -e "Passed tests: $PASSED_TESTS"
echo -e "Failed tests: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Some tests failed.${NC}"
fi

# Clean up
read -p "Do you want to keep the test files? (y/n): " keep_files
if [ "$keep_files" != "y" ]; then
    rm -rf $TEMP_DIR
    echo "Test files cleaned up."
else
    echo "Test files kept in $TEMP_DIR directory."
fi
