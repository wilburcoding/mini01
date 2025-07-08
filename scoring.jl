function get_score(g, node_info, node_color_indices)
    maxscore = 0
    score = 0
    for (vertex, value) in node_info
        for neighbor in value.neighbors
            c = 0
            for path in paths(g, vertex, neighbor)
                if (size(path)[1] <= 4)
                    c += 1
                end
            end
            maxscore+=c
            if (node_color_indices[vertex] == node_color_indices[neighbor])
                if (c >= 2)
                    score+=c
                else
                    score-=c
                end
            else
                if (c >= 2)
                    score -= c
                else
                    score += c
                end

            end
        end
    end
    return round(score/maxscore, sigdigits=3)

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
                if neighbor ∉ visited
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