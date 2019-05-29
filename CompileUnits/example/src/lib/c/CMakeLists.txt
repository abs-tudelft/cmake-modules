add_compile_unit(
  NAME example::lib::c
  SRCS
    src/c.cpp
  TSTS
  	test/unit.cpp
  DEPS
  	example::lib::a
  	example::lib::b
)
