module progression
export disease_schedule

struct disease_schedule
    # When is the duration of the previous disease stage in hours.
	When::Float64
	# Stage is the next disease stage.
	Stage::Int64

end

end