add_compile_unit(
  NAME example::cli
  TYPE EXECUTABLE
  COMPONENT bins
  SRCS
    src/main.cpp
  DEPS
  	example::lib::c  	
)
