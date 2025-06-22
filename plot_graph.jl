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

function plot_graph(g)
    n = nv(g)
    fig, ax, p = graphplot(g, node_labels=fill("", n), node_color=:lightblue, node_size=60, node_strokewidth=2, node_strokecolor=:black)
    hidespines!(ax)
    hidedecorations!(ax)
    # Fallback for older GraphMakie: node positions are stored as p[:node_pos], which is an Observable
    positions = haskey(p, :node_pos) ? p[:node_pos][] : nothing
    if positions === nothing
        error("Could not find node positions in the plot object. Please update GraphMakie or check documentation.")
    end
    # Compute axis limits with padding
    xs = [pos[1] for pos in positions]
    ys = [pos[2] for pos in positions]
    xpad = 0.1 * (maximum(xs) - minimum(xs) + 1e-6)
    ypad = 0.1 * (maximum(ys) - minimum(ys) + 1e-6)
    xlims!(ax, minimum(xs) - xpad, maximum(xs) + xpad)
    ylims!(ax, minimum(ys) - ypad, maximum(ys) + ypad)
    for i in 1:n
        pos = positions[i]
        text!(ax, string(i), position=pos, align = (:center, :center), color=:black, fontsize=18)
    end
    display(fig)
    return fig
end

function interactive_plot_graph(g)
    n = nv(g)
    edges = collect(Graphs.edges(g))
    width, height = 800, 600
    cx, cy = width/2, height/2
    radius = min(width, height) * 0.4
    positions = Observable([Point2f0(cx + radius * cos(2π*i/n), cy + radius * sin(2π*i/n)) for i in 1:n])

    scene = Scene(size = (width, height), camera = campixel!)

    # Plot edges
    edgeplots = [lines!(scene, lift(pos -> [pos[src(e)], pos[dst(e)]], positions), color=:gray, linewidth=2) for e in edges]
    # Plot nodes as scatter
    nodeplot = scatter!(scene, lift(pos -> first.(pos), positions), lift(pos -> last.(pos), positions),
        color=:lightblue, strokewidth=2, strokecolor=:black, markersize=60)
    # Plot labels
    labelplots = [text!(scene, string(i), position=lift(pos -> pos[i], positions), align=(:center, :center), color=:black, fontsize=18) for i in 1:n]

    # Dragging state
    dragging = Observable(false)
    drag_idx = Observable(0)
    last_mousepos = Observable(Point2f0(0, 0))

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
                        break
                    end
                end
            elseif event.action == Mouse.release
                dragging[] = false
                drag_idx[] = 0
            end
        end
    end

    display(scene)
    return scene
end

function main()
    edges = read_edges("graph01.txt")
    g = build_graph(edges)
    fig = interactive_plot_graph(g)
    return nothing
end

main()
