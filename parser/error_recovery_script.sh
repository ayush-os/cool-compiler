#!/bin/bash

# Comprehensive Error Recovery Test Suite for Cool Parser
# This script specifically targets error recovery in all different contexts

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory for test files
ERR_DIR="error_recovery_tests"
mkdir -p $ERR_DIR

# Counter for test results
TOTAL=0
PASSED=0

# Function to run error recovery test
test_error_recovery() {
    local test_name=$1
    local test_content=$2
    local test_description=$3
    local test_file="$ERR_DIR/$test_name.cl"
    
    echo -e "\n${CYAN}=== ERROR RECOVERY TEST: $test_name ===${NC}"
    echo -e "${BLUE}Description: $test_description${NC}"
    echo "$test_content" > "$test_file"
    TOTAL=$((TOTAL + 1))
    
    # Run your parser
    echo -e "${YELLOW}Running your parser...${NC}"
    ./myparser "$test_file" > "$ERR_DIR/my_output.txt" 2>&1
    MY_EXIT=$?
    
    # Run reference parser
    echo -e "${YELLOW}Running reference parser...${NC}"
    ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$ERR_DIR/ref_output.txt" 2>&1
    REF_EXIT=$?
    
    # Check if both parsers detected errors (they should)
    if ! grep -q "ERROR" "$ERR_DIR/my_output.txt"; then
        echo -e "${RED}FAIL: Your parser did not detect any errors!${NC}"
        return
    fi
    
    if ! grep -q "ERROR" "$ERR_DIR/ref_output.txt"; then
        echo -e "${RED}FAIL: Reference parser did not detect any errors (unexpected)!${NC}"
        return
    fi
    
    # Compare exit codes
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes differ! Your parser: $MY_EXIT, Reference: $REF_EXIT${NC}"
        return
    fi
    
    # Check if the error recovery worked properly by seeing if the parser continued
    # and parsed the rest of the file
    
    # First, count the number of class definitions in the test file
    CLASS_COUNT=$(grep -c "class " "$test_file")
    
    # Then, check if your parser identified all classes
    MY_CLASS_COUNT=$(grep -c "class " "$ERR_DIR/my_output.txt")
    
    # For reference parser, some versions output differently, but should at least have some output
    # after the error
    if [ -s "$ERR_DIR/ref_output.txt" ]; then
        REF_CONTINUED=1
    else
        REF_CONTINUED=0
    fi
    
    # Verification logic - if we have multiple classes and your parser found at least one,
    # it likely recovered and continued parsing
    if [ $CLASS_COUNT -gt 1 ] && [ $MY_CLASS_COUNT -gt 0 ]; then
        echo -e "${GREEN}PASS: Your parser detected errors and continued parsing${NC}"
        PASSED=$((PASSED + 1))
    else
        # Interactive verification
        echo -e "${YELLOW}Manual verification needed:${NC}"
        echo -e "Your parser output:"
        cat "$ERR_DIR/my_output.txt"
        echo -e "\nReference parser output:"
        cat "$ERR_DIR/ref_output.txt"
        
        read -p "Did your parser recover properly from the error? (y/n): " recovery_ok
        if [ "$recovery_ok" = "y" ]; then
            echo -e "${GREEN}PASS: Manually verified error recovery${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAIL: Error recovery did not work as expected${NC}"
        fi
    fi
}

# ===== ERROR RECOVERY TEST CASES =====

# 1. Missing semicolon in class attribute
echo "Error Recovery Test 1: Missing semicolon in class attribute"
test_error_recovery "err_missing_semicolon" "
class A {
    a : Int <- 5  -- Missing semicolon here
    b : Int <- 10;
    
    method1() : Int { a + b };
};

class B {
    c : Int <- 15;
    
    method2() : Int { c * 2 };
};
" "Tests recovery from missing semicolon in attribute definition"

# 2. Error in one class but not the next
echo "Error Recovery Test 2: Error in one class but not the next"
test_error_recovery "err_class_recovery" "
class ErrorClass {
    x : Undefined;  -- Error: undefined type
    
    badMethod() : Undefined { 5 };  -- Error: undefined return type
};

-- This class should still be parsed correctly
class GoodClass {
    y : Int <- 10;
    
    goodMethod() : Int { y };
};
" "Tests recovery after a class with type errors so the next class is parsed"

# 3. Error in feature but recovery to next feature
echo "Error Recovery Test 3: Error in feature but recovery to next feature"
test_error_recovery "err_feature_recovery" "
class FeatureTest {
    -- Good attribute
    a : Int <- 5;
    
    -- Bad attribute - missing type
    b : <- 10;
    
    -- Good method after bad attribute
    method1() : Int { a };
    
    -- Bad method - missing parameter type
    method2(x : Int, y : ) : Int { x + y };
    
    -- Good method after bad method
    method3() : Int { a * 2 };
};
" "Tests recovery from errors in features to continue parsing subsequent features"

# 4. Error in expression but recovery to next expression
echo "Error Recovery Test 4: Error in expression but recovery to next expression"
test_error_recovery "err_expr_recovery" "
class ExprTest {
    test() : Int {
        {
            5 + ;  -- Error: missing right operand
            
            -- This should still be parsed
            10 * 2;
            
            if then 5 else 10 fi;  -- Error: missing condition
            
            -- This should still be parsed
            20 + 30;
        }
    };
};
" "Tests recovery from errors in expressions to continue parsing subsequent expressions"

# 5. Error in let binding
echo "Error Recovery Test 5: Error in let binding"
test_error_recovery "err_let_recovery" "
class LetTest {
    test() : Int {
        let 
            x : Int <- 5,
            y : <- 10,  -- Error: missing type
            z : Int  -- Error: missing assignment
        in x + y + z
    };
    
    -- This method should still be parsed
    test2() : Int { 42 };
};
" "Tests recovery from errors in let bindings"

# 6. Error in if expression
echo "Error Recovery Test 6: Error in if expression"
test_error_recovery "err_if_recovery" "
class IfTest {
    test() : Int {
        if 5 < then  -- Error: incomplete condition
            10
        else
            20
        fi
    };
    
    -- This method should still be parsed
    test2() : Int { 30 };
};
" "Tests recovery from errors in if expressions"

# 7. Error in while expression
echo "Error Recovery Test 7: Error in while expression"
test_error_recovery "err_while_recovery" "
class WhileTest {
    test() : Int {
        while loop  -- Error: missing condition
            5
        pool
    };
    
    -- This method should still be parsed
    test2() : Int { 40 };
};
" "Tests recovery from errors in while expressions"

# 8. Error in case expression
echo "Error Recovery Test 8: Error in case expression"
test_error_recovery "err_case_recovery" "
class CaseTest {
    test(x : Object) : Object {
        case x of
            i : Int => i;
            s : => s;  -- Error: missing type
            o : Object => 0;
        esac
    };
    
    -- This method should still be parsed
    test2() : Int { 50 };
};
" "Tests recovery from errors in case expressions"

# 9. Missing class closing brace
echo "Error Recovery Test 9: Missing class closing brace"
test_error_recovery "err_missing_brace" "
class A {
    a : Int <- 5;
    
    method1() : Int { a };
-- Missing closing brace here

class B {
    b : Int <- 10;
    
    method2() : Int { b };
};
" "Tests recovery from missing class closing brace"

# 10. Invalid inheritance
echo "Error Recovery Test 10: Invalid inheritance"
test_error_recovery "err_invalid_inherit" "
class A inherits NonExistent {  -- Error: inheriting from undefined class
    a : Int <- 5;
    
    method1() : Int { a };
};

class B {
    b : Int <- 10;
    
    method2() : Int { b };
};
" "Tests recovery from invalid inheritance"

# 11. Multiple errors in a class
echo "Error Recovery Test 11: Multiple errors in a class"
test_error_recovery "err_multiple_class" "
class MultiError {
    a : Int <- 5
    b : <- 10;  -- Error: missing type
    c : Undefined;  -- Error: undefined type
    
    method1(x : ) : Int { x };  -- Error: missing parameter type
    method2() : Undefined { 5 };  -- Error: undefined return type
    method3() : Int { 5 + };  -- Error: incomplete expression
};

class GoodClass {
    x : Int <- 20;
    
    method() : Int { x };
};
" "Tests recovery from multiple errors within a class"

# 12. Multiple errors in method body
echo "Error Recovery Test 12: Multiple errors in method body"
test_error_recovery "err_multiple_body" "
class MethodBodyErrors {
    test() : Int {
        {
            5 + ;  -- Error: incomplete expression
            if then 10 else 20 fi;  -- Error: missing condition
            let x : <- 5 in x;  -- Error: missing type
            while loop 10 pool;  -- Error: missing condition
            case 5 of i : => i; o : Object => 0; esac;  -- Error: missing type
            42;  -- This should be parsed correctly
        }
    };
    
    -- This method should still be parsed
    test2() : Int { 100 };
};
" "Tests recovery from multiple errors within a method body"

# 13. Nested blocks with errors
echo "Error Recovery Test 13: Nested blocks with errors"
test_error_recovery "err_nested_blocks" "
class NestedErrors {
    test() : Int {
        {
            {
                5 + ;  -- Error: incomplete expression
                10;  -- This should be parsed
            };
            
            {
                if then 20 else 30 fi;  -- Error: missing condition
                40;  -- This should be parsed
            };
            
            50;  -- This should be parsed
        }
    };
};
" "Tests recovery from errors in nested blocks"

# 14. Errors in complex expressions
echo "Error Recovery Test 14: Errors in complex expressions"
test_error_recovery "err_complex_expr" "
class ComplexErrors {
    test() : Int {
        if 5 < 10 then
            let x : Int <- , y : Int <- 20 in  -- Error: missing initializer
                x + y
        else
            case of  -- Error: missing case expression
                i : Int => i;
                o : Object => 0;
            esac
        fi
    };
    
    -- This method should still be parsed
    test2() : Int { 60 };
};
" "Tests recovery from errors in complex nested expressions"

# 15. Errors in formal parameters
echo "Error Recovery Test 15: Errors in formal parameters"
test_error_recovery "err_formal_params" "
class FormalErrors {
    method1(x : Int, y : , z : Int) : Int {  -- Error: missing parameter type
        x + z
    };
    
    method2(a : Undefined, b : Int) : Int {  -- Error: undefined parameter type
        b
    };
    
    -- This method should still be parsed
    method3(c : Int) : Int { c };
};
" "Tests recovery from errors in formal parameter definitions"

# 16. Multiple bad classes and recovery
echo "Error Recovery Test 16: Multiple bad classes and recovery"
test_error_recovery "err_multiple_classes" "
class A inherits {  -- Error: missing parent class name
    a : Int;
};

class {  -- Error: missing class name
    b : Int;
};

class C inherits NonExistent {  -- Error: undefined parent class
    c : Int;
};

-- This class should still be parsed
class D {
    d : Int;
};
" "Tests recovery from multiple classes with errors"

# 17. Error in dispatch expression
echo "Error Recovery Test 17: Error in dispatch expression"
test_error_recovery "err_dispatch" "
class DispatchErrors {
    method1() : Int { 5 };
    method2(x : Int) : Int { x };
    
    test() : Int {
        {
            self.;  -- Error: missing method name
            self.method1(;  -- Error: incomplete parameter list
            self.undefined();  -- Error: undefined method
            self.method2();  -- Error: wrong number of arguments
            self.method1();  -- This should be parsed correctly
        }
    };
};
" "Tests recovery from errors in dispatch expressions"

# 18. Errors in arithmetic expressions
echo "Error Recovery Test 18: Errors in arithmetic expressions"
test_error_recovery "err_arithmetic" "
class ArithmeticErrors {
    test() : Int {
        {
            5 + * 3;  -- Error: invalid expression
            10 - ;  -- Error: missing operand
            * 15;  -- Error: missing operand
            20 / 0;  -- This is valid syntax (though would cause runtime error)
            25 * 2;  -- This should be parsed correctly
        }
    };
};
" "Tests recovery from errors in arithmetic expressions"

# 19. Errors in comparison expressions
echo "Error Recovery Test 19: Errors in comparison expressions"
test_error_recovery "err_comparison" "
class ComparisonErrors {
    test() : Bool {
        {
            5 < ;  -- Error: missing right operand
            10 <= *;  -- Error: invalid right operand
            15 = ;  -- Error: missing right operand
            20 < 30;  -- This should be parsed correctly
        }
    };
};
" "Tests recovery from errors in comparison expressions"

# 20. Errors in new expressions
echo "Error Recovery Test 20: Errors in new expressions"
test_error_recovery "err_new" "
class NewErrors {
    test() : Object {
        {
            new;  -- Error: missing type name
            new Undefined;  -- Error: undefined type
            new SELF_TYPE;  -- This should be parsed correctly
        }
    };
};
" "Tests recovery from errors in new expressions"

# 21. Recovery across multiple files
echo "Error Recovery Test 21: Recovery across multiple files"
# Create first file with error
cat > "$ERR_DIR/file1.cl" << 'EOL'
class A {
    a : Int <- 5
    method1() : Int { a };
};
EOL

# Create second file without error
cat > "$ERR_DIR/file2.cl" << 'EOL'
class B {
    b : Int <- 10;
    method2() : Int { b };
};
EOL

# Create combined test script
cat > "$ERR_DIR/test_multiple_files.sh" << 'EOL'
#!/bin/bash
# Test recovery across multiple files
echo "Testing file1.cl (contains error):"
./myparser file1.cl
echo -e "\nTesting file2.cl (correct file):"
./myparser file2.cl
EOL
chmod +x "$ERR_DIR/test_multiple_files.sh"

echo -e "${CYAN}=== ERROR RECOVERY TEST: Multiple Files ===${NC}"
echo -e "${BLUE}Description: Tests that an error in one file doesn't affect parsing of subsequent files${NC}"
echo -e "${YELLOW}To run this test manually, execute:${NC}"
echo -e "cd $ERR_DIR && ./test_multiple_files.sh"

# 22. Multiple instances of the same error
echo "Error Recovery Test 22: Multiple instances of the same error"
test_error_recovery "err_repeated_errors" "
class RepeatedErrors {
    a : Int <- 5
    b : Int <- 10
    c : Int <- 15
    d : Int <- 20
    
    -- All missing semicolons above
    
    method1() : Int { a + b };
    method2() : Int { c + d };
};
" "Tests recovery from multiple instances of the same error type"

# 23. Syntax error in class and method names
echo "Error Recovery Test 23: Syntax error in identifiers"
test_error_recovery "err_identifiers" "
class 123Invalid {  -- Error: invalid class name
    a : Int;
    
    123method() : Int { a };  -- Error: invalid method name
};

class Valid {
    b : Int;
    
    validMethod() : Int { b };
};
" "Tests recovery from invalid identifiers"

# 24. Errors in every feature of a class
echo "Error Recovery Test 24: Errors in every feature"
test_error_recovery "err_all_features" "
class AllFeatureErrors {
    a : <- 5;  -- Error: missing type
    b : Undefined;  -- Error: undefined type
    c : Int <- ;  -- Error: missing initializer
    
    method1( : Int) : Int { 5 };  -- Error: missing parameter name
    method2(x : ) : Int { x };  -- Error: missing parameter type
    method3() : Undefined { 10 };  -- Error: undefined return type
    method4() : Int { 5 + };  -- Error: invalid expression
};

class StillValid {
    x : Int <- 42;
    validMethod() : Int { x };
};
" "Tests recovery when every feature in a class has errors"

# 25. Class with completely invalid syntax
echo "Error Recovery Test 25: Class with completely invalid syntax"
test_error_recovery "err_invalid_syntax" "
class @#$% {
    *** : !!! <- ???;
    
    @@@@() : ### { ^^^ };
};

class ValidAfterMess {
    x : Int <- 100;
    validMethod() : Int { x };
};
" "Tests recovery from completely invalid syntax"

# 26. Specific test for the case mentioned in the assignment
echo "Error Recovery Test 26: Specific case from assignment"
test_error_recovery "err_assignment_case" "
class ErrorInClass {
    a : Int;
    b : String;
    
    -- Error in class definition
    c : Int <- 5
    
    method1() : Int { 1 };
};

-- Next class should be parsed correctly
class NextClass {
    x : Int;
    y : String;
    
    method2() : Int { 2 };
};
" "Tests the specific case mentioned in the assignment: error in class definition but next class is syntactically correct"

# 27. Error in an if expression with recovery for next statement in a block
echo "Error Recovery Test 27: Error in if with recovery in block"
test_error_recovery "err_if_block_recovery" "
class IfBlockRecovery {
    test() : Int {
        {
            -- Error in if statement
            if 5 < then 10 else 20 fi;
            
            -- Next statement should be parsed
            30 + 40;
            
            -- Final result
            50;
        }
    };
};
" "Tests recovery from error in if expression to parse next statement in a block"

# 28. Error in let binding with recovery for another let binding
echo "Error Recovery Test 28: Error in let binding with recovery"
test_error_recovery "err_let_binding_recovery" "
class LetBindingRecovery {
    test() : Int {
        let 
            x : <- 5,  -- Error: missing type
            y : Int <- let z : <- 10 in z,  -- Error: nested let with missing type
            a : Int <- 15  -- This should be parsed correctly
        in x + y + a
    };
};
" "Tests recovery from errors in let bindings to parse other bindings"

# 29. Test for the 'let' binding specifically mentioned in assignment
echo "Error Recovery Test 29: Let binding recovery"
test_error_recovery "err_let_binding_spec" "
class LetBinding {
    test() : Int {
        {
            -- Let with error in binding
            let x : Int <- in x + 1;
            
            -- Next let should be parsed correctly
            let y : Int <- 42 in y;
        }
    };
};
" "Tests the specific case of error recovery in a let binding mentioned in the assignment"

# 30. Test for error recovery in expressions inside {...} block
echo "Error Recovery Test 30: Error in expression inside block"
test_error_recovery "err_expression_block" "
class ExpressionBlockRecovery {
    test() : Int {
        {
            -- Error in expression
            x + ;
            
            -- This should still be parsed
            let x : Int <- 5 in x + 1;
            
            -- This should still be parsed
            42;
        }
    };
};
" "Tests recovery from errors in expressions inside a {...} block, as mentioned in the assignment"

# Summary
echo -e "\n${YELLOW}=== Error Recovery Test Summary ===${NC}"
echo -e "Total tests: $TOTAL"
echo -e "Passed tests: $PASSED"
echo -e "Failed tests: $((TOTAL - PASSED))"

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}All error recovery tests passed!${NC}"
else
    echo -e "${RED}Some error recovery tests failed.${NC}"
fi

# Cleanup option
read -p "Do you want to keep the error recovery test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $ERR_DIR
    echo "Error recovery test files cleaned up."
else
    echo "Error recovery test files kept in $ERR_DIR directory."
fi
