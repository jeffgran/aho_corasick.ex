defmodule AhoCorasick do
  import Debug

  defstruct graph: nil

  def new do
    g = :digraph.new()
    :digraph.add_vertex(g, :root, :root)
    %AhoCorasick{graph: g}
  end

  def add_term(ac, term) do
    terminus = add_tokens(ac, tokenize(term))
    :digraph.add_vertex(ac.graph, terminus, term)
    ac
  end

  def add_tokens(ac, [token | rest]) do
    add_tokens(ac, [token | rest], :root)
  end

  def add_tokens(ac, tokenlist, node)

  def add_tokens(ac, [token | rest], node) do
    edges = :digraph.out_edges(ac.graph, node)

    case Enum.find(edges, fn(e) -> edge_matches(ac, e, token) end) do
      nil ->
        next_node = add_token(ac, token, node)
        last_node = add_tokens(ac, rest, next_node)
        last_node
      edge ->
        {_, _, v2, _} = :digraph.edge(ac.graph, edge)
        last_node = add_tokens(ac, rest, v2)
    end
  end

  def add_tokens(_, [], node) do
    node
  end

  def add_token(_, "", node) do node end

  def add_token(ac, token, node, edge \\ nil) do
    v = :digraph.add_vertex(ac.graph)
    v = :digraph.add_vertex(ac.graph, v, token)
    #debug "adding vertex for #{token}"
    #debug v

    if edge == nil do
      :digraph.add_edge(ac.graph, node, v, token)
    end

    v
  end

  def num_nodes(ac) do
    :digraph.no_vertices(ac.graph)
  end

  def print(ac) do
    :digraph.vertex(ac.graph, :root)
    print(ac, :root, 0)
  end

  def print(ac, node, level) do
    IO.write("+ #{label ac, node}\n")
    Enum.each :digraph.out_edges(ac.graph, node), fn(e) ->
      {_e, _v1, v2, l} = :digraph.edge(ac.graph, e)
      IO.write("#{String.duplicate("  ", level)}|#{l}")
      print(ac, v2, level + 1)
    end

  end

  def label(ac, node) do
    {_vertex, label} = :digraph.vertex(ac.graph, node)
    label
  end

  defp tokenize(term) do
    String.split(term, "")
  end

  defp edge_matches(ac, edge, token) do
    {_, _, _, l} = :digraph.edge(ac.graph, edge)
    l == token
  end

  # defp goto(node, _) do

  # end

end
