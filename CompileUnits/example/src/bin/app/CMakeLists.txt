add_compile_unit(
  NAME example::app
  TYPE EXECUTABLE
  SRCS
    src/main.cpp
  TSTS
    test/unit.cpp
  DEPS
    example::lib
)

# For integration tests, which may depend on other targets, you can manually
# add `TESTS` compile units which specify their additional dependencies.
add_compile_unit(
  NAME example::app::integration
  TYPE TESTS
  SRCS
    test/integration.cpp
  DEPS
    example::lib::interface
)
