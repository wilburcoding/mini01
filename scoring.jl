function get_score(g, weights, node_info, node_color_indices)
    total_weight = 0 
    for (u, v) in weights
        total_weight += v/2
    end
    println(total_weight)
    total = 0
    for (u, v) in weights
        edge_weight = v
        k_i = 0
        for neighbor in node_info[u[1]].neighbors
            k_i += weights[(u[1], neighbor)]
        end
        k_j = 0
        for neighbor in node_info[u[2]].neighbors
            k_j += weights[(u[2], neighbor)]
        end
        same_community = node_color_indices[u[1]] == node_color_indices[u[2]] ? 1 : 0
        total += (edge_weight - ((k_i * k_j) / (2 * total_weight))) * (same_community)
    end




    # maxscore = 0
    # score = 0
    # for (vertex, value) in node_info
    #     for neighbor in value.neighbors
    #         c = size(paths(g, vertex, neighbor))[1] 
    #         maxscore+=c
    #         if (node_color_indices[vertex] == node_color_indices[neighbor])
    #             if (c >= 2)
    #                 score+=c
    #             else
    #                 score-=c
    #             end
    #         else
    #             if (c >= 2)
    #                 score -= c
    #             else
    #                 score += c
    #             end

    #         end
    #     end
    # end
    # return round(score/maxscore, sigdigits=3)
    return round(total / (2 * total_weight), sigdigits=3)


end
function paths(g, start_node::Int, end_node::Int)
    paths = []
    visited = Set{Int}()

    function dfs(current_node, path)
        push!(path, current_node)
        push!(visited, current_node)

        if current_node == end_node
            push!(paths, copy(path)) 
        else
            for neighbor in neighbors(g, current_node)
                if neighbor ∉ visited && size(path)[1] < 5 # Ignore paths over a certain lenght
                    dfs(neighbor, path)
                end
            end
        end

        pop!(path) 
        delete!(visited, current_node)  
    end

    dfs(start_node, [])
    return paths
end