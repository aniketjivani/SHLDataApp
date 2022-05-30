using Dash, DashCoreComponents, DashHtmlComponents
using DelimitedFiles
using Printf

using Plots
# plotly()


using ColorSchemes
using Dates
using JLD


"""
Supply path to JLD file and load all data from it.
"""
function load_data(filePath)
    d = load(filePath)
    return d
end

"""
Function to extract and return correct start and end times for sim and obs data.
"""
function getStartEndTimes(file::Dict)
    shl_times = Dates.DateTime.(file["shl_times"])
    obs_times = Dates.DateTime.(file["obs_times"])

    shl_start, shl_end = shl_times[1], shl_times[end]
    obs_start, obs_end = obs_times[1], obs_times[end]

    shlStartIdx = argmin(abs.(shl_times .- obs_start))
    shlEndIdx   = argmin(abs.(shl_times .- obs_end))

    obsStartIdx = argmin(abs.(obs_times .- shl_start))
    obsEndIdx   = argmin(abs.(obs_times .- shl_end))

    return shlStartIdx, shlEndIdx, obsStartIdx, obsEndIdx
end

function getStartEndTimes(filePath)
    d = load_data(filePath)
    shlStartIdx, shlEndIdx, obsStartIdx, obsEndIdx = getStartEndTimes(d)
end


"""
Take in shl data, obs data at all latitudes for a given background (defaults to 4 for CR2154), plot that, mark map time and shock arrival time. also highlight latitudes based on optional argument (defaults to earth and -4)
"""
function plotSHLData(simData, obsData)
    return nothing
end


"""
Take in a filepath, QoI to plot and optional args for bg run and lats to highlight, and call main plotting function (plotSHLData).

Note that we assume a lot about naming conventions and this could break if the data is saved differently in the future. For now, its a good reference point.
"""
function makeLatPlots(filePath;
                      bgRun = 4,
                      highlightLats = [-4, 7],
                      tickInterval  = 84,
                      qoi="Ur",
                      ylims=(200, 800),
                      palette=:RdBu,
                      highlight_palette=:tab10,
                      simAlpha=0.7,
                      simWidth=1.5,
                      tickFormat="dd-m HH:MM",
                      mapTime="2014-09-10T14:00:00",
                      arrivalTime="2014-09-12T15:26",
                      dpi=500
                      )
    

    d = load(filePath)

    
    
    shlStartIdx, shlEndIdx, obsStartIdx, obsEndIdx = getStartEndTimes(d)
    
    bg_runs  = d["bg"]
    bgIdx = findall(in(bgRun), bg_runs)[1]

    latVals  = d["lat"]
    
    shl_data = d[qoi * "SHL"][shlStartIdx:shlEndIdx, :, bgIdx]  
    obs      = d[qoi * "Obs"][obsStartIdx:obsEndIdx]

    times = d["shl_times"][shlStartIdx:shlEndIdx]


    timeTicks = range(DateTime(times[1]), DateTime(times[end]), step=Hour(tickInterval))
    tickVals  = findall(in(timeTicks), DateTime.(times))
    tickLabels = Dates.format.(timeTicks, tickFormat)
    
    highlightLatIdx = findall(in(highlightLats), latVals)
    mapTimeIdx = argmin(abs.(DateTime.(times) .- DateTime(mapTime)))
    arrivalTimeIdx = argmin(abs.(DateTime.(times) .- round(DateTime(arrivalTime), Hour(1))))

    nLines = length(latVals)
    labelsVec = reshape("Lat = " .* string.(latVals), 1, nLines)
    
    if length(highlightLats) > 1
        highlightColors = [ColorSchemes.colorschemes[highlight_palette][i] for i in collect(range(0, 1, length=length(highlightLats)))]'
    else
        highlightColors = "red"
    end
    
    p = plot(obs, line=(:black, :dash, 2.5), label="OMNI")
    plot!([mapTimeIdx], seriestype=:vline, line=(:black, 2), label="MapTime: $(mapTime)")
    plot!([arrivalTimeIdx], seriestype=:vline, line=(:green, 2), label="Arrival: $(arrivalTime)")


    
    
    plot!(shl_data,
          line_z = (1:nLines)',
          color=palette,
          linealpha=simAlpha,
          linewidth=simWidth,
          label=labelsVec,
          colorbar=false
          )                                                      
   
    plot!(shl_data[:, highlightLatIdx], linecolor=highlightColors, linewidth=3,
          label=reshape("Lat = " .* string.(highlightLats), 1, length(highlightLats))
          )

    plot!(xlabel="Start Time of obs: $(times[1])")
    plot!(ylims=ylims)
    plot!(ylabel=qoi)
    plot!(xticks=(tickVals, tickLabels))


    # if highlightLats == 7
    #     plot!(title = "Highlighted Lat = $(highlightLats) (earth)", titlelocation=:center)
    # else
    #     plot!(title = "Highlighted Lat = $(highlightLats)", titlelocation=:center)
    # end

    plot!(size=(800, 600))
    # return p

    dataFig = Plots.plotly_series(p)
    layoutFig = Plots.plotly_layout(p)

    # fix overlapping of axis title and tick labels
    layoutFig[:xaxis][:standoff] = 20
    layoutFig[:yaxis][:standoff] = 20

    # fix layout title
    if highlightLats == 7
        titleText = "Highlighted Lat = $(highlightLats) (earth)"
        
    else
        titleText = "Highlighted Lat = $(highlightLats)"

    end
    layoutFig[:title] = Dict{Symbol, Any}(:text=>titleText, :x=>0.5, :xanchor=>"center", :xref=>"paper")
    ## fix title position to center - note, this modifies existing annotations keyword in layout and adding a `title` keyword DOES NOT do anything!

    # layoutFig[:annotations][1][:x] = 1
    # layoutFig[:annotations][1][:xanchor]=:right
    # layoutFig[:annotations][1][:align] = "center"
    # layoutFig[:title] = Dict{Symbol, Any}(:xref=> "paper", :xanchor=>"center")
    
    layoutFig[:margin] = Dict{Symbol, Any}(:l => 40, :b=> 40, :r=>0, :t=>30) 
    figure = (data = dataFig, layout = layoutFig)
    return figure
end

                   
# Let's make the app :)

dropdown_options = [Dict("label" => string.(i), "value" => i) for i in collect(-20:20)]
bg_options = [Dict("label" => string.(i), "value" => i) for i in [1, 4, 6, 8, 10, 13, 14, 16, 17, 19]]


app=dash(external_stylesheets=["https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"])

app.title = "SHL Background plots for CR2154"

app.layout = html_div() do
        html_h1("SHL Background Data",
                style=(textAlign="center",
                       )
                ),
    
    
        # html_label("Slider"),
        # dcc_slider(
        # id = "slider1",
        # min = 0,
        # max = 9,
        # marks = Dict([i => (i == 1 ? "Label $(i)" : "$(i)") for i = 1:9]),
        # value = 5,
        # # type  = "number"
    # ),
    html_div(children=[
             html_label("Select Latitudes"),
        dcc_checklist(id="Latitudes", options = dropdown_options, value=[-4, 7]),
        html_label("Select Background"),
             dcc_radioitems(id="Background runs", options= bg_options, value=[4]),
    ],
            style = Dict("columnCount" => 2)), 
    html_br(),
    html_div(style=Dict("columnCount"=>2),
             children=[
             #children=[
             #    html_h1("Plot of QoIs at different latitudes"),
                           dcc_graph(id="UrPlot",
                                       figure=makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=4),
                                     #style=(display="inline-block")
                                     ),
                             dcc_graph(id="NpPlot",
                                       figure=makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=4, qoi="Np", ylims=(0, 70)),
                                      # style=(display="inline-block")
                                       )
            ]
    )
    end

callback!(app, Output("UrPlot", "figure"),
          Input("Latitudes", "value"),
          Input("Background runs", "value"),
          ) do selectedLats, selectedBackground
              makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=selectedBackground, highlightLats = selectedLats)
          end

callback!(app, Output("NpPlot", "figure"),
          Input("Latitudes", "value"),
          Input("Background runs", "value"),
          ) do selectedLats, selectedBackground
              makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=selectedBackground, highlightLats = selectedLats, qoi="Np", ylims=(0, 70))
          end           
# callback!(makePlot, app, CallbackId([], [(Symbol(:slider1), :value)])

# callback!(makePlot,
#           app,
#           Output("theplot", "figure"),
#           Input("slider1", "value"),
#           )

                     
# function to make plots given a set of latitudes to highlight and obs

# callback!(app, Output("power", "figure"), Input("slider", "value")) do value
#     powplot(value)
# end
# port = something(tryparse(Int, get(ARGS, 1, "")), tryparse(Int, get(ENV, "PORT", "")), 8080)

# run_server(app, "0.0.0.0", port)
