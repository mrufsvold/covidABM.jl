module stage_enum
export stages
const stages = Dict(
    "Susceptable" => 0,
    "Exposed" =>  1,
    "Asymptomatic" =>  2,
    "Symptomatic" =>  3,
    "Severe" =>  4,
    "Recovered" => 5,
    "Dead" =>  6
)
end