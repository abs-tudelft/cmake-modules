include(CMakeParseArguments)

# TODO: option
include(FetchContent)
include(GoogleTest)
enable_testing()
FetchContent_Declare(googletest
  GIT_REPOSITORY  https://github.com/google/googletest.git
  GIT_TAG         main
)
FetchContent_GetProperties(googletest)
if(NOT googletest_POPULATED)
  FetchContent_Populate(googletest)
  set(INSTALL_GTEST OFF CACHE BOOL "")
  add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR} EXCLUDE_FROM_ALL)
  set_target_properties(gtest gtest_main gmock gmock_main PROPERTIES CXX_CLANG_TIDY "" CXX_STANDARD 11 CXX_STANDARD_REQUIRED ON)
endif()

option(BUILD_TESTS "Build tests" OFF)

FetchContent_Declare(benchmark
  GIT_REPOSITORY  https://github.com/google/benchmark.git
  GIT_TAG         main
)
FetchContent_GetProperties(benchmark)
if(NOT benchmark_POPULATED)
  FetchContent_Populate(benchmark)
  set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "")
  set(BENCHMARK_ENABLE_GTEST_TESTS OFF CACHE BOOL "")
  add_subdirectory(${benchmark_SOURCE_DIR} ${benchmark_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()
option(BUILD_BENCHMARKS "Build benchmarks" OFF)

define_property(GLOBAL PROPERTY FCM BRIEF_DOCS "." FULL_DOCS ".")

function(add_compile_unit)
  set(options
    OPT   # Mark unit as optional. Ignored for tests.
  )
  set(single
    NAME      # Target name
    TYPE      # Compile unit type: SHARED | OBJECT | EXECUTABLE | TESTS | INTERFACE | BENCHMARK
    COMPONENT # Group name
  )
  set(multi
    SRCS  # List of sources
    TSTS  # List of tests
    DEPS  # List of dependencies
    PRPS  # List of properties <prop1> <value1> <prop2> <value2>
    BNCH  # List of benchmarks
  )
  cmake_parse_arguments(X "${options}" "${single}" "${multi}" ${ARGN})

  # Default behavior is OBJECT_LIBRARY
  if(NOT X_TYPE)
    set(X_TYPE OBJECT)
  endif()

  if(NOT X_COMPONENT)
    set(X_COMPONENT "Unspecified")
  endif()

  # test shortcut
  if (X_TSTS)
    foreach(TST ${X_TSTS})
      get_filename_component(X_TST_NAME ${TST} NAME_WE)
      set(X_TST_DEP)
      if(NOT ${X_TYPE} MATCHES EXECUTABLE)
        list(APPEND X_TST_DEP ${X_NAME})
      endif()
      add_compile_unit(
        NAME ${X_NAME}::${X_TST_NAME}
        TYPE TESTS
        SRCS
          ${TST}
        DEPS
          gmock_main
          ${X_DEPS}
          ${X_TST_DEP}
        PRPS
          ${X_PRPS}
      )
    endforeach()
  endif()

  # benchmark shortcut
  if (X_BNCH)
    foreach(BNCH ${X_BNCH})
      get_filename_component(X_BNCH_NAME ${BNCH} NAME_WE)
      set(X_BNCH_DEP)
      if(NOT ${X_TYPE} MATCHES EXECUTABLE)
        list(APPEND X_BNCH_DEP ${X_NAME})
      endif()
      add_compile_unit(
        NAME ${X_NAME}::${X_BNCH_NAME}
        TYPE BENCHMARK
        SRCS
          ${BNCH}
        DEPS
          benchmark_main
          ${X_DEPS}
          ${X_BNCH_DEP}
        PRPS
          ${X_PRPS}
      )
    endforeach()
  endif()

  # Target names use underscores, an alias with the provided name is added
  string(REPLACE "::" "_" X_NAME ${X_NAME})

  # Create compile unit option
  string(TOUPPER "${X_NAME}" X_OPTION_NAME)
  if(NOT X_TYPE MATCHES TESTS)
    if(X_OPT)
      option(BUILD_${X_OPTION_NAME} "Build ${X_NAME}" OFF)
    else()
      option(BUILD_${X_OPTION_NAME} "Build ${X_NAME}" ON)
    endif()
  endif()

  set_property(GLOBAL APPEND PROPERTY FCM FCM_${X_NAME})

  # single
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_NAME ${X_NAME})
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_TYPE ${X_TYPE})
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_COMPONENT ${X_COMPONENT})
  # multi
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_SRCS ${X_SRCS})
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_DEPS ${X_DEPS})
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_PRPS ${X_PRPS})
  # metadata
  set_property(GLOBAL PROPERTY FCM_${X_NAME}_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  # set_global(${X_NAME} BIN_DIR ${CMAKE_INSTALL_BINDIR})

endfunction()

function(compile_units)
  # Make a copy of the global list
  get_property(FCM GLOBAL PROPERTY FCM)
  get_property(FCM_COPY GLOBAL PROPERTY FCM)

  # Drop all units disabled by option
  foreach(LIB ${FCM_COPY})
    get_property(X_TYPE GLOBAL PROPERTY ${LIB}_TYPE)
    if(NOT X_TYPE MATCHES TESTS AND NOT X_TYPE MATCHES BENCHMARK)
      get_property(X_NAME GLOBAL PROPERTY ${LIB}_NAME)
      string(TOUPPER "${X_NAME}" X_OPTION_NAME)
      if(NOT BUILD_${X_OPTION_NAME})
        list(REMOVE_ITEM FCM_COPY ${LIB})
      endif()
    else()
      if(X_TYPE MATCHES TESTS AND NOT BUILD_TESTS)
        list(REMOVE_ITEM FCM_COPY ${LIB})
      endif()
      if(X_TYPE MATCHES BENCHMARK AND NOT BUILD_BENCHMARKS)
        list(REMOVE_ITEM FCM_COPY ${LIB})
      endif()
    endif()
  endforeach()
  set(FCM_COUNT)
  while(FCM_COPY)
    if (FCM_COUNT EQUAL 1000)
      message(FATAL_ERROR "Recursion limit. You may have a circular dependency.")
    endif()
    set(FCM_NEXT)
    foreach(LIB ${FCM_COPY})
      get_property(X_NAME GLOBAL PROPERTY ${LIB}_NAME)
      set(X_OBJ_SRCS)
      set(X_SKIP NO)
      get_property(X_DEPS GLOBAL PROPERTY ${LIB}_DEPS)

      if (X_DEPS)
        foreach(X IN LISTS X_DEPS)
          if (NOT TARGET ${X})
            string(REPLACE "::" "_" X_NAME ${X})
            get_property(X_NAME_EXISTS GLOBAL PROPERTY FCM_${X_NAME}_NAME)
            if (NOT X_NAME_EXISTS)
              find_library(X_LIB ${X})
              if(X_LIB)
                continue()
              endif()
              get_property(NAME GLOBAL PROPERTY ${LIB}_NAME)
              string(REPLACE "_" "::" TARGET_NAME ${NAME})
              message(FATAL_ERROR "Dependency ${X} for ${TARGET_NAME} does not exist. No such target, compilation unit or library.")
            else()
              list(FIND FCM_COPY FCM_${X_NAME} FCM_X_TODO)
              if(FCM_X_TODO EQUAL -1)
                list(FIND FCM_NEXT FCM_${X_NAME} FCM_X_ADDED)
                if(FCM_X_ADDED EQUAL -1)
                  list(APPEND FCM_NEXT FCM_${X_NAME})
                  set(X_SKIP YES)
                endif()
              endif()
            endif()
            list(FIND FCM_NEXT ${LIB} FCM_X_ADDED)
            if(FCM_X_ADDED EQUAL -1)
              list(APPEND FCM_NEXT ${LIB})
            endif()
            set(X_SKIP YES)
            break()
          endif()
          get_target_property(TYPE ${X} TYPE)
          if (${TYPE} MATCHES OBJECT_LIBRARY)
            list(APPEND X_OBJ_SRCS $<TARGET_OBJECTS:${X}>)
            get_target_property(X_OBJ_DEPS ${X} OBJ_DEPS)
            if (X_OBJ_DEPS)
              list(APPEND X_OBJ_SRCS ${X_OBJ_DEPS})
            endif()
          else()
            if (${TYPE} MATCHES EXECUTABLE)
              list(REMOVE_ITEM X_DEPS ${X})
            endif()
          endif()
        endforeach()
      endif()

      if (X_SKIP)
        continue()
      endif()

      # single
      get_property(NAME GLOBAL PROPERTY ${LIB}_NAME)
      get_property(TYPE GLOBAL PROPERTY ${LIB}_TYPE)
      get_property(COMPONENT GLOBAL PROPERTY ${LIB}_COMPONENT)
      # multi
      get_property(SRCS GLOBAL PROPERTY ${LIB}_SRCS)
      get_property(PRPS GLOBAL PROPERTY ${LIB}_PRPS)
      # metadata
      get_property(SRC_DIR GLOBAL PROPERTY ${LIB}_SRC_DIR)

      string(REPLACE "_" "::" TARGET_NAME ${NAME})

      if (SRCS)
        set(ABS_SRCS)
        foreach(SRC ${SRCS})
          if(IS_ABSOLUTE ${SRC})
            list(APPEND ABS_SRCS ${SRC})
          else()
            get_filename_component(ABS_PATH ${SRC_DIR}/${SRC} ABSOLUTE)
            list(APPEND ABS_SRCS ${ABS_PATH})
          endif()
        endforeach()
        set(SRCS ${ABS_SRCS})
      endif()

      if (${TYPE} MATCHES OBJECT OR ${TYPE} MATCHES SHARED OR ${TYPE} MATCHES INTERFACE)
        add_library(
          ${NAME}
          ${TYPE}
          ${SRCS}
          ${X_OBJ_SRCS}
        )
        if(NOT TARGET_NAME STREQUAL NAME)
          add_library(
            ${TARGET_NAME}
            ALIAS ${NAME}
          )
        endif()
        if (${TYPE} MATCHES INTERFACE)
          target_include_directories(
            ${NAME}
            INTERFACE
              $<BUILD_INTERFACE:${SRC_DIR}/include>
              $<INSTALL_INTERFACE:include>
          )
        else()
          target_include_directories(
            ${NAME}
            PUBLIC
              $<BUILD_INTERFACE:${SRC_DIR}/src>
              $<BUILD_INTERFACE:${SRC_DIR}/include>
              $<BUILD_INTERFACE:${SRC_DIR}/test>
              $<INSTALL_INTERFACE:include>
          )
        endif()
        if(EXISTS ${SRC_DIR}/include/)
          install(
            DIRECTORY ${SRC_DIR}/include/
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            COMPONENT ${COMPONENT}
          )
        endif()
        if(${TYPE} MATCHES SHARED)
          # shared libraries are installed
          install(
            TARGETS ${NAME}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT ${COMPONENT}
          )
        endif()
        if(${TYPE} MATCHES OBJECT)
          # Use position independent code for object libraries
          set_property(TARGET ${NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)
        endif()
      endif()

      if (${TYPE} MATCHES EXECUTABLE OR ${TYPE} MATCHES TESTS OR ${TYPE} MATCHES BENCHMARK)
        if(TYPE MATCHES TESTS AND NOT BUILD_TESTS)
          continue()
        endif()
        if(TYPE MATCHES BENCHMARK AND NOT BUILD_BENCHMARKS)
          continue()
        endif()
        add_executable(
          ${NAME}
          ${SRCS}
          ${X_OBJ_SRCS}
        )
        if (${TYPE} MATCHES EXECUTABLE)
          install(
            TARGETS ${NAME}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT ${COMPONENT}
          )
        endif()
        if (${TYPE} MATCHES TESTS)
          set(X_TEST_PREFIX ${TARGET_NAME})
          string(APPEND X_TEST_PREFIX "::")
          list(APPEND X_DEPS gmock_main)
          gtest_discover_tests(${NAME} TEST_PREFIX ${X_TEST_PREFIX})
        endif()
        if (${TYPE} MATCHES BENCHMARK)
          set(X_BENCHMARK_PREFIX ${TARGET_NAME})
          string(APPEND X_BENCHMARK_PREFIX "::")
          list(APPEND X_DEPS benchmark_main)
        endif()
      endif()

      if(X_OBJ_SRCS)
        set_target_properties(${NAME} PROPERTIES OBJ_DEPS "${X_OBJ_SRCS}")
      endif()

      if(PRPS)
        set_target_properties(${NAME} PROPERTIES ${PRPS})
      endif()

      target_link_libraries(
        ${NAME}
        ${X_DEPS}
      )

    endforeach()

    set(FCM_COPY ${FCM_NEXT})
    MATH(EXPR FCM_COUNT "${FCM_COUNT}+1")

  endwhile()

  set_property(GLOBAL PROPERTY FCM)

endfunction()
