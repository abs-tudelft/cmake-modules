# cmake-modules

[![Build Status](https://dev.azure.com/abs-tudelft/cmake-modules/_apis/build/status/abs-tudelft.cmake-modules?branchName=master)](https://dev.azure.com/abs-tudelft/cmake-modules/_build/latest?definitionId=1&branchName=master)

This is a collection of [CMake](https://cmake.org/) modules used and maintained by the [Accelerated Big Data Systems group](https://github.com/abs-tudelft).

## Modules

Currently the following modules are available.

| Module 			| Description 																					|
|-------------------|-----------------------------------------------------------------------------------------------|
| [CompileUnits] 	| Opinionated and boilerplate free CMake for C++ projects by definition of compilation units 	|

More information and examples are available inside the module directories.

## Usage

Use the [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) module to add the modules to your tree:

```cmake
include(FetchContent)

FetchContent_Declare(cmake-modules
  GIT_REPOSITORY  https://github.com/abs-tudelft/cmake-modules.git
  GIT_TAG         master
)

FetchContent_MakeAvailable(cmake-modules)
```

Include the module of interest:

```cmake
include(<some-module>)
```

You can also use any other method to add the CMake module of interest to your source tree and append the path of the CMake module to the [`CMAKE_MODULE_PATH`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) variable:

```cmake
list(APPEND CMAKE_MODULE_PATH <path-to-cmake-module>)
```

Include the module:
```cmake
include(<the-module>)
```

[CompileUnits]: https://github.com/abs-tudelft/cmake-modules/tree/master/CompileUnits
