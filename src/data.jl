module Data

include("structs.jl")

using Flux
using Flux: onehotbatch
using Flux.Data: DataLoader
using Plots
using ScikitLearn
@sk_import datasets: make_moons

export get_moon_data_loader, get_nmist_data_loader

"""
    get_moon_data_loader(n = 300, offset = 0.5, shuffle = true, seed = 1337)

Returns a Flux.DataLoader with moon data for the specified parameters.
Supports creation of random moons and shuffling of the data points.  
"""
function get_moon_data_loader(; n::Int64 = 300, offset::Float64 = 0.5, shuffle::Bool = true, seed::Int64 = rand((1, 2^31)), args...)
    args = Args(; args...)

    # offset: linearly separable => 1.0; not lin. sep. => 0.5
	x, y = generate_moons(n, offset = offset, seed = seed)
	x, y = transpose(x), onehotbatch(y, 0:1)

	# create data loader
	return DataLoader((x, y), batchsize = args.batchsize, shuffle = shuffle)
end

"""
    get_nmist_data_loader(shuffle = true)

Returns a Flux.DataLoader with MNIST data for the specified parameters.
"""
function get_nmist_data_loader(; shuffle::Bool = true, args...)
    args = Args(; args...)

	x, y = MLDatasets.MNIST.traindata(Float32)
	
	# reshape Data in order to flatten each image into a linear array
    # encode labels with one-hot
	x, y = Flux.flatten(x), onehotbatch(y, 0:9)

	# create data loader
	return DataLoader((x, y), batchsize = args.batchsize, shuffle = shuffle)
end

"""
    generate_moons_from_publication(offset = 0.5, coord_down_scale = 1.0, show_plot = false)

Returns the exact same moons that were used on the demo website 
of the publication authors at https://mohammadpz.github.io/GradientStarvation.html  
"""
function generate_moons_from_publication(; offset::Float64 = 0.0, coord_down_scale::Float64 = 1.0, show_plot::Bool = false)
    moons = hcat(moon_class_1(offset, coord_down_scale), moon_class_2(offset, coord_down_scale))
    labels = [repeat([0], 150); repeat([1], 150)]

    if show_plot 
        display(scatter(moons[1,:], moons[2,:], c = labels))
    end

    return moons, labels
end

"""
    generate_moons(n = 300, noise = 0.42, offset = 0.5, rotation = 90, seed = 42, show_plot = true)

Wrapper function for scikitlearn make_moons function. Additionally features the options to rotate and offset the
moons or plot the generated data.
"""
function generate_moons(n::Int64; noise::Float64 = 0.09, offset::Float64 = 0.0, rotation::Int64 = 90, seed::Int64 = rand((1, 2^31)), show_plot::Bool = false)
    X, y = make_moons(n_samples = n, noise = noise, random_state = seed)
    p1 = scatter(X[:,1], X[:,2], c = y, title = "generated state")

    if offset != 0.0
        X = apply_moon_offset(X, y, offset)
    end
    p2 = scatter(X[:,1], X[:,2], c = y, title = "offsetted state")

    if rotation != 0.0
        θ = deg2rad(rotation)
        R = [cos(θ) -sin(θ); sin(θ) cos(θ)]
        X *= R
        # move center closer to (0, 0)
        if offset != 0.0
            X[:,2] .+= offset/2
        end
    end
    p3 = scatter(X[:,1], X[:,2], c = y, title = "rotated state")
    
    if show_plot
        display(plot(p1, p2, p3, layout = (1, 3)))
    end

    return X, y
end

"""
    apply_moon_offset(X, y, 0.5)

Separates both moons by the specified offset.
"""
function apply_moon_offset(X, y, offset)
    # @assert direction in ["x", "y"] "Error: direction must be either x or y"
    # use offset as total offset, thus devide by number of labels; assume 2 labels
    offset /= 2
    # direction == "x" ? direction = 1 : direction = 2

    moons = []
    for label in unique(y)
        push!(moons, findall(l -> l == label, y))
    end

    max_y = [maximum(X[m, 2]) for m in moons]

    if max_y[1] > max_y[2]
        X[moons[1], 2] .+= offset
        X[moons[2], 2] .-= offset
    else
        X[moons[1], 2] .-= offset
        X[moons[2], 2] .+= offset
    end

    return X
end

"""
    moon_class_1(0.0, 1.0)

Returns the hardcoded coordinates of the first moon from the author's demo website 
at https://mohammadpz.github.io/GradientStarvation.html
"""
function moon_class_1(offset::Float64 = 0.0, coord_down_scale::Float64 = 1.0)
    x = [
        -2.717835893494339 - offset,
        -2.0025756608302556 - offset,
        -2.568929506049188 - offset,
        -2.270602886384911 - offset,
        -2.5015948773601426 - offset,
        -2.330151863221954 - offset,
        -0.7415685155965577 - offset,
        -2.0839366412304012 - offset,
        -2.8528165357526083 - offset,
        -1.147008103324011 - offset,
        -2.8784004738595304 - offset,
        -0.8677959198389527 - offset,
        -1.7589836417118123 - offset,
        -2.998388218477527 - offset,
        -2.122794047965966 - offset,
        -0.6950154023659438 - offset,
        -2.6642421732719845 - offset,
        -0.4107292059512281 - offset,
        -2.5650150317912725 - offset,
        -0.03957624387021477 - offset,
        -1.459975933353292 - offset,
        -1.7826178769431 - offset,
        -0.0063910086450723325 - offset,
        -3.113867547530851 - offset,
        -2.8910961520154546 - offset,
        -2.3718952252880245 - offset,
        -1.3897222631802355 - offset,
        -2.1375714939983066 - offset,
        -0.9994610567775488 - offset,
        -0.7776520784930578 - offset,
        -0.353388277001343 - offset,
        -0.02895203726210091 - offset,
        -0.6726983784145278 - offset,
        -2.2946962578019665 - offset,
        -1.863557466465306 - offset,
        -0.26730788088522667 - offset,
        -2.498303344433606 - offset,
        -0.9859628310147427 - offset,
        -2.3015390566521345 - offset,
        -2.182161422047994 - offset,
        -0.6476638289513104 - offset,
        -1.9828161461009488 - offset,
        -2.759334618718058 - offset,
        -2.5751009200744224 - offset,
        -2.2754802700838868 - offset,
        -2.894718819023576 - offset,
        -2.3942266106035563 - offset,
        -2.3597155702364154 - offset,
        -0.8619147842448072 - offset,
        -1.5585362847484685 - offset,
        -2.2329166647636507 - offset,
        -0.2731017075516541 - offset,
        -0.4781390413985451 - offset,
        -1.7901443397126593 - offset,
        -1.1433045993548665 - offset,
        -2.0898117037306303 - offset,
        -1.0837510824272951 - offset,
        -2.6928615859081817 - offset,
        -2.649706340336663 - offset,
        -2.6375589115090947 - offset,
        -0.7346260030476295 - offset,
        -2.42417820501776 - offset,
        -0.7008726348089543 - offset,
        -0.3491363431388116 - offset,
        -2.6855954583467803 - offset,
        -0.9335914608244527 - offset,
        -1.1282308435392019 - offset,
        -1.5571341099841778 - offset,
        -2.0968912603614944 - offset,
        -0.730628023393316 - offset,
        -0.4951985004108488 - offset,
        -2.902350613309882 - offset,
        -1.7885697248681875 - offset,
        -1.4751061664049347 - offset,
        -1.5390777424462194 - offset,
        -2.8762322285242092 - offset,
        -0.4940392357287259 - offset,
        -0.012054114845436309 - offset,
        -3.032053951860437 - offset,
        -2.374125805765452 - offset,
        -2.4025184090990277 - offset,
        -1.0969861251226607 - offset,
        -2.7140378394308975 - offset,
        -1.753366456813175 - offset,
        -2.350980683560984 - offset,
        -0.4481758551592373 - offset,
        -0.4837435351770224 - offset,
        -2.6861383109374612 - offset,
        -2.2799772528992794 - offset,
        -2.0013629328184592 - offset,
        -2.9883132223545816 - offset,
        -2.1215585709864007 - offset,
        -2.421553486436626 - offset,
        -0.5889598185224101 - offset,
        -2.7964229143440953 - offset,
        -2.1055240403942315 - offset,
        -2.550214662670338 - offset,
        -2.60314101539995 - offset,
        -0.7509004504010787 - offset,
        -1.1097198256588752 - offset,
        -1.2853090821878264 - offset,
        -0.06881151445833164 - offset,
        -1.888037104217837 - offset,
        -2.655692934648788 - offset,
        -0.0712617816418619 - offset,
        -2.237386070712279 - offset,
        -2.624697844350373 - offset,
        -1.6932598229929476 - offset,
        -3.1292392711691432 - offset,
        -1.9302970612705348 - offset,
        -0.05552000023091433 - offset,
        -2.213859883403356 - offset,
        -2.2855940763118876 - offset,
        -1.5360545910906862 - offset,
        -1.8423162009755345 - offset,
        -1.2540315350699642 - offset,
        -2.4100284289768377 - offset,
        -1.2316448752106524 - offset,
        -1.009437911641195 - offset,
        -2.2341929394003626 - offset,
        -1.5936721603442507 - offset,
        -1.4301284921136954 - offset,
        -2.133956374401404 - offset,
        -2.5419546529030743 - offset,
        -2.4706384450766503 - offset,
        -1.4458442971552867 - offset,
        -0.675298309924629 - offset,
        -0.1307759125127804 - offset,
        -2.1724261559379694 - offset,
        -3.0301757418373185 - offset,
        -2.223984637645856 - offset,
        -0.8960548947689856 - offset,
        -1.6879441985156765 - offset,
        -1.5656539231364017 - offset,
        -1.1715302401075987 - offset,
        -2.1977928180739728 - offset,
        -2.3569595232747393 - offset,
        -1.812798093076864 - offset,
        -1.0133105775192217 - offset,
        -0.8510029404821573 - offset,
        -1.4057618612620275 - offset,
        -0.8426327453397771 - offset,
        -1.919390352513409 - offset,
        -2.7504997471435866 - offset,
        -1.463129347902804 - offset,
        -2.7820769325267394 - offset,
        -1.9904715999050417 - offset,
        -2.0374228816770796 - offset,
        -1.9573778533077693 - offset,
        -1.0107773780231675 - offset
    ]
    y = [
        0.6793610085529345,
        -0.7764598781122054,
        1.3030331041149927,
        1.696103804129755,
        1.8362701766489786,
        0.5295968005263707,
        3.5042711192603146,
        -0.7231575356785352,
        2.277743746352307,
        3.1121491784480697,
        1.4770243521157966,
        -1.0110529899688063,
        -0.21940659318914466,
        1.2783156815611991,
        -0.1791718798868415,
        3.884218615064042,
        1.9439974190429932,
        3.505002569928259,
        0.5755380178279407,
        -1.210873365508656,
        -1.0329923799436405,
        -1.0582442212859733,
        3.6142846309958205,
        1.5445673874139447,
        1.6469163448206863,
        0.2540079910444923,
        -1.258967648201369,
        2.794453234058449,
        -1.149826801806625,
        4.1149852157058895,
        -1.4081025494488113,
        3.5570091502314423,
        3.713458077324815,
        0.9623315035843127,
        2.792146626757914,
        -1.205590370248826,
        1.3344598403007284,
        3.057031649768471,
        2.578789613141873,
        -0.6543242980905074,
        -1.2100425673015185,
        2.9197086781500277,
        0.7696706532935776,
        1.6626933401609023,
        0.42253538652727796,
        1.4631522384301066,
        2.942466273998301,
        1.2364964850094777,
        3.152143289401243,
        3.6228480325523322,
        -0.6233110354243981,
        -1.3580082036894057,
        -1.305693088622172,
        -0.3935866480543121,
        3.111337871342845,
        2.410394433635401,
        -0.7759536147862817,
        1.3340538265678492,
        2.2303142906955555,
        0.3209555538663683,
        3.89346947511081,
        0.7649583168967733,
        -1.0802855176420891,
        -1.2568494543447684,
        2.4944104537407057,
        -0.679082202208783,
        3.693884882642762,
        -0.9569209611232933,
        -0.3002820219513763,
        -1.2603402702853281,
        -0.729087176112734,
        0.16046671198639534,
        2.8847324649501402,
        3.4142846215369556,
        2.9919434674688086,
        0.9143476976637405,
        -1.0038621010673856,
        3.7992457338282373,
        0.3803212691710048,
        2.577260760939388,
        1.9925005915231553,
        3.0431663584149904,
        1.7300408024972684,
        -0.46725570847050424,
        -0.25749919862715076,
        -1.493604284214328,
        4.396876304605113,
        1.5310130579985914,
        0.11093029172240809,
        -0.6139231414423276,
        0.9208951171502733,
        0.6712563554792417,
        2.618298719018602,
        3.6804690431500036,
        0.48814363461182453,
        1.7996187499638172,
        1.1625285801183705,
        0.7389373388724324,
        -1.2211299676858136,
        -0.8873468825484077,
        3.4776733678417986,
        3.575493958460944,
        2.3985492607241343,
        1.71557735708596,
        3.749934520345652,
        0.3575930800531485,
        2.1434683067151066,
        -0.9049053449496425,
        0.10465507554354464,
        3.1473437369575374,
        3.8373893523193847,
        -0.2809886987751162,
        -0.0809670563060226,
        -1.0586183593166278,
        2.9422791248401476,
        3.3776803834259663,
        3.153656143587366,
        3.5152991121388566,
        -1.281563505634356,
        1.7966322608299223,
        3.523561811455531,
        -0.7139026560764259,
        2.830553038963384,
        1.756811334089956,
        2.7361898523968753,
        -0.9036159267450711,
        -0.8009280139118677,
        -1.3972949916010728,
        2.4380037963785406,
        -0.05613139501335074,
        -0.9752089176334047,
        3.3757400103199693,
        3.2402795631690253,
        3.1005177839870184,
        -1.0528879963506719,
        0.11441934583356184,
        2.5168873649410255,
        2.960577394399894,
        -0.8705594922460475,
        3.573688045781485,
        -0.8907098511435746,
        3.294176954534472,
        -0.08783059329234524,
        2.292660484192841,
        3.4597453566827,
        0.253560604420727,
        -0.39806607018651047,
        2.5778821384858093,
        -0.7882243058017496,
        -0.9895456553950488
    ]

    return vcat(transpose.((x, y))...) / coord_down_scale
end

"""
    moon_class_2(0.0, 1.0)

Returns the hardcoded coordinates of the second moon from the author's demo website 
at https://mohammadpz.github.io/GradientStarvation.html
"""
function moon_class_2(offset::Float64 = 0.0, coord_down_scale::Float64 = 1.0)
    x = [
        1.2605697631874289 + offset,
        0.4428841761287988 + offset,
        2.213537711353039 + offset,
        2.2246476075616277 + offset,
        0.934302193080736 + offset,
        0.8703714425371154 + offset,
        2.6652808441973175 + offset,
        2.5868192990813768 + offset,
        2.5485659972780015 + offset,
        1.3501341878455395 + offset,
        1.3394525649634517 + offset,
        1.5703488118666078 + offset,
        2.578906600693658 + offset,
        2.6017725256967363 + offset,
        0.4855765554512216 + offset,
        1.620317196388419 + offset,
        0.6107465335988917 + offset,
        2.705677633402291 + offset,
        2.529619115397467 + offset,
        1.7205080921848972 + offset,
        2.025034051353637 + offset,
        0.9454991520471547 + offset,
        2.4474158496753415 + offset,
        0.44018725848007784 + offset,
        2.3578626209991933 + offset,
        2.305287296588136 + offset,
        2.1078203674554112 + offset,
        2.5672512309425377 + offset,
        0.76210430597206 + offset,
        0.9009064185658802 + offset,
        0.8790969921498528 + offset,
        2.834290242153208 + offset,
        1.827620864188383 + offset,
        0.9106326766024155 + offset,
        2.4986568505695774 + offset,
        1.329902276945841 + offset,
        0.30026706132425485 + offset,
        1.8709094482262436 + offset,
        2.6457300611721415 + offset,
        0.903254228522091 + offset,
        1.6008172396371303 + offset,
        3.2153091597614525 + offset,
        2.5679011437621266 + offset,
        2.359601929920219 + offset,
        2.0630126331781993 + offset,
        0.9482707644288992 + offset,
        1.318717891036563 + offset,
        2.685806352629474 + offset,
        1.8516766580167963 + offset,
        2.356710102702996 + offset,
        2.1684918727788336 + offset,
        1.5800357609867945 + offset,
        1.033126269584137 + offset,
        1.872794212999521 + offset,
        0.5235449122291833 + offset,
        0.7008785749342308 + offset,
        2.553663974985213 + offset,
        2.7411100225680163 + offset,
        2.0343480716575852 + offset,
        0.5340990535248212 + offset,
        2.4353923087262066 + offset,
        2.697340999301913 + offset,
        2.6521161619740408 + offset,
        0.8016750570795748 + offset,
        2.0888346508237094 + offset,
        0.8304001118980417 + offset,
        2.1076008673731175 + offset,
        0.3589801618753179 + offset,
        1.1229934118941256 + offset,
        1.3365490905708357 + offset,
        1.8354193619448524 + offset,
        2.718680142657365 + offset,
        1.114668177329429 + offset,
        2.4373081838238693 + offset,
        2.414593845611318 + offset,
        0.12290616957133377 + offset,
        2.432773932914067 + offset,
        2.703247300810249 + offset,
        0.9329542112336406 + offset,
        1.8387052373191828 + offset,
        2.192531994043116 + offset,
        0.9347932451321164 + offset,
        2.6506791700072787 + offset,
        1.4357888060935096 + offset,
        2.5074984951495582 + offset,
        1.452676080486036 + offset,
        2.1649169298468043 + offset,
        2.096317932113875 + offset,
        1.1626855473307327 + offset,
        0.0698015672586913 + offset,
        2.263884734272171 + offset,
        2.452097505628506 + offset,
        2.318232969547698 + offset,
        1.5708028678519623 + offset,
        1.7619872579964682 + offset,
        0.48741766950630805 + offset,
        2.2860590634348394 + offset,
        2.355561815069757 + offset,
        2.624438667886823 + offset,
        1.854267558549543 + offset,
        2.3213276658541218 + offset,
        2.745584480726928 + offset,
        0.11463689662493518 + offset,
        1.2268104662722987 + offset,
        0.4883558476641737 + offset,
        0.302830362550608 + offset,
        2.8418136908650427 + offset,
        2.4110065851996403 + offset,
        1.1883288319221876 + offset,
        0.4231560219611501 + offset,
        2.7332667742376247 + offset,
        2.4548799817800466 + offset,
        1.4492552216872536 + offset,
        0.29812737679036055 + offset,
        0.6024251082982855 + offset,
        2.4071077716684606 + offset,
        2.545623250801896 + offset,
        1.1447541103640393 + offset,
        1.6300111419299077 + offset,
        2.2144073814114598 + offset,
        1.741764282945776 + offset,
        2.584934801845699 + offset,
        2.94429370319911 + offset,
        0.04396728231852283 + offset,
        1.511277836871522 + offset,
        1.5078872546350166 + offset,
        2.2830235983573757 + offset,
        1.141833418913716 + offset,
        2.31153512617248 + offset,
        0.7930014449666454 + offset,
        1.7855431618709825 + offset,
        1.2496515034524522 + offset,
        2.494095987642121 + offset,
        0.99530344900322 + offset,
        1.6423078459022569 + offset,
        1.2698194368721236 + offset,
        2.3092312380669213 + offset,
        1.508197474828362 + offset,
        0.5282536325342755 + offset,
        2.8592120295683343 + offset,
        1.964949523096605 + offset,
        2.6235858300049006 + offset,
        1.2938945593806481 + offset,
        2.2949841542633416 + offset,
        2.347836965953938 + offset,
        2.3781640679457445 + offset,
        2.0047220333928424 + offset,
        0.5906909597410415 + offset,
        1.2986453274833423 + offset,
        2.667821411223028 + offset
    ]
    y = [
        1.0458976448210704,
        -3.9067277248882855,
        0.10622312924614075,
        -3.131178556347437,
        1.01212401276388,
        1.14213909231317,
        -1.499740679978164,
        -2.3757729401741026,
        -2.122671490779725,
        -3.502953002856569,
        -3.256081109078368,
        -3.1749520646753595,
        -2.155913453889749,
        -0.2395214626274446,
        0.9755334524010564,
        -3.471619676384854,
        0.9470748554316055,
        -1.8958980011427715,
        -1.750911067902624,
        0.6014389134684253,
        -0.328098369799075,
        -3.4065530755818263,
        -0.570775344749403,
        1.2583085822944136,
        0.37952520933453554,
        -1.3523455959069988,
        -2.9400776134322326,
        -0.931511238718386,
        0.9834249491123324,
        -3.5025716943059186,
        -4.248785250853195,
        -0.6773777546863811,
        -3.146614604919824,
        1.6069751824711314,
        0.12949305293031732,
        0.8261796714411879,
        -3.569524692879105,
        0.7005037664902201,
        -2.425440866187578,
        -3.738092107397064,
        -3.2452624729025747,
        -1.368470502749851,
        0.07815030521334698,
        -2.430664435412014,
        -0.3937883060575643,
        0.9090318588982524,
        -3.2871385464785274,
        -1.0695984302841914,
        0.24434407871756103,
        -2.25954235705039,
        -0.7439150005837414,
        -3.0397095698565275,
        0.9359563676278917,
        1.0115209086189823,
        -3.3783557249585123,
        0.9594224070734308,
        -0.10771629916989434,
        -1.7184897675482067,
        -2.708724275370595,
        1.6742944306376044,
        -2.2521686832796735,
        -0.3155915671715026,
        -1.3799617068714918,
        -3.7029324960425725,
        0.6295951027167603,
        1.3620703160533432,
        -2.6320189409595427,
        1.2235177121091534,
        -3.3223373231734046,
        0.7410339357717708,
        0.5026708223105636,
        -1.2659346176335473,
        1.1018873624037109,
        -1.7793888239691904,
        -0.6335066629431028,
        0.7436758886663175,
        -2.271922352203361,
        -1.5681088934930953,
        1.387487453946818,
        -0.18205302519419486,
        0.7509498665446229,
        1.1304461649366861,
        0.2598239003357525,
        -3.638173831524141,
        -0.3246237440748867,
        -3.846851795839017,
        0.12598502378608517,
        -2.974937206560519,
        -3.611991741390597,
        -3.6894705097537193,
        -2.792874862433873,
        -2.998549361725964,
        -2.520540198719894,
        0.6171082788895208,
        -3.1598996224476084,
        1.5195493259285597,
        -1.9538102221406346,
        -2.061630645113948,
        -0.45792310107331247,
        0.07907581142523268,
        -0.10696635485443987,
        -1.710269012859103,
        -3.60107422436533,
        1.1092227889389914,
        -3.7822078275343984,
        -4.21797263754794,
        -1.719272711473141,
        -2.58454577962155,
        -3.436277286035127,
        0.9974824865464593,
        -1.2960555247563033,
        -2.098906157582724,
        -3.2980549567958297,
        -4.140712584756083,
        -3.6668594006359907,
        -1.9331827888832867,
        -1.6997537944929542,
        1.2288964589068012,
        -3.280361193419007,
        -2.7915168449133825,
        0.716151381796484,
        -0.4617926598386114,
        -0.7751800733034873,
        1.5080467962694248,
        -3.601524555444186,
        0.4038862638181287,
        -2.6698628730744787,
        -3.534713771642897,
        -1.5036639589034162,
        0.9984399344555597,
        0.3775513743392528,
        -3.61494166755954,
        -0.6561789952747799,
        -3.9953414791058472,
        0.8817193140291141,
        1.2639173654508489,
        0.6932869760752849,
        -3.4031870404877793,
        -3.6982857231300157,
        -2.4260474342934755,
        -3.3108893959920254,
        -0.7863371260473055,
        0.7098721965355509,
        0.21815437229061818,
        -2.078371734274718,
        -1.1400343437416685,
        -1.2769894466119114,
        1.6438700737392897,
        -3.0090552847647456,
        0.2317409067300455
    ] 

    return vcat(transpose.((x, y))...) / coord_down_scale
end

end