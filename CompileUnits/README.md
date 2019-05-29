# CompileUnits

Opinionated and boilerplate free CMake for C++ projects by definition of compilation units.

## Motivation

This module is the result of a struggle to generate sensible build and install targets with CMake for a large project with multiple small interdependent libraries and install targets. In the early stages of development, the project structure was changing almost daily, causing us to spend lots of time fixing all the `CMakeLists.txt` files to reflect these structural changes. For example, the introduction of a new dependency between some libraries required us to make sure ordering of target definitions allowed this and adding tests required us to copy and paste test target definitions. At some point we became frustrated and decided to write this module.

### Opionated and boilerplate free

This module is opionated. By being opiniated about the project structure, boilerplate code in your `CMakeLists.txt` files can be reduced.

### Compilation units

Compilation units are the build target abstraction defined by this module. They map to CMake targets, but provide consistent install targets and provide an easy way to define depencencies.

## Concepts

This module adds two top level functions: `add_compile_unit` and `compile_units`. The former function is used to define all the compilation units. This process is lazy i.e. no CMake target are defined until the latter function is invoked.

All compilation units have a unique name and type, and optionally some sources, tests and dependencies. Compilation units can depend on CMake targets and on other compilation units by name. Test sources added to a compilation unit declaration result in additional test targets which inherit dependencies and depend on the compilation unit declared in the declaration (unless this compilation unit is of the `EXECTUABLE` type). The different compilation unit types and their behavior is listed below.

### Libraries

There are two library types, `SHARED` and `OBJECT` (which is the default if no type is set using the `add_compile_unit` function). `OBJECT` libraries map to CMake [object libraries](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#object-libraries). `SHARED` libraries map to CMake [shared libraries](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#normal-libraries). Use the `OBJECT` type if you want the library source to compile into targets depending on it, and use the `SHARED` type if you want an install target where dependent targets link to.

| Type 		| Description 											| Install 				|
|-----------|-------------------------------------------------------|-----------------------|
| `OBJECT` 	| Compiled into dependent targets. 						| No install target 	|
| `SHARED` 	| Builds shared library. Linked to by dependent targets.| `CMAKE_INSTALL_LIBDIR`|

### Binaries

The `EXECUTABLE` compilation unit type is used to generate binary build and install targets. It maps to CMake [binary executables](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#binary-executables). Tests defined for this compilation unit only inherit dependencies.

| Type 			| Description 				| Install 					|
|---------------|---------------------------|---------------------------|
| `EXECTUABLE`	| Builds executable binary.	| `CMAKE_INSTALL_BINDIR`	|

### Tests

The `TESTS` compilation unit type is used to build test targets, Use this type if you need additional dependencies, e.g. for integration tests. When including test source files for other types, they generate `TESTS` compilation units which inherit the dependencies of the compilation unit. These compilation units map to CMake [binary executables](https://cmake.org/cmake/help/latest/manual/cmake-buildsystem.7.html#binary-executables) without an installation target.

| Type 		| Description 			| Install 				|
|-----------|-----------------------|-----------------------|
| `TESTS`	| Builds test targets.	| No install target 	|

### Includes

Library compilation unit include directories are set to `src` and `include` and are included in the install target. Dependent compilation units inherit include directories.

## Example

### Minimal library project

```
whale/
  src/
    whale.cpp
  	io.cpp
  	util.cpp
  include/
  	whale/
  		whale.hpp
  test/
  	unit.cpp
  CMakeLists.txt
```

```cmake
cmake_minimum_required(VERSION 3.14)
project(VERSION 0.1.0 DESCRIPTION "whale lib" LANGUAGES CXX)

FetchContent_Declare(cmake-modules
   GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
   GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

include(CompileUnits)

add_compile_unit(
  NAME whale
  TYPE SHARED
  SRCS
    src/whale.cpp
    src/io.cpp
    src/util.cpp
  TSTS
    test/unit.cpp
)

compile_units()
```

### Minimal library with executable project

```
whale/
  src/
    bin/
      src/
        app.cpp
      CMakeLists.txt
    lib/
      include/
        whale/
          whale.hpp
      src/
        whale.cpp
      test/
        unit.cpp
      CMakeLists.txt
  CMakeLists.txt
```

`whale/CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.14)
project(VERSION 0.1.0 DESCRIPTION "whale lib" LANGUAGES CXX)

FetchContent_Declare(cmake-modules
   GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
   GIT_TAG         master
)
FetchContent_MakeAvailable(cmake-modules)

include(CompileUnits)

add_subdirectory(src/bin)
add_subdirectory(src/lib)

compile_units()
```

`whale/src/bin/CMakeLists.txt`
```cmake
add_compile_unit(
  NAME whale::app
  TYPE EXECUTABLE
  SRCS
    src/app.cpp
  DEPS
    whale::lib
)
```

`whale/src/lib/CMakeLists.txt`
```cmake
add_compile_unit(
  NAME whale::lib
  TYPE OBJECT
  SRCS
    src/whale.cpp
  TSTS
    test/unit.cpp
)
```
