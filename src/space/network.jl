module network
using Agents
using Graphs
using Statistics
using Random

function disconnect!(model)
    g = model.space.graph 
    for e in edges(g)
        rem_edge!(g,e)
    end 
end

neighbor_counts(g::AbstractGraph) = length.(neighbors.(Ref(g),vertices(g)))

function communitynetwork!(model, mean_conns::Int64, max_conns::Int64, min_conns::Int64)
    disconnect!(model)
    g = model.space.graph

    # start network with a random connection
    v1 = 0
    v2 = 0 
    while v1 == v2
        v1 = rand(vertices(g))
        v2 = rand(vertices(g))
    end
    add_edge!(model,v1,v2)

    # Do fast edge adding with shuffle until we almost reach mean connection number
    verts = vertices(g)
    average_conns = mean(neighbor_counts(g))
    while average_conns < mean_conns - 1
        for (v1,v2) in zip(verts, shuffle(verts))
            if v1 != v2 & length(neighbors(g,v1)) < max_conns & length(neighbors(g,v2)) < max_conns
                add_edge!(model, v1,v2)
            end
        end
        average_conns = mean(neighbor_counts(g))
    end

    # Go back through to connect any insufficiently connected nodes
    insufficient = verts[neighbor_counts(g) .< min_conns]
    while length(insufficient) > 0
        # Get nodes that aren't maxed out yet
        not_maxed =  verts[(neighbor_counts(g) .< max_conns) .& (neighbor_counts(g) .> 0)]
        # shuffle and zip up insufficient to not maxed
        for (v1,v2) in zip(insufficient, shuffle(not_maxed)[1:length(insufficient)])
            if v1 != v2 
                add_edge!(model, v1,v2)
            end
        end
        insufficient = verts[neighbor_counts(g) .< min_conns]
    end

    # Clean up any over connected nodes
    for v in verts[neighbor_counts(g) .> max_conns]  
        neigh_verts = [(nv, length(neighbors(g,v))) for nv in neighbors(g,v)]
        sort!(neigh_verts, by = x -> x[2])
        for (v2, n_counts) in neigh_verts
            rem_edge!(g,v,v2)
            if length(neighbors(g,v)) <= max_conns
                break
            end
        end
    end
    
end


### Keeping this for an example of what NOT to do -- 
function filter_communitynetwork!(model, mean_conns::Int64, max_conns::Int64, min_conns::Int64)
    disconnect!(model)
    g = model.space.graph

    # start network with a random connection
    v1 = 0
    v2 = 0 
    while v1 == v2
        v1 = rand(vertices(g))
        v2 = rand(vertices(g))
    end
    add_edge!(model,v1,v2)

    # Keep adding edges until there are no vertices with insufficient edges and the mean connections is correct
    insufficient_edges = filter(v -> length(neighbors(g,v)) < min_conns, vertices(g))

    i = 0
    while (length(insufficient_edges) > 0 | (mean(neighbor_counts(g)) < mean_conns)) & i < 10000
        # Find vertices that have fewer than the max number of connections and already connected to the network
        not_maxed_vertices = filter(v -> (length(neighbors(g,v)) < max_conns) & (length(neighbors(g,v)) >= 0), vertices(g))
        
        # The first vertice should be one of the insufficient ones, if there are any left
        # Otherwise, grab one that isn't maxed
        v1 = length(insufficient_edges) > 0 ? rand(insufficient_edges) : rand(not_maxed_vertices)
        # The second vertice should be already connected, but not maxed
        v2 = rand(not_maxed_vertices)

        add_edge!(model,v1,v2)
        
        # Update the vertices that still haven't reached minimum
        insufficient_edges = filter(v -> length(neighbors(g,v)) < min_conns, vertices(g))
        i += 1
    end

end


end