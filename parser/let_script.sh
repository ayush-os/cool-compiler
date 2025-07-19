#!/bin/bash

# This script specifically tests let expression ambiguity handling
# Based on the images you shared, let expressions have ambiguity that should be
# resolved by extending as far to the right as possible.

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory for test files
LET_TEST_DIR="let_ambiguity_tests"
mkdir -p $LET_TEST_DIR

# Function to compare parser outputs
run_let_test() {
    local test_name=$1
    local test_content=$2
    local test_file="$LET_TEST_DIR/$test_name.cl"
    
    echo -e "\n${BLUE}=== Let Ambiguity Test: $test_name ===${NC}"
    echo "$test_content" > "$test_file"
    
    # Run parsers
    echo -e "${YELLOW}Running your parser...${NC}"
    ./myparser "$test_file" > "$LET_TEST_DIR/my_output.txt" 2>&1
    MY_EXIT=$?
    
    echo -e "${YELLOW}Running reference parser...${NC}"
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$LET_TEST_DIR/ref_output.txt" 2>&1
    REF_EXIT=$?
    
    # Compare outputs
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes differ! Your parser: $MY_EXIT, Reference: $REF_EXIT${NC}"
        return
    fi
    
    # Check if outputs match exactly
    if diff -q "$LET_TEST_DIR/my_output.txt" "$LET_TEST_DIR/ref_output.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match exactly${NC}"
        return
    fi
    
    # Show differences and verify manually
    echo -e "${YELLOW}Outputs differ - manual verification needed${NC}"
    echo -e "Your parser output:"
    cat "$LET_TEST_DIR/my_output.txt"
    echo -e "\nReference parser output:"
    cat "$LET_TEST_DIR/ref_output.txt"
    
    read -p "Do these differences only involve line numbers? (y/n): " only_lines
    if [ "$only_lines" = "y" ]; then
        echo -e "${GREEN}PASS: Differences are only in line numbers${NC}"
    else
        echo -e "${RED}FAIL: Parser outputs differ beyond line numbers${NC}"
        
        # Ask for explanation to help debugging
        echo -e "${YELLOW}Based on what you see, what might be the issue in your parser?${NC}"
        read -p "> " explanation
        echo "Noted: $explanation"
    fi
}

# ===== TEST CASES FOR LET AMBIGUITY =====

# 1. Basic let expression
echo "Let Test 1: Basic let expression"
run_let_test "let_basic" "
class Test {
    test() : Int {
        let x : Int <- 5 in x + 3
    };
};
"

# 2. Multiple variables in let
echo "Let Test 2: Multiple variables in let"
run_let_test "let_multi_vars" "
class Test {
    test() : Int {
        let x : Int <- 5, 
            y : Int <- 10, 
            z : Int <- 15 
        in x + y + z
    };
};
"

# 3. Let with another let in body (should extend right)
echo "Let Test 3: Let with another let in body (right association)"
run_let_test "let_in_body" "
class Test {
    test() : Int {
        let x : Int <- 5 in 
            let y : Int <- 10 in x + y
    };
};
"

# 4. Let with another let in initialization
echo "Let Test 4: Let with another let in initialization"
run_let_test "let_in_init" "
class Test {
    test() : Int {
        let x : Int <- let y : Int <- 5 in y * 2,
            z : Int <- 10
        in x + z
    };
};
"

# 5. Let with binary operation and precedence
echo "Let Test 5: Let with binary operation and precedence"
run_let_test "let_with_binop" "
class Test {
    test() : Int {
        5 + let x : Int <- 10 in x * 2
    };
};
"

# 6. Let with mixed expressions
echo "Let Test 6: Let with mixed expressions"
run_let_test "let_mixed" "
class Test {
    test() : Int {
        let x : Int <- 5 in x + let y : Int <- 10 in y * 2 - 3
    };
};
"

# 7. Complex let with if-then-else
echo "Let Test 7: Complex let with if-then-else"
run_let_test "let_with_if" "
class Test {
    test() : Int {
        let x : Int <- 5 in
            if x < 10 then
                let y : Int <- 20 in y
            else
                let z : Int <- 30 in z
            fi
    };
};
"

# 8. Multiple nested lets in different positions
echo "Let Test 8: Multiple nested lets in different positions"
run_let_test "multiple_nested_lets" "
class Test {
    test() : Int {
        let a : Int <- 1 in
        let b : Int <- 2 in
        let c : Int <- 3 in
            a + b + c +
            (let d : Int <- 4 in d) +
            let e : Int <- 5 in e
    };
};
"

# 9. Deeply nested let expressions
echo "Let Test 9: Deeply nested let expressions"
run_let_test "deeply_nested_lets" "
class Test {
    test() : Int {
        let a : Int <- 1 in
            let b : Int <- 2 in
                let c : Int <- 3 in
                    let d : Int <- 4 in
                        let e : Int <- 5 in
                            a + b + c + d + e
    };
};
"

# 10. Let as part of larger expressions
echo "Let Test 10: Let as part of larger expressions"
run_let_test "let_in_larger_expr" "
class Test {
    test() : Int {
        (5 + let x : Int <- 10 in x) * 
        (20 - let y : Int <- 5 in 
            let z : Int <- 3 in y + z)
    };
};
"

# 11. Let with case expression
echo "Let Test 11: Let with case expression"
run_let_test "let_with_case" "
class Test {
    test(obj : Object) : Int {
        let x : Int <- 5 in
            case obj of
                i : Int => i + x;
                s : String => let l : Int <- s.length() in l + x;
                o : Object => 0;
            esac
    };
};
"

# 12. Let with multiple identifiers (should be transformed to nested lets)
echo "Let Test 12: Let with multiple identifiers"
run_let_test "let_multi_identifiers" "
class Test {
    test() : Int {
        let x : Int <- 5, y : Int <- 10 in x + y
    };
};
"

# 13. Mixed associativity test
echo "Let Test 13: Mixed associativity test"
run_let_test "let_mixed_assoc" "
class Test {
    test() : Int {
        let x : Int <- 1 in x +
        let y : Int <- 2 in y +
        let z : Int <- 3 in z
    };
};
"

# 14. Let in method body with complex expressions
echo "Let Test 14: Let in method body with complex expressions"
run_let_test "let_complex_method" "
class LetTest {
    attr1 : Int <- 100;
    
    test() : Int {
        {
            let x : Int <- 5,
                y : Int <- attr1
            in {
                let temp : Int <- x + y in
                    while temp < 200 loop
                        temp <- temp * 2
                    pool;
                
                if y < 150 then
                    let z : Int <- 30 in z
                else
                    let w : Int <- 40 in w
                fi;
            };
        }
    };
};
"

# 15. Let with parse error and recovery
echo "Let Test 15: Let with parse error and recovery"
run_let_test "let_error_recovery" "
class LetErrorTest {
    test() : Int {
        {
            let x : Int <- in x + 1;  -- Missing initializer
            
            -- This should be recovered
            let y : Int <- 42 in y;
        }
    };
};
"

# Summary
echo -e "\n${YELLOW}====================================${NC}"
echo -e "${YELLOW}Let Ambiguity Test Suite Completed${NC}"
echo -e "${YELLOW}====================================${NC}"
echo -e "Check the above results to verify your parser's handling of let expressions."
echo -e "All test files are in the '${LET_TEST_DIR}' directory."

# Cleanup option
read -p "Do you want to keep the let test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $LET_TEST_DIR
    echo "Let test files cleaned up."
else
    echo "Let test files kept in $LET_TEST_DIR directory."
fi
