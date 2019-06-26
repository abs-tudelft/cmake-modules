add_subdirectory(a)
add_subdirectory(b)
add_subdirectory(c)
add_subdirectory(interface)

add_compile_unit(
  NAME example::lib
  TYPE SHARED
  DEPS
    example::lib::a
    example::lib::b
    example::lib::c
)
