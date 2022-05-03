module utils

function indexin(a::Any, t::Tuple)
    for (i,v) in enumerate(t)
        if v == a
            return i
        end
    end
    throw(KeyError("Value $a not in Tuple $t"))
end

end