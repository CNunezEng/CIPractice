cmake_minimum_required(VERSION 3.16)

project(CIPractice LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(parentheses
    src/Parentheses.cpp
)

target_include_directories(parentheses
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_options(parentheses
    PRIVATE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

add_executable(parentheses_tests
    src/ParenthesesTest.cpp
)

target_link_libraries(parentheses_tests
    PRIVATE
        parentheses
)

target_compile_options(parentheses_tests
    PRIVATE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra>
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

enable_testing()

add_test(
    NAME parentheses_tests
    COMMAND parentheses_tests
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
