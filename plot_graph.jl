#= 
This script reads a text file where each line is an edge ("x y") and displays the graph using GraphMakie.
=#
using Graphs
using GraphMakie
using GLMakie
using GeometryBasics
using LinearAlgebra: norm
const Point2f0 = GeometryBasics.Point2f
import Graphs: edges

function read_edges(filename)
    edge_list = []
    open(filename, "r") do f
        for line in eachline(f)
            s = split(strip(line))
            if length(s) == 2 && all(x -> occursin(r"^\d+$", x), s)
                push!(edge_list, (parse(Int, s[1]), parse(Int, s[2])))
            end
        end
    end
    return edge_list
end

function build_graph(edges)
    if isempty(edges)
        println("No edges found in input file. Displaying an empty graph.")
        return SimpleGraph(0)
    end
    nodes = unique(vcat([e[1] for e in edges], [e[2] for e in edges]))
    g = SimpleGraph(maximum(nodes))
    for (u, v) in edges
        add_edge!(g, u, v)
    end
    return g
end

function interactive_plot_graph(g, node_colors, node_text_colors)
    n = nv(g)
    edges = collect(Graphs.edges(g))
    width, height = 800, 600
    cx, cy = width/2, height/2
    radius = min(width, height) * 0.4
    positions = Observable([Point2f0(cx + radius * cos(2π*i/n), cy + radius * sin(2π*i/n)) for i in 1:n])

    scene = Scene(size = (width, height), camera = campixel!)

    # Plot edges
    [lines!(scene, lift(pos -> [pos[src(e)], pos[dst(e)]], positions), color=:gray, linewidth=2) for e in edges]
    # Plot nodes as scatter, use node_colors directly
    scatter!(scene, lift(pos -> first.(pos), positions), lift(pos -> last.(pos), positions),
        color=node_colors, strokewidth=2, strokecolor=:black, markersize=60)
    # Plot labels, use node_text_colors for each node
    [text!(scene, string(i), position=lift(pos -> pos[i], positions), align=(:center, :center), color=node_text_colors[i], fontsize=18) for i in 1:n]

    # Dragging state
    dragging = Observable(false)
    drag_idx = Observable(0)
    last_mousepos = Observable(Point2f0(0, 0))
    mouse_down_pos = Observable(Point2f0(0, 0))
    mouse_down_node = Observable(0)

    on(scene.events.mouseposition) do pos
        last_mousepos[] = Point2f0(pos[1], pos[2])
        if dragging[] && drag_idx[] > 0
            mousepos = last_mousepos[]
            newpos = copy(positions[])
            newpos[drag_idx[]] = mousepos
            positions[] = newpos
        end
    end

    on(scene.events.mousebutton) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                mousepos = last_mousepos[]
                # Find closest node within radius
                for i in 1:n
                    if norm(mousepos .- positions[][i]) < 30  # 30 pixels for easier selection
                        dragging[] = true
                        drag_idx[] = i
                        mouse_down_pos[] = mousepos
                        mouse_down_node[] = i
                        break
                    end
                end
            elseif event.action == Mouse.release
                # If released on the same node and not moved, treat as click
                if dragging[] && drag_idx[] > 0
                    moved = norm(last_mousepos[] .- mouse_down_pos[]) > 5  # 5 pixels threshold
                    if !moved && mouse_down_node[] == drag_idx[]
                        idx = drag_idx[]
                        # No color cycling logic needed when using node_colors directly
                    end
                end
                dragging[] = false
                drag_idx[] = 0
                mouse_down_node[] = 0
            end
        end
    end

    run(`clear`)
    println("You can view the graph now!")
    display(scene)
    return scene
end