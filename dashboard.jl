@info "Launched"
using Dash, DashCoreComponents, DashHtmlComponents
using DelimitedFiles
using Printf
using PlotlyBase
# using PlotlyJS

# using DataFrames, CSV
# using RDatasets


# iris = dataset("datasets", "iris")

@info "Loaded"
function makePlot(p)
    if isnothing(p)
        return Plot(1:100, rand(100),
                   mode="markers"
                   )
    else
#         fig = p1 = plot(
#     iris, x=:SepalLength, y=iris.SepalWidth .+ p, color=:Species,
#     mode="markers", marker_size=8
# )
#        return fig

        return Plot(1:100, rand(100) .+ p,
                       mode="markers"
                       )
    end
end
@info "Defined function"

app=dash()

app.layout = html_div() do
        html_h1("First Dash!😋😌",
                style=(textAlign="center",
                       )
                ),
        # html_label("Slider"),
        dcc_slider(
        id = "slider1",
        min = 0,
        max = 9,
        marks = Dict([i => (i == 1 ? "Label $(i)" : "$(i)") for i = 1:9]),
        value = 5,
        # type  = "number"   
        ),
        html_div("Example graph"),
        dcc_graph(id="theplot",
                  figure=makePlot(4)
                  )
    end


# callback!(makePlot, app, CallbackId([], [(Symbol(:slider1), :value)])

callback!(makePlot,
          app,
          Output("theplot", "figure"),
          Input("slider1", "value"),
          )



    



@info "Prepared plot"

# handler = make_handler(app2, debug = true)
@info "Setup and now serving..."
# HTTP.serve(handler, ip"0.0.0.0", parse(Int, length(ARGS) > 0 ? ARGS[1] : "8080"))


# run_server(app, "0.0.0.0", 8080)











