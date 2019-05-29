add_compile_unit(
  NAME example::cli
  TYPE EXECUTABLE
  SRCS
    src/main.cpp
  DEPS
  	example::lib::c  	
)
