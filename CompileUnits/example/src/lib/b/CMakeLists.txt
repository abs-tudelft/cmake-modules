add_compile_unit(
  NAME example::lib::b
  SRCS
    src/b.cpp
  DEPS
  	example::lib::a
)
