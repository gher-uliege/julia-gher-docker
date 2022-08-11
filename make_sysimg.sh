#!/usr/bin/env julia                                                                                                                              

using PackageCompiler

run(`julia  --trace-compile=trace_compile.jl precompile_script.jl`)

PackageCompiler.create_sysimage(
    [:DIVAnd];
    sysimage_path="sysimg_custom.so",
    #precompile_execution_file="make_sysimg_commands.jl")                                                                                         
    precompile_statements_file="trace_compile.jl")




