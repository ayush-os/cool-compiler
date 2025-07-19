#!/bin/bash

# Create temp directory if it doesn't exist
TEMP_DIR="specialized_tests"
mkdir -p $TEMP_DIR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run test similar to the main script
run_test() {
    local test_name=$1
    local test_content=$2
    local test_file="$TEMP_DIR/$test_name.cl"
    
    echo -e "\n${YELLOW}Running specialized test: ${test_name}${NC}"
    echo "$test_content" > "$test_file"
    
    # Run parsers
    ./myparser "$test_file" > "$TEMP_DIR/my_output.txt" 2>&1
    MY_EXIT_CODE=$?
    
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$TEMP_DIR/ref_output.txt" 2>&1
    REF_EXIT_CODE=$?
    
    # Interactive comparison
    if [ $MY_EXIT_CODE -ne $REF_EXIT_CODE ]; then
        echo -e "${RED}FAIL: Exit codes don't match. Your parser: $MY_EXIT_CODE, Reference: $REF_EXIT_CODE${NC}"
        return
    fi
    
    if ! diff -q "$TEMP_DIR/my_output.txt" "$TEMP_DIR/ref_output.txt" > /dev/null; then
        echo -e "${YELLOW}Outputs differ - checking if it's just line numbers...${NC}"
        # Display differences
        echo -e "Your parser output:"
        cat "$TEMP_DIR/my_output.txt"
        echo -e "\nReference parser output:"
        cat "$TEMP_DIR/ref_output.txt"
        
        read -p "Are these differences just in line numbers? (y/n): " just_lines
        if [ "$just_lines" = "y" ]; then
            echo -e "${GREEN}Test PASSED (line number differences only)${NC}"
        else
            echo -e "${RED}Test FAILED (differences beyond line numbers)${NC}"
        fi
    else
        echo -e "${GREEN}Test PASSED (outputs match exactly)${NC}"
    fi
}

# ===== SPECIALIZED TEST CASES =====

# 1. Let ambiguity - right association
echo "SPECIALIZED TEST 1: Let right association"
run_test "let_right_assoc" "
class LetTest {
    test() : Int {
        let x : Int <- 1 in let y : Int <- 2 in let z : Int <- 3 in x + y + z
    };
};
"

# 2. Let with complex expressions on the right
echo "SPECIALIZED TEST 2: Let with complex right side"
run_test "let_complex_right" "
class LetTest {
    test() : Int {
        let x : Int <- 5 in 
            x + (let y : Int <- 10 in y * 2) + 
            (let z : Int <- 15 in z / 3)
    };
};
"

# 3. Let with expressions in initializers
echo "SPECIALIZED TEST 3: Let with expressions in initializers"
run_test "let_expr_init" "
class LetTest {
    test() : Int {
        let x : Int <- 5 + 3 * 2,
            y : Int <- if x < 10 then x else x * 2 fi,
            z : Int <- while y > 0 loop y <- y - 1 pool
        in x + y + z
    };
};
"

# 4. Nested let expressions with missing types
echo "SPECIALIZED TEST 4: Let with missing types (error recovery)"
run_test "let_missing_types" "
class LetTest {
    test() : Int {
        let x : <- 5,
            y : Int <- 10
        in x + y
    };
};
"

# 5. Let dangling else ambiguity interaction
echo "SPECIALIZED TEST 5: Let-if interaction for dangling else"
run_test "let_if_dangling" "
class LetTest {
    test() : Int {
        let x : Int <- 5 in
            if x < 10 then 
                let y : Int <- 20 in
                    if y > x then y else x fi
            else
                0
            fi
    };
};
"

# 6. Multiple lets in complex expressions
echo "SPECIALIZED TEST 6: Multiple lets in expressions"
run_test "multiple_lets" "
class LetTest {
    test() : Int {
        5 + let x : Int <- 10 in x * 2 - let y : Int <- 7 in y / 2
    };
};
"

# Precedence Testing

# 7. Operator precedence comprehensive test
echo "SPECIALIZED TEST 7: Comprehensive operator precedence"
run_test "operator_precedence" "
class PrecedenceTest {
    test() : Bool {
        ~5 * 3 + 4 / 2 - 1 < 10 && not 4 = 3 || true
    };
};
"

# 8. Complex case statement
echo "SPECIALIZED TEST 8: Complex case statement"
run_test "complex_case" "
class CaseTest {
    test(x : Object) : Object {
        case x of
            i : Int => 
                case i of
                    0 => \"zero\";
                    1 => \"one\";
                    n : Int => n + 100;
                esac;
            s : String => 
                if s.length() = 0 then
                    \"empty\"
                else
                    s
                fi;
            o : Object => o;
        esac
    };
};
"

# 9. Extremely nested expressions
echo "SPECIALIZED TEST 9: Extremely nested expressions"
run_test "extreme_nesting" "
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
"

# 10. Error recovery in complex structures
echo "SPECIALIZED TEST 10: Error recovery in complex structures"
run_test "complex_error_recovery" "
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
"

# 11. Let with ISVOID and other operators
echo "SPECIALIZED TEST 11: Let with ISVOID and operators"
run_test "let_with_isvoid" "
class IsvoidTest {
    test() : Bool {
        let x : Int <- 5 in isvoid x || 
        let y : Object <- null in isvoid y &&
        let z : Int <- 10 in not isvoid z
    };
};
"

# 12. Class attribute initialization with self and complex expressions
echo "SPECIALIZED TEST 12: Class attribute complex initialization"
run_test "complex_attr_init" "
class AttributeTest {
    counter : Int <- 0;
    name : String <- \"test\";
    
    self_ref : AttributeTest <- self;
    complex_attr : Int <- {
        let temp : Int <- 5 in
            if temp < 10 then
                temp * 2
            else
                temp + 10
            fi;
    };
};
"

# 13. Let with formal parameter name shadowing
echo "SPECIALIZED TEST 13: Let with parameter shadowing"
run_test "let_param_shadow" "
class ShadowTest {
    test(x : Int) : Int {
        let x : Int <- x + 1 in
            let y : Int <- x + 2 in
                x + y
    };
};
"

# 14. Lots of method dispatches and chaining
echo "SPECIALIZED TEST 14: Method dispatch chaining"
run_test "method_chains" "
class Chain {
    value : Int;
    
    init(v : Int) : Chain {
        {
            value <- v;
            self;
        }
    };
    
    add(x : Int) : Chain {
        (new Chain).init(value + x)
    };
    
    multiply(x : Int) : Chain {
        (new Chain).init(value * x)
    };
    
    getValue() : Int { value };
    
    test() : Int {
        (new Chain).init(5).add(3).multiply(2).add(1).getValue()
    };
};
"

# 15. Let SHIFT/REDUCE conflict test case
echo "SPECIALIZED TEST 15: Let with potential SHIFT/REDUCE conflict"
run_test "let_shift_reduce" "
class ShiftReduceTest {
    test() : Int {
        let x : Int <- 5,
            y : Int <- let z : Int <- 10 in z
        in x + y
    };
};
"

echo -e "\n${YELLOW}All specialized tests completed!${NC}"
echo -e "Check the results above to verify your parser's behavior on edge cases."
echo -e "Test files stored in the '${TEMP_DIR}' directory."
