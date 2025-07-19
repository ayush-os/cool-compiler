#!/bin/bash

# Performance and Resource Stress Testing for Cool Parser
# This script creates extremely large Cool programs to test parser performance and resource handling

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory for test files
PERF_DIR="performance_tests"
mkdir -p $PERF_DIR

# Function to measure parsing time
measure_parsing_time() {
    local test_name=$1
    local test_file="$PERF_DIR/$test_name.cl"
    local size=$(du -h "$test_file" | cut -f1)
    
    echo -e "\n${CYAN}=== PERFORMANCE TEST: $test_name (Size: $size) ====${NC}"
    
    # Run your parser with time measurement
    echo -e "${YELLOW}Running your parser...${NC}"
    TIMEFORMAT='%3R seconds'
    MY_TIME=$( { time ./myparser "$test_file" > "$PERF_DIR/my_output.txt" 2>&1; } 2>&1 )
    MY_EXIT=$?
    MY_SIZE=$(du -h "$PERF_DIR/my_output.txt" | cut -f1)
    
    # Run reference parser with time measurement
    echo -e "${YELLOW}Running reference parser...${NC}"
    TIMEFORMAT='%3R seconds'
    REF_TIME=$( { time ./lexer "$test_file" | /afs/ir/class/cs143/bin/parser > "$PERF_DIR/ref_output.txt" 2>&1; } 2>&1 )
    REF_EXIT=$?
    REF_SIZE=$(du -h "$PERF_DIR/ref_output.txt" | cut -f1)
    
    # Report results
    echo -e "${BLUE}Results:${NC}"
    echo -e "Your parser: $MY_TIME, exit code: $MY_EXIT, output size: $MY_SIZE"
    echo -e "Reference parser: $REF_TIME, exit code: $REF_EXIT, output size: $REF_SIZE"
    
    # Compare outputs (just success/failure, not detailed diff due to potential size)
    if [ $MY_EXIT -ne $REF_EXIT ]; then
        echo -e "${RED}FAIL: Exit codes don't match!${NC}"
    else
        # Check if either parser produced error messages
        if grep -q "ERROR" "$PERF_DIR/my_output.txt" || grep -q "ERROR" "$PERF_DIR/ref_output.txt"; then
            echo -e "${YELLOW}Both parsers found errors (expected for stress tests)${NC}"
            
            # Optionally show first few errors from each
            echo -e "\nFirst few errors from your parser:"
            grep "ERROR" "$PERF_DIR/my_output.txt" | head -5
            
            echo -e "\nFirst few errors from reference parser:"
            grep "ERROR" "$PERF_DIR/ref_output.txt" | head -5
            
            read -p "Do these errors look similar? (y/n): " similar_errors
            if [ "$similar_errors" = "y" ]; then
                echo -e "${GREEN}PASS: Both parsers produced similar errors${NC}"
            else
                echo -e "${YELLOW}Parsers produced different errors${NC}"
            fi
        else
            echo -e "${GREEN}PASS: Both parsers completed without errors${NC}"
        fi
    fi
}

# ===== PERFORMANCE TEST CASES =====

# 1. Massive number of classes
echo "Performance Test 1: Generating massive number of classes file..."
cat > "$PERF_DIR/massive_classes.cl" << 'EOL'
EOL

# Generate 1000 simple classes
for i in {1..1000}; do
    cat >> "$PERF_DIR/massive_classes.cl" << EOL
class Class$i {
    attr1 : Int <- $i;
    attr2 : String <- "Class$i";
    
    method1() : Int { attr1 };
    method2() : String { attr2 };
};

EOL
done

# Add a Main class
cat >> "$PERF_DIR/massive_classes.cl" << 'EOL'
class Main {
    main() : Object { new Object };
};
EOL

measure_parsing_time "massive_classes"

# 2. Massive class with many features
echo "Performance Test 2: Generating class with massive number of features..."
cat > "$PERF_DIR/massive_features.cl" << 'EOL'
class MassiveFeatures {
EOL

# Generate 1000 attributes and methods
for i in {1..1000}; do
    cat >> "$PERF_DIR/massive_features.cl" << EOL
    attr$i : Int <- $i;
EOL
done

for i in {1..1000}; do
    cat >> "$PERF_DIR/massive_features.cl" << EOL
    method$i() : Int { attr$i };
EOL
done

cat >> "$PERF_DIR/massive_features.cl" << 'EOL'
};

class Main {
    main() : Object { new MassiveFeatures };
};
EOL

measure_parsing_time "massive_features"

# 3. Method with massive parameter list
echo "Performance Test 3: Generating method with massive parameter list..."
cat > "$PERF_DIR/massive_parameters.cl" << 'EOL'
class MassiveParameters {
    massiveMethod(
EOL

# Generate 1000 parameters
for i in {1..999}; do
    cat >> "$PERF_DIR/massive_parameters.cl" << EOL
        p$i : Int,
EOL
done

cat >> "$PERF_DIR/massive_parameters.cl" << 'EOL'
        p1000 : Int
    ) : Int { 
        p1 + p2 + p3 + p4 + p5
    };
};

class Main {
    main() : Object { new MassiveParameters };
};
EOL

measure_parsing_time "massive_parameters"

# 4. Massive expression with deep nesting
echo "Performance Test 4: Generating massive nested expression..."
cat > "$PERF_DIR/massive_expression.cl" << 'EOL'
class MassiveExpression {
    test() : Int {
EOL

# Generate deeply nested expression with 100 levels
expr="1"
for i in {1..100}; do
    expr="($expr + $i)"
done

cat >> "$PERF_DIR/massive_expression.cl" << EOL
        $expr
EOL

cat >> "$PERF_DIR/massive_expression.cl" << 'EOL'
    };
};

class Main {
    main() : Object { (new MassiveExpression).test() };
};
EOL

measure_parsing_time "massive_expression"

# 5. Massive let expression with many variables
echo "Performance Test 5: Generating massive let expression..."
cat > "$PERF_DIR/massive_let.cl" << 'EOL'
class MassiveLet {
    test() : Int {
        let 
EOL

# Generate 100 variables in let expression
for i in {1..99}; do
    cat >> "$PERF_DIR/massive_let.cl" << EOL
            v$i : Int <- $i,
EOL
done

cat >> "$PERF_DIR/massive_let.cl" << 'EOL'
            v100 : Int <- 100
        in
            v1 + v2 + v3 + v4 + v5
    };
};

class Main {
    main() : Object { (new MassiveLet).test() };
};
EOL

measure_parsing_time "massive_let"

# 6. Massive case expression
echo "Performance Test 6: Generating massive case expression..."
cat > "$PERF_DIR/massive_case.cl" << 'EOL'
class MassiveCase {
    test(obj : Object) : Object {
        case obj of
EOL

# Generate 100 case branches
for i in {1..99}; do
    cat >> "$PERF_DIR/massive_case.cl" << EOL
            v$i : Int => $i;
EOL
done

cat >> "$PERF_DIR/massive_case.cl" << 'EOL'
            v100 : Object => 100;
        esac
    };
};

class Main {
    main() : Object { (new MassiveCase).test(new Object) };
};
EOL

measure_parsing_time "massive_case"

# 7. Massive if-then-else nesting
echo "Performance Test 7: Generating massive if-then-else nesting..."
cat > "$PERF_DIR/massive_if.cl" << 'EOL'
class MassiveIf {
    test(x : Int) : Int {
EOL

# Generate deeply nested if-then-else with 100 levels
current="x"
for i in {1..100}; do
    cat >> "$PERF_DIR/massive_if.cl" << EOL
        if $current < $i then
EOL
    current="$i"
done

# Close all if statements
for i in {1..100}; do
    if [ $i -eq 100 ]; then
        cat >> "$PERF_DIR/massive_if.cl" << EOL
            100
EOL
    else
        cat >> "$PERF_DIR/massive_if.cl" << EOL
            $i
EOL
    fi
    cat >> "$PERF_DIR/massive_if.cl" << EOL
        else
EOL
done

cat >> "$PERF_DIR/massive_if.cl" << EOL
            0
EOL

for i in {1..100}; do
    cat >> "$PERF_DIR/massive_if.cl" << EOL
        fi
EOL
done

cat >> "$PERF_DIR/massive_if.cl" << 'EOL'
    };
};

class Main {
    main() : Object { (new MassiveIf).test(50) };
};
EOL

measure_parsing_time "massive_if"

# 8. Massive block with many expressions
echo "Performance Test 8: Generating massive block with many expressions..."
cat > "$PERF_DIR/massive_block.cl" << 'EOL'
class MassiveBlock {
    test() : Int {
        {
EOL

# Generate 1000 expressions in a block
for i in {1..999}; do
    cat >> "$PERF_DIR/massive_block.cl" << EOL
            $i;
EOL
done

cat >> "$PERF_DIR/massive_block.cl" << 'EOL'
            1000;
        }
    };
};

class Main {
    main() : Object { (new MassiveBlock).test() };
};
EOL

measure_parsing_time "massive_block"

# 9. Massive string literals
echo "Performance Test 9: Generating massive string literals..."
cat > "$PERF_DIR/massive_strings.cl" << 'EOL'
class MassiveStrings {
EOL

# Generate 10 methods with very long string literals
for i in {1..10}; do
    # Create a string of approximately 1000 characters
    cat >> "$PERF_DIR/massive_strings.cl" << EOL
    string$i() : String { "$(printf '%01000d' 0 | tr '0' 'X')" };
EOL
done

cat >> "$PERF_DIR/massive_strings.cl" << 'EOL'
};

class Main {
    main() : Object { new MassiveStrings };
};
EOL

measure_parsing_time "massive_strings"

# 10. Combined stress test
echo "Performance Test 10: Generating combined stress test..."
cat > "$PERF_DIR/combined_stress.cl" << 'EOL'
EOL

# Generate 100 classes
for i in {1..100}; do
    cat >> "$PERF_DIR/combined_stress.cl" << EOL
class Class$i {
    attr1 : Int <- $i;
    attr2 : String <- "Class$i";
    
    method1() : Int { 
        let x : Int <- $i,
            y : Int <- $i * 2
        in x + y
    };
    
    method2(p1 : Int, p2 : Int, p3 : Int) : Int {
        if p1 < p2 then
            p1 + p2
        else
            p2 + p3
        fi
    };
    
    method3(obj : Object) : Object {
        case obj of
            i : Int => i + $i;
            s : String => s.length();
            o : Object => 0;
        esac
    };
    
    method4() : Int {
        {
            let x : Int <- 1 in x + 1;
            let y : Int <- 2 in y + 2;
            let z : Int <- 3 in z + 3;
            $i;
        }
    };
};

EOL
done

cat >> "$PERF_DIR/combined_stress.cl" << 'EOL'
class Main {
    main() : Object { 
        {
EOL

# Generate calls to each class
for i in {1..100}; do
    cat >> "$PERF_DIR/combined_stress.cl" << EOL
            (new Class$i).method1();
            (new Class$i).method2(1, 2, 3);
            (new Class$i).method3(new Object);
            (new Class$i).method4();
EOL
done

cat >> "$PERF_DIR/combined_stress.cl" << 'EOL'
            new Object;
        }
    };
};
EOL

measure_parsing_time "combined_stress"

echo -e "\n${YELLOW}=== Performance Testing Complete ===${NC}"
echo -e "All performance tests have been run."
echo -e "This gives you an idea of how your parser performs on extremely large inputs."

# Cleanup option
read -p "Do you want to keep the performance test files? (y/n): " keep
if [ "$keep" != "y" ]; then
    rm -rf $PERF_DIR
    echo "Performance test files cleaned up."
else
    echo "Performance test files kept in $PERF_DIR directory."
fi
