module PlotLib

include("plotutils.jl")
include("structs.jl")

using Flux
using PlotlyJS
using Plots

export plot_train_and_test_data, plot_loss_and_accuracy, plot_features, plot_decision_boundary

title_font_size = 18
tick_font_size = 16

"""
	plot_train_and_test_data(train_loader, test_loader, "Train", "Test")

Returns a PlotlyJS subplot with one row and two columns visualizing the two provided datasets.
"""
function plot_train_and_test_data(train_loader::Flux.Data.DataLoader, test_loader::Flux.Data.DataLoader; train_title = "", test_title = "")
	# define common layout
	layout = Layout(
		width = 1000, height = 1000, autosize = false,
		plot_bgcolor = "rgba(0, 0, 0, 0)", paper_bgcolor = "rgba(0, 0, 0, 0)",
		xaxis = attr(
			showgrid = true, gridcolor = "#e2e2e2",
			ticks = "outside", zeroline = false,
			tickfont = attr(size = tick_font_size)),
		yaxis = attr(
			showgrid = true, gridcolor = "#e2e2e2",
			ticks = "outside", zeroline = false,
			tickfont = attr(size = tick_font_size)),
	)

	# create two independent plots
	p_train = PlotlyJS.plot(PlotlyJS.scatter(
		x = train_loader.data[1][1,:], y = train_loader.data[1][2,:], mode = "markers",
		marker_color = PlotUtils.map_bool_to_color(train_loader.data[2][1,:], "red", "blue"),
		showlegend = false
	), layout)
	p_test = PlotlyJS.plot(PlotlyJS.scatter(
		x = test_loader.data[1][1,:], y = test_loader.data[1][2,:], mode = "markers",
		marker_color = PlotUtils.map_bool_to_color(test_loader.data[2][1,:], "red", "blue"),
		showlegend = false, showgrid = true
	), layout)

	# adjust common layout with individual titles
	# does not work for some reason :/
	PlotlyJS.relayout!(p_train, title = attr(text = train_title, font = attr(size = title_font_size)))
	PlotlyJS.relayout!(p_test, title = attr(text = test_title, font = attr(size = title_font_size)))

	# combine plots into one
	p = [p_train p_test]
	PlotlyJS.relayout!(p, plot_bgcolor = "rgba(0, 0, 0, 0)", paper_bgcolor = "rgba(0, 0, 0, 0)")
	p
end

"""
	plot_loss_and_accuracy(loss, accuracy)

Returns a PlotlyJS line plot with the data of the provided loss and accuracy vectors. 
"""
function plot_loss_and_accuracy(loss::Vector{Any}, accuracy::Vector{Any}; args...)
	args = Args(; args...)
	PlotlyJS.plot([
		PlotlyJS.scatter(y = loss, x = 1:args.epochs, mode = "lines", name = "loss"),
		PlotlyJS.scatter(y = accuracy, x = 1:args.epochs, mode = "lines", name = "accuracy")
		],
		Layout(
			title = attr(text = "Loss and Accuracy", font = attr(size = title_font_size)),
			width = 1000, height = 1000, autosize = false,
			xaxis = attr(
				showgrid = false, 
				ticks = "outside",
				tickfont = attr(size = tick_font_size)),
			yaxis = attr(
				range = [0, 1], dtick = 0.1, showgrid = false,
				ticks = "outside",
				tickfont = attr(size = tick_font_size)),
			legend = attr(font = attr(size = tick_font_size)),
			automargin = false,
			margin = attr(l = 0, r = 0, b = 0, t = 0, pad = 0),
			plot_bgcolor = "rgba(0, 0, 0, 0)",
			paper_bgcolor = "rgba(0, 0, 0, 0)"
		)
	)
end

"""
	plot_features(z1, z2)

Returns a PlotlyJS line plot with the data of both features z1 and z2. 
"""
function plot_features(z1::Vector{Float64}, z2::Vector{Float64}; args...)
	args = Args(; args...)
	PlotlyJS.plot([
		PlotlyJS.scatter(y = z1, x = 1:args.epochs, mode = "lines", name = "z1"), 
		PlotlyJS.scatter(y = z2, x = 1:args.epochs, mode = "lines", name = "z2")
		],
		Layout(
			title = attr(text = "Features", font = attr(size = title_font_size)),
			width = 1000, height = 1000, autosize = false,
			xaxis = attr(
				ticks = "outside",
				tickfont = attr(size = tick_font_size)),
			yaxis = attr(
				ticks = "outside",	
				tickfont = attr(size = tick_font_size)),
			legend = attr(font = attr(size = tick_font_size)),
			margin = attr(l = 0, r = 0, b = 0, t = 0, pad = 0),
			plot_bgcolor = "rgba(0, 0, 0, 0)",
			paper_bgcolor = "rgba(0, 0, 0, 0)"
		)
	)
end

"""
	plot_decision_boundary(train_loader, model; title = "SGD Δ0.5")

Returns a PlotlyJS contour plot of the provided dataset according to the specified model.
"""
function plot_decision_boundary(loader::Flux.DataLoader, model; title = "")
	# grid and range step size
	n = 100
	# determine limits of given data
	x_max = maximum(loader.data[1][1,:]) + .25
	y_max = maximum(loader.data[1][2,:]) + .25
	x_min = minimum(loader.data[1][1,:]) - .25
	y_min = minimum(loader.data[1][2,:]) - .25

	r_x = LinRange(x_min, x_max, n)
	r_y = LinRange(y_min, y_max, n)

	# create grid to be used for the contours
	d1 = collect(Iterators.flatten(vcat([fill(v, (n, 1)) for v in r_x])))
	d2 = collect(Iterators.flatten(vcat([reshape(r_y, 1, :) for _ in 1:n])))
	grid = hcat(d1, d2)

	# use model to predict decision boundary based on grid
	gr_pred = model(grid')
	gr_pred = reshape(gr_pred[1,:], (n, n))

	# map classes (Boolean) to integers to be used as colors
	cols = PlotUtils.map_bool_to_color(loader.data[2][1,:], "#FF0000", "#0000FF")
	opacity = 0.90

	PlotlyJS.plot([
		# data points
		PlotlyJS.scatter(
			x = loader.data[1][1,:], y = loader.data[1][2,:], 
			mode = "markers", marker = attr(color = cols, line_width = 1),
			showlegend = false
		),
		# actual contours
		PlotlyJS.contour(
			x = r_x, y = r_y, z = gr_pred, 
			contours_start = -10, contours_end = 10, contours_size = 1, 
			contours_coloring = "heatmap", colorscale = PlotUtils.get_custom_rdbu_scale(opacity), 
			colorbar = attr(thickness = 25, len = 0.9, y = 0.425), 
			opacity = opacity, showlegend = false
		),
		# highlight decision boundary line
		PlotlyJS.contour(
			x = r_x, y = r_y, z = gr_pred, 
			contours_start = 0, contours_end = 0, contours_size = 0,
			contours_coloring = "lines", colorscale = [[0, "black"], [1, "black"]], 
			showscale = false, showlegend = false, line = attr(width = 3)
		)],
		Layout(
			title = attr(text = title, font = attr(size = title_font_size)),
			width = 1000, height = 1000, autosize = false,
			xaxis = attr(
				range = [x_min, x_max],
				zeroline = false, zerolinewidth = 1, zerolinecolor = "black", 
				automargin = false, showgrid = false,
				tickfont = attr(size = tick_font_size)),
			yaxis = attr(
				range = [y_min, y_max],
				zeroline = false, zerolinewidth = 1, zerolinecolor = "black", 
				automargin = false, showgrid = false,
				tickfont = attr(size = tick_font_size)),
			legend = attr(font = attr(size = tick_font_size)),
			margin = attr(l = 0, r = 0, b = 0, t = 0, pad = 0),
			plot_bgcolor = "rgba(0, 0, 0, 0)",
			paper_bgcolor = "rgba(0, 0, 0, 0)"
		),
		config = PlotConfig(
			scrollZoom = false
		)
	)
end

end