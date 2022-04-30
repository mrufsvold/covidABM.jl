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

    # Keep adding edges until there are no vertices with insufficient edges and the mean connections is correct
    insufficient_edges = filter(v -> length(neighbors(g,v)) < min_conns, vertices(g))
    while length(insufficient_edges) > 0 & (mean(neighbor_counts(g)) < mean_conns)
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
    end

end


end