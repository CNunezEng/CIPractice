/**
 * @file TestParentheses.cpp
 * @brief Unit tests for the Parentheses Validation solution.
 * 
 * This test suite reads test cases from an INI file (testCases.ini) to enable
 * dynamic test case configuration without recompilation.
 */

#include "Parentheses.h"
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <map>

/**
 * @struct TestCase
 * @brief Represents a single test case with operations and expected result.
 */
struct TestCase {
    std::string name;
    std::string input;
    bool output;
};

/**
 * @brief Reads test cases from an INI file.
 * 
 * Expected INI format:
 * [TestCaseN]
 * Name=Description
 * Input=op1,op2,op3,...
 * Output=123
 * 
 * @param filename Path to the INI file
 * @return Vector of parsed TestCase objects
 */
std::vector<TestCase> readTestCasesFromINI(const std::string& filename) {
    std::vector<TestCase> testCases;
    std::ifstream file(filename);
    
    if (!file.is_open()) {
        std::cout << "Could not open test cases file: " << filename << std::endl;
        return testCases;
    }
    
    std::string line;
    TestCase currentTestCase;
    bool inTestCase = false;
    
    while (std::getline(file, line)) {
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        
        // Skip empty lines and comments
        if (line.empty() || line[0] == ';') continue;
        
        // Check for section headers [TestCaseN]
        if (line[0] == '[' && line[line.length() - 1] == ']') {              
            currentTestCase = TestCase();
            inTestCase = true;
        } else if (inTestCase) {
            // Parse key=value pairs
            size_t eqPos = line.find('=');
            if (eqPos != std::string::npos) {
                std::string key = line.substr(0, eqPos);
                std::string value = line.substr(eqPos + 1);
                
                // Trim key and value
                key.erase(key.find_last_not_of(" \t") + 1);
                value.erase(0, value.find_first_not_of(" \t"));
                
                if (key == "Name") {
                    currentTestCase.name = value;
                } else if (key == "Input") {
                    currentTestCase.input = value;
                    
                } else if (key == "Output") {
                    std::istringstream iss(value);
                    iss >> std::boolalpha >> currentTestCase.output;
                    testCases.push_back(currentTestCase);
                    std::cout << "Added test case: " << currentTestCase.name << " with input: " << currentTestCase.input << " and output: " << std::boolalpha << currentTestCase.output << std::endl;
                }
            }
        }
    }

    std::cout << "Total test cases loaded: " << testCases.size() << std::endl;
    
    file.close();
    return testCases;
}

// ═══════════════════════════════════════════════════════════════════════════
// Dynamic Test Cases loaded from testCases.ini
// ═══════════════════════════════════════════════════════════════════════════

int main() {
    // Load test cases from the INI file
    std::vector<TestCase> testCases = readTestCasesFromINI("test/TestCases.ini");

    if(!(testCases.size() > 0)){
        std::cout << "No test cases found in the INI file." << testCases.size() << std::endl;
        return 1;
    } // At least one test case should be loaded

    bool isPassed = false;
    bool allPassed = true;
    int noTests = 0;
    int noFails = 0;

    // Create test instance
    Parentheses s;
    
    // Execute each test case
    for (const auto& testCase : testCases) 
    {
        int result = s.isValid(testCase.input);
        isPassed = (result == testCase.output);
        noTests++;

        if(!isPassed){
            allPassed = false;
            std::cout << testCase.name << " FAILED with input: " << testCase.input 
            << " expected output: " << testCase.output <<
            " and actual output: " << result << std::endl;
            noFails++;
        }
        else{
            std::cout << testCase.name << " Passed " << std::endl;
        }
    }

    if (allPassed){
        std::cout << "All tests PASSED" << std::endl;
    }
    else{
        std::cout << noFails << " of " << noTests << "FAILED" << std::endl;
        std::cout << "see above for failures" << std::endl;
    }
}
