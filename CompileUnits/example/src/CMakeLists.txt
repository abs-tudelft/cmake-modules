# In this example project there are library and binary targets. They reside in
# different subfolders and are included here. The order of the include
# statements does not have to reflect dependency ordering, as target definition
# is deferred until all compile units are declared.
add_subdirectory(bin)
add_subdirectory(lib)
