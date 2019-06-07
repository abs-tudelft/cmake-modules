cmake_minimum_required(VERSION 3.14)

project(example
	VERSION 0.1.0
	DESCRIPTION "An example project for the CompileUnits module"
	LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the CompileUnits CMake module
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/..)

# FetchContent_Declare(cmake-modules
#   GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
#   GIT_TAG         master
# )
# FetchContent_MakeAvailable(cmake-modules)

include(CompileUnits)

# Enable tests
SET(BUILD_TESTS ON CACHE BOOL "")

# Add all directories with `CMakeLists.txt` files which add compile units.
add_subdirectory(src)

# Always call the `compile_units` function after adding all the compile units
# with the `add_compile_unit` function.
compile_units()
