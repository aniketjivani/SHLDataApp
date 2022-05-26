@info "Launched"
using HTTP
using Dash, DashCoreComponents, DashHtmlComponents
using DelimitedFiles
using Printf
# using Plotly
# using Plots
# plotly()


@info "Loaded"
function makePlot(p)
    if isnothing(p)
        return Plot(1:100, rand(100),
                       mode="markers"
                       )
    else
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











