module utils
using StatsBase

function indexin(a::Any, t::Tuple)
    for (i,v) in enumerate(t)
        if v == a
            return i
        end
    end
    throw(KeyError("Value $a not in Tuple $t"))
end


function boolsample(true_w::Float64, false_w::Float64)::Bool
    b = StatsBase.sample(
				[true, false], 
				StatsBase.weights([true_w, false_w])
				)
    return b
end
boolsample(true_w::Float64) = boolsample(true_w, 1- true_w)

end