/**
 * @file Parentheses.h
 * @brief Header file for the Paretheses Validation problem.
 * 
 * This module provides a solution for validating parentheses.
 */

#ifndef PARENTHESES_H
#define PARENTHESES_H

#include <string>

/**
 * @class Parentheses
 * @brief Solves the Parentheses Validation Problem
 */
class Parentheses {
public:
    /**
     * @brief Given a string containing the characters 
     * '(', ')', '{', '}', '[' and/or ']',
     * determine if the input string is valid.
     * 
     * An input string is valid if:
     * 
     * Open brackets must be closed by the same type of brackets.
     * Open brackets must be closed in the correct order.
     * Every close bracket has a corresponding open bracket of the same type.
     * 
     * @param s the string in which we will validate the parentheses
     * @return the result of the validation
     */
    bool isValid(std::string s);
};

#endif // PARENTHESES_H
