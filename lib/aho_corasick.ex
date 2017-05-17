defmodule AhoCorasick do
  import Debug

  defstruct graph: nil

  def new(terms) do
    g = :digraph.new()
    :digraph.add_vertex(g, :root)
    ac = %AhoCorasick{graph: g}
    Enum.each terms, &add_term(ac, &1)
    build_trie(ac)
    ac
  end

  def add_term(ac, term) do
    terminus = add_tokens(ac, tokenize(term))
    :digraph.add_vertex(ac.graph, terminus, [term])
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
    v = :digraph.add_vertex(ac.graph, v)

    if edge == nil do
      :digraph.add_edge(ac.graph, node, v, {:token, token})
    end

    v
  end

  def node_at_path(ac, tokens, node \\ :root)

  def node_at_path(ac, [token|rest], node) do
    edge = token_edge_from_node(ac, node, token)
    if edge do
      {_e, _v1, v2, _label} = :digraph.edge(ac.graph, edge)
      node_at_path(ac, rest, v2)
    else
      nil
    end
  end

  def node_at_path(ac, [], node) do
    :digraph.vertex(ac.graph, node)
  end


  def build_trie(ac, queue \\ [:root])

  def build_trie(ac, []) do
    nil
  end

  def build_trie(ac, [node|tail]) do
    next_edges = token_edges_from_node(ac, node)
    next_nodes = Enum.map next_edges, fn(e) ->
      {_edge, _v1, v2, {:token, token}} = :digraph.edge(ac.graph, e)
      fail_node = if node == :root do
        set_failure_for(ac, v2, :root)
        :root
      else
        f_n = failure_node_from_node(ac, node)
        f_n2 = compute_failure_for(ac, f_n, token)
        set_failure_for(ac, v2, f_n2)
        f_n2
      end
      if v2 == fail_node do
        ac.graph |> :digraph.add_vertex(v2, results(ac, v2))
      else
        ac.graph |> :digraph.add_vertex(v2, results(ac, v2) ++ results(ac, fail_node))
      end
      v2
    end
    build_trie(ac, tail ++ next_nodes)
  end

  def set_failure_for(ac, node, failure_node) do
    :digraph.add_edge(ac.graph, node, failure_node, :failure)
  end

  def compute_failure_for(ac, :root, token) do
    :root
  end

  def compute_failure_for(ac, node, token) do
    case token_edge_from_node(ac, node, token) do
      nil ->
        next = failure_node_from_node(ac, node)
        compute_failure_for(ac, next, token)
      e ->
        {_edge, _v1, v2, _token_label} = ac.graph |> :digraph.edge(e)
        v2
    end
  end

  def failure_node_from_node(ac, :root) do
    :root
  end

  def failure_node_from_node(ac, node) do
    edge = Enum.find_value :digraph.out_edges(ac.graph, node), fn(e) ->
      case :digraph.edge(ac.graph, e) do
        {_edge, _v1, v2, :failure} -> v2
        _not_a_failure_edge -> false
      end
    end
  end

  @doc """
  given a node, return all :token-type edges coming from this node
  """
  def token_edges_from_node(ac, node) do
    ac.graph
    |> :digraph.out_edges(node)
    |> Enum.filter(fn(e) ->
      {_edge, _v1, _v2, label} = ac.graph |> :digraph.edge(e)
      case label do
        {:token, t} -> true
        _not_a_token_edge -> false
      end
    end)
  end

  @doc """
  given a node and a token, find the :token-type edge coming out of this node
  that is labelled by the given token.
  """
  def token_edge_from_node(ac, node, sought_token) do
    ac.graph
    |> :digraph.out_edges(node)
    |> Enum.find(fn(e) ->
      {_edge, _v1, _v2, label} = ac.graph |> :digraph.edge(e)
      case label do
        {:token, t} -> t == sought_token
        _not_a_token_edge -> false
      end
    end)
  end

  # defp goto(ac, node, [target_token|rest]) do
  #   #results = result(ac, node, results)

  #   edges = :digraph.out_edges(ac.graph, node)
  #   case Enum.find(edges, fn(e) -> edge_matches(ac, e, target_token) end) do
  #     nil ->
  #       if node == :root do
  #         goto(ac, :root, rest)
  #       else
  #         fail(ac, node, [target_token|rest])
  #       end
  #     edge ->
  #       {_edge, _v1, v2, _label} = :digraph.edge(ac.graph, edge)
  #       goto(ac, v2, rest)
  #   end
  # end

  # defp goto(ac, node, []) do
  #   results
  # end

  # defp result(ac, node, results) do
  #   # TODO. if the node has a result label, return (results + newresult)
  # end

  def search(ac, input) do
    input_tokens = tokenize(input)
    #results = goto(ac, :root, input_tokens, [])
    #results
  end

  def num_nodes(ac) do
    :digraph.no_vertices(ac.graph)
  end

  def print(ac) do
    :digraph.vertex(ac.graph, :root)
    print(ac, :root, 0)
  end

  def print(ac, node, level) do
    if level == 0 do IO.write("\n") end
    label_as_string = ac
    |> results(node)
    |> Enum.join(",")

    if label_as_string |> String.length > 0 do
      label_as_string = "{#{label_as_string}}"
    end

    IO.write("+ #{label_as_string}\n")

    Enum.each :digraph.out_edges(ac.graph, node), fn(e) ->
      case :digraph.edge(ac.graph, e) do
        {_e, _v1, v2, {:token, token}} ->
          IO.write("#{String.duplicate("  ", level)}|#{token}")
          print(ac, v2, level + 1)
        _other_kind_of_edge -> nil
      end
    end
  end

  def results(ac, node) do
    {_vertex, label} = :digraph.vertex(ac.graph, node)
    #debug label
    label
  end

  @doc """
  Splits a dictionary entry into tokens.

  could be configurable in the future, but for now default is to tokenize per-
  character. per-word or something could maybe save memory because less nodes,
  but that means comparison on each node is now strcomp, partially thwarting
  the value of aho-corasick itself.

  also, this should be configurable w.r.t. case-sensitivity. For case-insensitive
  searches, we should downcase everything here.
  """
  def tokenize(term) do
    String.split(term, "")
  end

  defp edge_matches(ac, edge, token) do
    {_, _, _, {:token, label}} = :digraph.edge(ac.graph, edge)
    label == token
  end

end
