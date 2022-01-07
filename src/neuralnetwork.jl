module NeuralNetwork

include("data.jl")
include("plotutils.jl")

using Flux
using Flux: onehotbatch, onecold
using Flux.Data: DataLoader
using Flux.Losses: logitcrossentropy
using Plots
using PlotlyJS
using MLDatasets

export get_moon_data, get_nmist_data, get_loss_and_accuracy, train

function get_moon_data(args)
	x_train, y_train = Data.get_moons(300, offset = 1.0)
	x_test, y_test = Data.get_moons_from_publication()

	x_train = transpose(x_train)
	y_train, y_test = onehotbatch(y_train, 0:1), onehotbatch(y_test, 0:1)

	# create data loaders
	train_loader = DataLoader((x_train, y_train), batchsize = args.batchsize, shuffle = true)
	test_loader = DataLoader((x_test, y_test), batchsize = args.batchsize)

	return train_loader, test_loader
end

function get_nmist_data(args)
	# Loading Dataset	
	xtrain, ytrain = MLDatasets.MNIST.traindata(Float32)
	xtest, ytest = MLDatasets.MNIST.testdata(Float32)
	
	# Reshape Data in order to flatten each image into a linear array
	xtrain = Flux.flatten(xtrain)
	xtest = Flux.flatten(xtest)

	# One-hot-encode the labels
	ytrain, ytest = onehotbatch(ytrain, 0:9), onehotbatch(ytest, 0:9)

	# Create DataLoaders (mini-batch iterators)
	train_loader = DataLoader((xtrain, ytrain), batchsize=args.batchsize, shuffle=true)
	test_loader = DataLoader((xtest, ytest), batchsize=args.batchsize)

	return train_loader, test_loader
end

function get_loss_and_accuracy(data_loader::Flux.Data.DataLoader, model)
	accuracy = 0
	loss = 0.0f0
	num = 0
	for (x, y) in data_loader
		ŷ = model(y)
		loss += logitcrossentropy(ŷ, y, agg = sum)
		accuracy += sum(onecold(ŷ) .== onecold(y))
		num += size(x)[end]
	end
	return loss / num, accuracy / num
end

function neural_network()
	return Chain(
		Dense(2, 500, relu),
		Dense(500, 2)
	)
end

function get_prediction(loader, model)
	pred = []
	for (x, y) in loader
		push!(pred, model(y))
	end
	return pred
end

Base.@kwdef mutable struct Args
	learning_rate::Float64 = 1e-2
    batchsize::Int = 50
    epochs::Int = 100
end

function train(args...)
	args = Args(args...)

	train_loader, test_loader = get_moon_data(args) # get_nmist_data(args)

	# plot train and test data sets
	p_train = Plots.scatter(
		train_loader.data[1][1,:], train_loader.data[1][2,:],
		 c = PlotUtils.map_bool_to_color(train_loader.data[2][1,:], "blue", "red")
	)
	p_test = Plots.scatter(
		test_loader.data[1][1,:], test_loader.data[1][2,:],
		c = PlotUtils.map_bool_to_color(test_loader.data[2][1,:], "blue", "red")
	)
	display(Plots.plot(p_train, p_test, layout = (1, 2)))

	model = neural_network()
	params = Flux.params(model)
	optimizer = ADAM(args.learning_rate) # Descent(args.learning_rate) # 

	# training
	for epoch in 1:args.epochs
		for (x, y) in train_loader
			# compute gradient
			grads = gradient(() -> logitcrossentropy(model(x), y), params)
			Flux.Optimise.update!(optimizer, params, grads)
		end

		# evaluate train and test loss and accuracy 
		train_loss, train_accuracy = get_loss_and_accuracy(train_loader, model)
		test_loss, test_accuracy = get_loss_and_accuracy(test_loader, model)
		println("Epoch $epoch")
		println("  train loss = $train_loss, train accuracy = $train_accuracy")
		println("  test loss = $test_loss, test accuracy = $test_accuracy")

		# early exit if accuracy is over threshold
		acc_thres = 0.90
		if test_accuracy > acc_thres
			@info "Stopped after $epoch epochs because test accuracy threshold of $(acc_thres * 100)% was exceeded."
			break
		end
	end

	return model
end

function plot_decision_boundary(loader, model)
	# grid and range step size
	n = 100
	# determine limits of given data
	x_max = maximum(loader.data[1][1,:]) + .25
	y_max = maximum(loader.data[1][2,:]) + .25
	x_min = minimum(loader.data[1][1,:]) - .25
	y_min = minimum(loader.data[1][2,:]) - .25

	# upper = ceil(maximum([x_max, y_max]), digits = 1, base = 2)
	# lower = floor(minimum([x_min, y_min]), digits = 1, base = 2)

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
			mode = "markers", marker = attr(color = cols, line_width = 1)
		),
		# actual contours
		PlotlyJS.contour(
			x = r_x, y = r_y, z = gr_pred, 
			contours_coloring = "heatmap", colorscale = PlotUtils.get_custom_rdbu_scale(opacity), 
			opacity = opacity
		),
		# highlight decision boundary line
		PlotlyJS.contour(
			x = r_x, y = r_y, z = gr_pred, 
			contours_start = 0, contours_end = 0, contours_size = 0,
			contours_coloring = "lines", colorscale = [[0, "black"], [1, "black"]], 
			showscale = false, line = attr(width = 3)
		)],
		Layout(
			width = 500, height = 500, autosize = true,
			xaxis_showgrid = false, yaxis_showgrid = false,
			xaxis_range = [x_min, x_max], yaxis_range = [y_min, y_max],
			xaxis = attr(zeroline = true, zerolinewidth = 1, zerolinecolor = "black", automargin = true),
			yaxis = attr(zeroline = true, zerolinewidth = 1, zerolinecolor = "black", automargin = true),
			margin = attr(l = 50, r = 50, b = 50, t = 50, pad = 0),
			plot_bgcolor = "rgba(0, 0, 0, 0)"
		),
		config = PlotConfig(
			scrollZoom = false
		)
	)
end

end