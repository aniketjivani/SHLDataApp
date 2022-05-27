

# include("./dashboard.jl")
include("./dashboard2.jl")
# println("all done here")
port = something(tryparse(Int, get(ARGS, 1, "")), tryparse(Int, get(ENV, "PORT", "")), 8080)

run_server(app, "0.0.0.0", port)
