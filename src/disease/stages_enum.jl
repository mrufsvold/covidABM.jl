module stage_enum
export stages_map
const stages_map = Dict(
    "Susceptable" => 0,
    "Exposed" =>  1,
    "Asymptomatic" =>  2,
    "Symptomatic" =>  3,
    "Severe" =>  4,
    "Recovered" => 5,
    "Dead" =>  6
)
end