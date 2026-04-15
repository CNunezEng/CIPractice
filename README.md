This is a project to demonstrate and practice CI toolchains.
I utilized the Copilot autocomplete for my code sample solution.

Code sample prompt from LeetCode
Valid Parentheses

Given a string s containing the characters '(', ')', '{', '}', '[' and ']', determine if the input string is valid.

I am altering to allow for other characters. 

An input string is valid if:

Open brackets must be closed by the same type of brackets.
Open brackets must be closed in the correct order.
Every close bracket has a corresponding open bracket of the same type.
 

Example 1:

Input: s = "()"

Output: true

Example 2:

Input: s = "()[]{}"

Output: true

Example 3:

Input: s = "(]"

Output: false

Example 4:

Input: s = "([])"

Output: true

Example 5:

Input: s = "([)]"

Output: false

 

Constraints:

1 <= s.length <= 104

TODO:
Add release that builds to library
add build instructions at top of this file
finish git yml
