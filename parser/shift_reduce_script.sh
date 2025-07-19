#!/bin/bash

# Specialized testing for shift-reduce conflicts in let expressions
# Based on the Cool language documentation and the provided images, let expressions
# have a potential ambiguity that may manifest as shift-reduce conflicts
#
# According to the documentation mentioned in the images:
# 1. The 'let' construct introduces ambiguity into the language
# 2. The ambiguity is resolved by extending 'let' expressions as far to the right as possible
# 3. This ambiguity may show up as a shift-reduce conflict in the parser
# 4. Using bison features for production precedence may help solve this

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory for test files
SR_DIR="shift_reduce_tests"
mkdir -p $SR_DIR

# Function to run test
run_shift_reduce_test() {
    local test_name=$1
    local test_content=$2
    local test_description=$3
    local test_file="$SR_DIR/$test_name.cl"
    
    echo -e "\n${CYAN}=== SHIFT-REDUCE TEST: $test_name ====${NC}"
    echo -e "${BLUE}Description: $test_description${NC}"
    echo "$test_content" > "$test_file"
    
    # Run parsers
    echo -e "${YELLOW}Running your parser...${NC}"
    ./myparser "$test_file" > "$SR_DIR/my_output.txt" 2>&1
    MY_EXIT=$?
    
    echo -e "${YELLOW}Running reference parser...${NC}"
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$SR_DIR/ref_output.txt" 2>&1
    REF_EXIT=$?
    
    # Interactive comparison
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes differ! Your parser: $MY_EXIT, Reference: $REF_EXIT${NC}"
        return
    fi
    
    # If outputs match exactly, it's a clear pass
    if diff -q "$SR_DIR/my_output.txt" "$SR_DIR/ref_output.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match exactly${NC}"
        return
    fi
    
    # Try ignoring line numbers
    grep -v "line" "$SR_DIR/my_output.txt" > "$SR_DIR/my_output_nolines.txt"
    grep -v "line" "$SR_DIR/ref_output.txt" > "$SR_DIR/ref_output_nolines.txt"
    
    if diff -q "$SR_DIR/my_output_nolines.txt" "$SR_DIR/ref_output_nolines.txt" > /dev/null; then
        echo -e "${GREEN}PASS: Outputs match when ignoring line numbers${NC}"
        return
    fi
    
    # Outputs differ - show details and ask for verification
    echo -e "${YELLOW}Outputs differ - manual verification needed${NC}"
    echo -e "Your parser output:"
    cat "$SR_DIR/my_output.txt"
    echo -e "\nReference parser output:"
    cat "$SR_DIR/ref_output.txt"
    
    echo -e "\n${YELLOW}This test specifically targets potential shift-reduce conflicts in let expressions.${NC}"
    echo -e "${YELLOW}Examine the parse trees to see if the associativity is handled correctly.${NC}"
    
    read -p "Is this test passing despite the differences? (y/n): " manual_verify
    if [ "$manual_verify" = "y" ]; then
        echo -e "${GREEN}PASS: Manually verified${NC}"
    else
        echo -e "${RED}FAIL: Test failed manual verification${NC}"
        echo -e "${YELLOW}This likely indicates a shift-reduce conflict in your let handling.${NC}"
    fi
}

# ===== SHIFT-REDUCE CONFLICT TEST CASES =====

# 1. Basic let expression
echo "Shift-Reduce Test 1: Basic let expression"
run_shift_reduce_test "sr_basic_let" "
class Test {
    test() : Int {
        let x : Int <- 5 in x + 3
    };
};
" "Basic let expression with a simple body"

# 2. Nested let expressions with right association
echo "Shift-Reduce Test 2: Nested let expressions (right association)"
run_shift_reduce_test "sr_nested_let" "
class Test {
    test() : Int {
        let x : Int <- 5 in let y : Int <- 10 in x + y
    };
};
" "Nested lets should associate to the right - 'let x in (let y in expr)'"

# 3. Let with nested let in initialization
echo "Shift-Reduce Test 3: Let with nested let in initialization"
run_shift_reduce_test "sr_let_in_init" "
class Test {
    test() : Int {
        let x : Int <- let y : Int <- 5 in y + 1 in x * 2
    };
};
" "Let with another let in the initialization expression"

# 4. Let with binary operation and confusion about what belongs to what
echo "Shift-Reduce Test 4: Let with binary operation"
run_shift_reduce_test "sr_let_binop" "
class Test {
    test() : Int {
        5 + let x : Int <- 10 in x * 2
    };
};
" "Let within a binary operation - ambiguity about association"

# 5. Multiple lets with binops
echo "Shift-Reduce Test 5: Multiple lets with binary operations"
run_shift_reduce_test "sr_multiple_let_binop" "
class Test {
    test() : Int {
        let x : Int <- 5 in x + let y : Int <- 10 in y * 2
    };
};
" "Multiple lets intermixed with binary operations - tests right association"

# 6. Let that could be ambiguous with if-then-else
echo "Shift-Reduce Test 6: Let with if-then-else"
run_shift_reduce_test "sr_let_if" "
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
" "Let containing if-then-else that contains more lets - tests nested scoping"

# 7. Let with left-recursive expression that might cause SR conflict
echo "Shift-Reduce Test 7: Let with left-recursive expression"
run_shift_reduce_test "sr_let_left_recursive" "
class Test {
    test() : Int {
        let a : Int <- 1 in
            a + let b : Int <- 2 in
                b + let c : Int <- 3 in
                    c
    };
};
" "Left-recursive expression with lets - tests precedence and association"

# 8. Complex nested let expression
echo "Shift-Reduce Test 8: Complex nested let expression"
run_shift_reduce_test "sr_complex_let" "
class Test {
    test() : Int {
        let a : Int <- 1,
            b : Int <- let c : Int <- 2,
                       d : Int <- 3
                      in c + d,
            e : Int <- let f : Int <- 4 in f
        in a + b + e
    };
};
" "Complex let with multiple variables and nested lets in initializers"

# 9. Let with case expression
echo "Shift-Reduce Test 9: Let with case expression"
run_shift_reduce_test "sr_let_case" "
class Test {
    test(obj : Object) : Int {
        let x : Int <- 5 in
            case obj of
                i : Int => i + x;
                s : String => let l : Int <- s.length() in l;
                o : Object => 0;
            esac
    };
};
" "Let with case that includes another let - tests nested scope handling"

# 10. Let with block expression
echo "Shift-Reduce Test 10: Let with block expression"
run_shift_reduce_test "sr_let_block" "
class Test {
    test() : Int {
        let x : Int <- 5 in {
            let y : Int <- 10 in y + 1;
            let z : Int <- 15 in z + 2;
            x + 3;
        }
    };
};
" "Let with block that contains more lets - tests block vs. let scoping"

# 11. Let with method dispatch
echo "Shift-Reduce Test 11: Let with method dispatch"
run_shift_reduce_test "sr_let_dispatch" "
class Test {
    getNum() : Int { 42 };
    
    test() : Int {
        let x : Int <- 5 in self.getNum() + let y : Int <- 10 in y
    };
};
" "Let with method dispatch - tests precedence with method calls"

# 12. Let with unary operators
echo "Shift-Reduce Test 12: Let with unary operators"
run_shift_reduce_test "sr_let_unary" "
class Test {
    test() : Int {
        let x : Int <- 5 in ~ let y : Int <- 10 in isvoid y
    };
};
" "Let with unary operators - tests precedence with unary ops"

# 13. Let with multi-line and comments to stress the parser
echo "Shift-Reduce Test 13: Let with multi-line and comments"
run_shift_reduce_test "sr_let_multiline" "
class Test {
    test() : Int {
        let 
            -- This is x
            x : Int <- 5, 
            
            (* This
               is 
               y *)
            y : Int <- 
                (* nested comment *)
                10
            
            -- End of variables
        in 
            -- Expression starts here
            x + y
            -- Expression ends here
    };
};
" "Let with multi-line formatting and comments - tests lexer/parser interaction"

# 14. Let with very complex expression
echo "Shift-Reduce Test 14: Let with very complex expression"
run_shift_reduce_test "sr_let_complex_expr" "
class Test {
    test() : Int {
        let x : Int <- 5 in
            if let y : Int <- 10 in y > x then
                case let z : String <- \"hello\" in z of
                    \"hello\" => let a : Int <- 20 in a;
                    s : String => s.length();
                    o : Object => 0;
                esac
            else
                let b : Int <- 30 in
                    while let c : Int <- b in c > 0 loop
                        let d : Int <- c - 1 in
                            b <- d
                    pool
            fi
    };
};
" "Let with extremely complex nested expression - combines multiple constructs"

# 15. Let with ambiguous binding examples from documentation
echo "Shift-Reduce Test 15: Let with ambiguous binding examples"
run_shift_reduce_test "sr_let_ambiguous" "
class Test {
    test1() : Int {
        -- This should parse as: let x:Int <- 1 in (x + (let y:Int <- 2 in y))
        let x : Int <- 1 in x + let y : Int <- 2 in y
    };
    
    test2() : Int {
        -- This should parse as: let x:Int <- (let y:Int <- 1 in y) in x
        let x : Int <- let y : Int <- 1 in y in x
    };
    
    test3() : Int {
        -- This should parse as: (5 + (let x:Int <- 10 in x))
        5 + let x : Int <- 10 in x
    };
};
" "Examples that demonstrate the let binding ambiguity described in documentation"

# Print summary
echo -e "\n${YELLOW}=== Shift-Reduce Conflict Test Summary ===${NC}"
echo -e "All shift-reduce tests have been run."
echo -e "These tests specifically target the let expression ambiguity mentioned in the documentation."
echo -e "Any differences in output might indicate shift-reduce conflicts in your parser."

# Cleanup option
read -p "Do you want to keep the shift-reduce test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $SR_DIR
    echo "Shift-reduce test files cleaned up."
else
    echo "Shift-reduce test files kept in $SR_DIR directory."
fi
