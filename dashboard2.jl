using Dash, DashCoreComponents, DashHtmlComponents
using DelimitedFiles
using Printf
using NetCDF
using Plots
# plotly()


using ColorSchemes
using Dates
using JLD
using ShiftedArrays
# using CSV, DataFrames


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

function loadRMSEData(filePath)

    d = load(filePath)

    UrOptRMSE = d["rmseUr"]
    NpOptRMSE = d["rmseNp"]
    BzOptRMSE = d["rmseBz"]

    return UrOptRMSE, NpOptRMSE, BzOptRMSE
end

"""
Make heatmap of quantity, for eg RMSE, OTS, etc which varies with latitude and longitude.
Typically quantity will be defined for multiple runs, so make heatmap for specified `plotIdx`
"""
function plotLatLonHeatmap(latVals, lonVals, latLonQoI, plotIdx; 
                           lat=-4,
                           lon=172,
                        qoi = "Ur", 
                        clims=(0, 300), 
                        palette=cgrad(:RdBu_9, rev=true), 
                        colorbar=true, 
                           ylabel="Latitude")
    plotly()
    p = heatmap(lonVals, latVals, latLonQoI[:, :, plotIdx], clim=clims,
	        c=palette)
    titleText = "QoI: " * qoi * " Run $(runsToKeep[plotIdx] + 20)"
    plot!(xlabel="Longitude", ylabel=ylabel, title=titleText)
    plot!(xlims=(170, 190))
    plot!(ylims=(-10, 20))
    plot!(colorbar=colorbar)
    plot!(legend=false)
    scatter!([180], [7], marker=(:circle, 6, :blue), label="")
    scatter!([lon],[lat])
             # annotations = (pLon + 0.6, pLat - 0.6, Plots.text("($pLon, $pLat)", :center, :blue, 10))
    plot!(size=(500, 400))

    dataFig = Plots.plotly_series(p)
    dataFig[1][:x] = string.(lonVals)
    dataFig[1][:y] = string.(latVals)
    dataFig[1][:type] = "heatmap"
    dataFig[1][:z] = [latLonQoI[i, :, plotIdx] for i in 1:length(latVals)]
    layoutFig = Plots.plotly_layout(p)

    # fix overlapping of axis title and tick labels
   layoutFig[:xaxis][:standoff] = 20
   layoutFig[:yaxis][:standoff] = 20

   layoutFig[:title] = Dict{Symbol, Any}(:text=>titleText, :x=>0.5, :xanchor=>"center", :xref=>"paper")
    delete!(layoutFig, :annotations)
    layoutFig[:margin] = Dict{Symbol, Any}(:l => 40, :b=> 40, :r=>0, :t=>30) 
    figure = (data = dataFig, layout = layoutFig)
    return figure
end

"""
Make plot of given run at given latitude and longitude and also plot the 
corresponding shifted version based on specified shifts.
"""
function plotShiftedQoI(ots, plotIdx, times, lat, lon, latVec, lonVec;
                        plot_obs=true, 
                        palette=:Dark2_8,
                        tickInterval=12,
                        tickFormat="dd-mm",
                        linealpha=0.6,
                        xlabel="start time",
                        qoi="Ur",
                        ylims=(200, 800),
                        legend=true,
                        )
        latIndex = findall(x -> x==lat, latVec)[1]
    lonIndex = findall(x -> x==lon, lonVec)[1]
		if qoi == "Ur"
			#obs = UrObs
			sim = UrSim[latIndex, lonIndex, :, plotIdx]
			#ylimits=(200, 800)
		elseif qoi == "Bz"
			#obs = BzObs
			sim = BzSim[latIndex, lonIndex, :, plotIdx]
			#ylimits=(-20, 20)
		elseif qoi == "Np"
			#obs = NpObs
			sim = NpSim[latIndex, lonIndex, :, plotIdx]
			#ylimits=(0, 100)
		end
    pLatLon = latLonPlotAllSamples(qoi, plotIdx, times, lat, lon; palette=:OrRd_9, ylabel=qoi, xlabel=xlabel) 

                            
    chosenOTS = ots[latIndex, lonIndex, plotIdx]
    qoiShifted = lag(sim, chosenOTS)
    plot!(pLatLon,
        qoiShifted, 
        line=(:blue, 2),
        label = "Shifted, OTS = $(chosenOTS)"
        )

        plot!([34], seriestype=:vline, line=(:green, 2), label="Arrival: 2014-09-12T15:26")
    # convert to plotly figure!!!!!
     plot!(size=(500, 400))

    titleText = "Lat=: " * "$(lat)" * " Lon=: " * "$(lon)"
    dataFig = Plots.plotly_series(pLatLon)
    #dataFig[1][:x] = string.(lonVals)
    #dataFig[1][:y] = string.(latVals)
    #dataFig[1][:type] = "heatmap"
    #dataFig[1][:z] = [latLonQoI[i, :, plotIdx] for i in 1:length(latVals)]
    layoutFig = Plots.plotly_layout(pLatLon)

    # fix overlapping of axis title and tick labels
   layoutFig[:xaxis][:standoff] = 20
   layoutFig[:yaxis][:standoff] = 20

   layoutFig[:title] = Dict{Symbol, Any}(:text=>titleText, :x=>0.5, :xanchor=>"center", :xref=>"paper")
    delete!(layoutFig, :annotations)
    layoutFig[:margin] = Dict{Symbol, Any}(:l => 40, :b=> 40, :r=>0, :t=>30) 
    figure = (data = dataFig, layout = layoutFig)
    return figure
end
"""
chosenQoI can be one of Ur, Np, Bz and B. Plotting_range can be something like 1:5, and so on.
Note that plotting_range will need to be converted back into original index while processing results.
"""
function latLonPlotAllSamples(chosenQoI, plotIdx, timesSim, lat, lon;
                            plot_obs=true, 
			    palette=:Dark2_8,
			    tickInterval=12,
			    linealpha=0.6,
			    xlabel="",
                            ylabel="Ur"
			    )
    
		latIndex = findall(x -> x==lat, latitudes)[1]
		lonIndex = findall(x -> x==lon, longitudes)[1]
	
		if chosenQoI == "Ur"
			obs = UrObs
			qoi = UrSim[latIndex, lonIndex, :, plotIdx]
			ylimits=(200, 800)
		elseif chosenQoI == "Bz"
			obs = BzObs
			qoi = BzSim[latIndex, lonIndex, :, plotIdx]
			ylimits=(-20, 20)
		elseif chosenQoI == "Np"
			obs = NpObs
			qoi = NpSim[latIndex, lonIndex, :, plotIdx]
			ylimits=(0, 100)
		end

    nLines = length(plotIdx)
		nTimePoints = size(qoi, 1)

		obsTimeTicks = range(timesSim[1], timesSim[end], step=Hour(tickInterval))
		SHLTicks  = findall(in(obsTimeTicks), timesSim)
    	SHLTickLabels = Dates.format.(obsTimeTicks, "dd-mm")

	
		if nLines <= 30
			if nLines == 1
				lineLabels = "run " * string(runsToKeep[plotIdx] + 20)
			else
				labelsVec = "run " .* string.(runsToKeep[plotIdx] .+ 20)
				lineLabels = reshape(labelsVec, 1, nLines)
			end
			p = plot(1:nTimePoints, qoi, line=(2.5), linealpha=linealpha, labels=lineLabels, line_z = (1:nLines)', color=palette)

			plot!(xticks=(SHLTicks, SHLTickLabels))
			plot!(xminorticks=tickInterval)
			plot!(colorbar=:false)
		else
			p = plot(1:nTimePoints, qoi, line=(2.5), linealpha=linealpha, labels="", line_z = (1:nLines)', color=palette)
			plot!(xticks=(SHLTicks, SHLTickLabels))
			plot!(xminorticks=tickInterval)
		    plot!(colorbar=false)
                end
                if plot_obs
			plot!(1:nTimePoints, obs, line=(:dash, :black, 3), label="OMNI")
		end
		if xlabel==""
			plot!(xlabel="")
		else
                    plot!(xlabel="Start Time: $startTime")
		#	plot!(xlabel="Start Time: $(Dates.format(startTime, "dd-u-yy HH:MM:SS"))")
		end
    # plot!(1:nTimePoints, 
		plot!(ylabel=chosenQoI)
		plot!(xlims=(1, nTimePoints), 
			  ylims=ylimits,
			  # xticks=(1:9:nTimePoints, string.(1:9:nTimePoints)),
			 legend=:outertopright
			 )
    # plot!(title="Lat=" * "$lat" * " Lon=" * "$lon")
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

    plot!(size=(800, 630))
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
    delete!(layoutFig, :annotations)
    layoutFig[:margin] = Dict{Symbol, Any}(:l => 40, :b=> 40, :r=>0, :t=>30) 
    figure = (data = dataFig, layout = layoutFig)
    return figure
end



"""
Function to take in distance data and plot summary showing variability across backgrounds!
"""
function plotDistanceSummary(distance_data)
    pDist = plot()
    latVals = collect(-20:20)
    latPlotColors = ColorSchemes.RdBu
    lineColors = [latPlotColors[i] for i in range(0, 1, length=41)]
    for (bgIdx,bg) in enumerate([1, 4, 6, 8, 10, 13, 14, 16, 17, 19])
        for (latIdx, lat) in enumerate(latVals)
	    if bgIdx == 10
	        scatter!(pDist,
		         [bg],
			[distance_data[latIdx, bgIdx]], 
                         marker=(:circle, 3, lineColors[latIdx]), 
                         markerstrokewidth=0,
                         label="Lat = $(lat)"
                         )
            else
                scatter!(pDist,
                         [bg],
                         [distance_data[latIdx, bgIdx]], 
                         marker=(:circle, 3, lineColors[latIdx]), 
                         markerstrokewidth=0,
                         label=""
                         )
            end
        end
    end
    
     plot!(size=(800, 600))
     plot!(xticks=([1, 4, 6, 8, 10, 13, 14, 16, 17, 19], string.([1, 4, 6, 8, 10, 13, 14, 16, 17, 19])))
    plot!(xlabel= "Background run ID")
    plot!(ylabel= "avg(dist_u + dist_n)")
    # convert to plotly figure
    dataFig = Plots.plotly_series(pDist)
    layoutFig = Plots.plotly_layout(pDist)

    
    # fix overlapping of axis title and tick labels
    layoutFig[:xaxis][:standoff] = 20
    layoutFig[:yaxis][:standoff] = 20

   # layoutFig[:title] = Dict{Symbol, Any}(:text=>titleText, :x=>0.5, :xanchor=>"center", :xref=>"paper")
    
    layoutFig[:margin] = Dict{Symbol, Any}(:l => 40, :b=> 40, :r=>0, :t=>30) 
    figure = (data = dataFig, layout = layoutFig)
    return figure
end
                   
# Let's make the app :)

dropdown_options = [Dict("label" => string.(i), "value" => i) for i in collect(-20:20)]
bg_options = [Dict("label" => string.(i), "value" => i) for i in [1, 4, 6, 8, 10, 13, 14, 16, 17, 19]]


dist_data = load("bg_2154_distances.jld", "summed_dist")
runsToKeep = load("restart_shl_CR2154.jld", "runsToKeep")
UrOptRMSE, NpOptRMSE, BzOptRMSE = loadRMSEData("restart_shl_CR2154.jld")
UrOTS = load("restart_shl_CR2154.jld", "otsUr")

# Load QoI data here!
EVENT_PATH = "shl_2021_11_08_AWSoM_CR2154.nc"
UrSim = ncread(EVENT_PATH, "UrSim")
BzSim = ncread(EVENT_PATH, "BzSim")
NpSim = ncread(EVENT_PATH, "NpSim")
#BSim  = ncread(EVENT_PATH, "BSim") 
	
UrObs = ncread(EVENT_PATH, "UrObs")
BzObs = ncread(EVENT_PATH, "BzObs")
NpObs = ncread(EVENT_PATH, "NpObs")
#BObs  = ncread(EVENT_PATH, "BObs")

latitudes = ncread(EVENT_PATH, "lat")
longitudes = ncread(EVENT_PATH, "lon")
	
timeElapsed = Dates.Hour.(ncread(EVENT_PATH, "time"))
startTime = ncgetatt(EVENT_PATH, "time", "shlStartTime")

times = timeElapsed .+ Dates.DateTime(startTime, "yyyy_mm_ddTHH:MM:SS")

# allRMSEData = CSV.read("allRMSEData_CR2154_old.csv", DataFrame)

explanatory_text = "
#### Overview:

- QoIs at different latitudes from -20 through 20 are marked in the plot below.

- Scrolling while hovering on the legend entries reveals the full legend.

- Clicking any one or more of the legend entries toggles visibility of the corresponding trace.

- We can zoom in using supplied controls to focus on area before map time.

"


markdown_text = "
#### All backgrounds
Below we plot the average of `dist_u` and `dist_n` for all backgrounds, these values being colored by latitude as indicated by the legend. Run 4 has the smallest overall distances, and distances seem to drop with decrease in latitude. Distances are calculated using 7 day window before map time.
"

restart_markdown = "
#### Restart SHL data
Next we can view the penalized shifted RMSE for different latitudes and longitudes, for the restart runs. Earth is marked in blue, and we can locate a particular lat and lon by moving the sliders (green circle on plot). These are old restart data (Orientation not changing).

The sliders below control the run we are viewing and the highlighted latitude and longitude. However, over here it seems that the lower RMSEs in general are observed at positive latitudes (opposite of what we saw in the backgrounds). 
" 

# app=dash(external_stylesheets=["https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css"])

app=dash()
app.title = "SHL Background plots for CR2154"

app.layout = html_div() do
    html_h1("SHL Background Data", style=(textAlign="center")),
    dcc_markdown(explanatory_text),
    html_div(children=[html_label("Select Latitudes"),
        dcc_checklist(id="Latitudes", options = dropdown_options, value=[-4, 7]),
        html_label("Select Background"),
        dcc_radioitems(id="Background runs", options= bg_options, value=[4])],
        style = Dict("columnCount" => 2)),
    html_div(
             children=[
                 dcc_graph(id="UrPlot",
                           figure=makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=4), style=Dict("width"=>"48%", "display"=>"inline-block")),
                 dcc_graph(id="NpPlot",
                           figure=makeLatPlots("./all_bg_shl_CR2154.jld"; bgRun=4, qoi="Np", ylims=(0, 70)), style=Dict("width"=>"48%", "display"=>"inline-block"))
            ]
             ),
    dcc_markdown(markdown_text),
    dcc_graph(id="Distance Summary",
              figure=plotDistanceSummary(dist_data)
              ),
    dcc_markdown(restart_markdown),
    html_label("Select Plot Idx"),
    dcc_slider(id="Plot Idx Slider",
        min=1,
        max=132,
        step=1,
       value=1,
       marks=Dict([i=>string.(i) for i in 1:132]) 
 #       marks=nothing,
 #       tooltip=Dict(:placement=>"bottom", :always_visible=>true)
               ),
    html_label("Select Latitudes"),
    dcc_slider(id="Latitude Slider",
        min=-10,
        max=20,
        step=2,
        value=-4,
        marks=Dict([i => string.(i) for i in collect(-10:2:20)])       
               ),
    html_label("Select Longitudes"),
    dcc_slider(id="Longitude Slider",
        min=170,
        max=190,
        step=2,
        value=180,
        marks=Dict([i => string.(i) for i in collect(170:2:190)])       
    ),
    html_div(# style=Dict("columnCount"=>3),
             children=[
                 dcc_graph(id="UrHeatmap",
                           figure=plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), UrOptRMSE, 1; qoi = "Ur", clims=(0, 350), palette=:YlOrRd_9, colorbar=true),
                           style=Dict("width"=>"32%", "display"=>"inline-block")
                           ),
                 dcc_graph(id="NpHeatmap",
                           figure=plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), NpOptRMSE, 1; qoi = "Np", clims=(0, 35), palette=:YlOrRd_9, colorbar=true),
                           style=Dict("width"=>"32%", "display"=>"inline-block")
                           ),
                 dcc_graph(id="BzHeatmap",
                           figure=plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), BzOptRMSE, 1; qoi = "Bz", clims=(0, 20), palette=:YlOrRd_9, colorbar=true),
                           style=Dict("width"=>"32%", "display"=>"inline-block")
                           )
             ]),
    html_div(
    children=[
        dcc_graph(id="UrSim",
                  figure=plotShiftedQoI(UrOTS, 1, times, 7, 180, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Ur", legend=true),  
                  style=Dict("width"=>"32%", "display"=>"inline-block")
        ),
        dcc_graph(id="NpSim",
                  figure=plotShiftedQoI(UrOTS, 1, times, 7, 180, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Np", legend=true),
                  style=Dict("width"=>"32%", "display"=>"inline-block")
        ),
        dcc_graph(id="BzSim",
                  figure=plotShiftedQoI(UrOTS, 1, times, 7, 180, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Bz", legend=true),
                  style=Dict("width"=>"32%", "display"=>"inline-block")
        )
        ]
    )
    # html_div(
    # children=html_table([
    # html_thead(html_tr([html_th(col) for col in names(allRMSEData)])),
    # html_tbody([
    #     html_tr([html_td(allRMSEData[r, c]) for c in names(allRMSEData)]) for r = 1:min(nrow(allRMSEData), size(allRMSEData, 1))]),
    # ], style=Dict("text-align"=>"center"))
    # )
    # RMSE table
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


callback!(app, Output("UrHeatmap", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
             plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), UrOptRMSE, selectedPlot; lat=selectedLat, lon=selectedLon, qoi = "Ur", clims=(0, 350), palette=:YlOrRd_9, colorbar=true)
             end

callback!(app, Output("NpHeatmap", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
             plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), NpOptRMSE, selectedPlot; lat=selectedLat, lon=selectedLon, qoi = "Np", clims=(0, 35), palette=:YlOrRd_9, colorbar=true)
             end


callback!(app, Output("BzHeatmap", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
             plotLatLonHeatmap(sort([collect(-10:2:20); 7]), collect(170:2:190), BzOptRMSE, selectedPlot; lat=selectedLat, lon=selectedLon, qoi = "Bz", clims=(0, 20), palette=:YlOrRd_9, colorbar=true)
          end

callback!(app, Output("UrSim", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
               plotShiftedQoI(UrOTS, selectedPlot, times, selectedLat, selectedLon, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Ur", legend=true)
          end

callback!(app, Output("NpSim", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
               plotShiftedQoI(UrOTS, selectedPlot, times, selectedLat, selectedLon, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Np", legend=true)
          end

callback!(app, Output("BzSim", "figure"),
          Input("Plot Idx Slider", "value"),
          Input("Latitude Slider", "value"),
          Input("Longitude Slider", "value"),
          ) do selectedPlot, selectedLat, selectedLon
               plotShiftedQoI(UrOTS, selectedPlot, times, selectedLat, selectedLon, latitudes, longitudes; palette=:OrRd_9, xlabel="start time", qoi="Bz", legend=true)
             end
# port = something(tryparse(Int, get(ARGS, 1, "")), tryparse(Int, get(ENV, "PORT", "")), 8080)

# run_server(app, "0.0.0.0", port)


## TO DO: Add markdown description of app before plots, including controls etc,
# add heatmaps of RE-computed RMSE for shl_data, and place them below the QoI plots.
# Save a static HTML version of the page as well!
