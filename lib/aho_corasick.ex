defmodule AhoCorasick do
  @moduledoc """
  Usage:

  ```elixir
  graph = AhoCorasick.new(["my", "dictionary", "terms"])

  results = AhoCorasick.search(graph, "I wonder if any of the terms from my dictionary appear in this text, and if so, where?")

  => #MapSet<[{"dictionary", 37, 10}, {"my", 34, 2}, {"terms", 23, 5}]>
  ```
  """

  defstruct graph: nil

  @doc """
  Create a new AhoCorasick graph, but don't populate it. You will need to
  call `add_token` to add tokens, and then `build_trie` before searching
  against this AhoCorasick
  """
  def new() do
    g = :digraph.new()
    :digraph.add_vertex(g, :root)
    %AhoCorasick{graph: g}
  end

  @doc """
  Create a new fully-formed AhoCorasick graph. Pass in all the dictionary terms
  you want to search against. You can immediately call `search` with this graph
  after this.
  """
  def new(terms) do
    g = :digraph.new()
    :digraph.add_vertex(g, :root)
    ac = %AhoCorasick{graph: g}
    Enum.each terms, &add_term(ac, &1)
    build_trie(ac)
    ac
  end

  @doc """
  Searches for dictionary term matches in the given input text

  Returns a MapSet of {matched_term, start_index_in_input_text, run_length}
  """
  def search(ac, input) do
    input_tokens = tokenize(input)
    goto(ac, :root, 0, input_tokens, MapSet.new())
  end

  @doc """
  Add a dictionary term to the graph
  """
  def add_term(ac, term) do
    terminus = add_tokens(ac, tokenize(term))
    :digraph.add_vertex(ac.graph, terminus, [term])
    ac
  end

  @doc """
  if you want to manually/dynamically add terms to the tree, this method must be called
  before you can `search` the graph for matches.

  Usage:

  ```elixir
  g = AhoCorasick.new()
  AhoCorasick.add_term(g, "a term")

  # must be called before calling search!
  AhoCorasick.build_trie(g)

  # internal trie/graph is built. now you can search:
  AhoCorasick.search(g, input_text)
  ```
  """
  def build_trie(ac, queue \\ [:root])

  def build_trie(_ac, []) do
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
        f_n = compute_failure_for(ac, f_n, token)
        set_failure_for(ac, v2, f_n)
        f_n
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


  @doc """
  follows a list of tokens from the :root node and returns the :digraph vertex
  at the end, if found. Returns nil otherwise
  """
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


  @doc """
  returns the number of nodes in the graph. maybe useful for debugging?
  """
  def num_nodes(ac) do
    :digraph.no_vertices(ac.graph)
  end


  @doc """
  prints an ascii representation of the token tree (only shows token edges and
  result values, but not failure edges)
  """
  def print(ac) do
    print(ac, :root, 0)
  end

  def print(ac, node, level) do
    if level == 0 do IO.write("\n") end
    label_as_string = ac
    |> results(node)
    |> Enum.join(",")

    label_as_string = if label_as_string |> String.length > 0 do
      "{#{label_as_string}}"
    else
      ""
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



  # private


  # given a list of tokens, add them all to the graph in the proper place,
  # with links to each other in a tree.
  defp add_tokens(ac, [token | rest]) do
    add_tokens(ac, [token | rest], :root)
  end

  defp add_tokens(ac, tokenlist, node)

  defp add_tokens(ac, [token | rest], node) do
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

  defp add_tokens(_, [], node) do
    node
  end

  # add a token (a node) to the graph
  defp add_token(_, "", node) do node end

  defp add_token(ac, token, node, edge \\ nil) do
    v = :digraph.add_vertex(ac.graph)

    if edge == nil do
      :digraph.add_edge(ac.graph, node, v, {:token, token})
    end

    v
  end

  # just simply creates an edge from one node to another labeled :failure.
  # this is used during search phase to move between nodes of the graph
  # when we hit the "failure" case (i.e. no edge from current node matches
  # the next token)
  defp set_failure_for(ac, node, failure_node) do
    :digraph.add_edge(ac.graph, node, failure_node, :failure)
  end

  # during the graph-building stage, this is used to figure out where to
  # create the failure edge for the given node.
  defp compute_failure_for(ac, :root, token) do
    case token_edge_from_node(ac, :root, token) do
      nil ->
        :root
      e ->
        {_edge, _v1, v2, _token_label} = ac.graph |> :digraph.edge(e)
        v2
    end
  end

  defp compute_failure_for(ac, node, token) do
    case token_edge_from_node(ac, node, token) do
      nil ->
        next = failure_node_from_node(ac, node)
        compute_failure_for(ac, next, token)
      e ->
        {_edge, _v1, v2, _token_label} = ac.graph |> :digraph.edge(e)
        v2
    end
  end

  # the "failure" case of the automaton uses this function to look up
  # the pre-computed failure node that it should go to if no edge from
  # the current node matches the next token.
  defp failure_node_from_node(_ac, :root) do
    :root
  end

  defp failure_node_from_node(ac, node) do
    Enum.find_value :digraph.out_edges(ac.graph, node), fn(e) ->
      case :digraph.edge(ac.graph, e) do
        {_edge, _v1, v2, :failure} -> v2
        _not_a_failure_edge -> false
      end
    end
  end

  # given a node, return all :token-type edges coming from this node
  defp token_edges_from_node(ac, node) do
    ac.graph
    |> :digraph.out_edges(node)
    |> Enum.filter(fn(e) ->
      {_edge, _v1, _v2, label} = ac.graph |> :digraph.edge(e)
      case label do
        {:token, _token} -> true
        _not_a_token_edge -> false
      end
    end)
  end


  # given a node and a token, find the :token-type edge coming out of this node
  # that is labelled by the given token.
  defp token_edge_from_node(ac, node, sought_token) do
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

  # invoke the state machine/atomaton for the given node (node), keeping track of the
  # current offset within the input text (i, [target_token|rest]), and accumulating
  # the matches (results)
  defp goto(ac, node, i, [target_token|rest], results) do
    new_results =
      results(ac, node)
    |> Enum.map(fn(term) ->
      len = String.length(term)
      {term, i - len, len}
    end)

    results = MapSet.union(results, MapSet.new(new_results))

    edges = :digraph.out_edges(ac.graph, node)
    case Enum.find(edges, fn(e) -> edge_matches(ac, e, target_token) end) do
      nil ->
        if node == :root do
          goto(ac, :root, i + 1, rest, results)
        else
          goto(ac, failure_node_from_node(ac, node), i, [target_token|rest], results)
        end
      edge ->
        {_edge, _v1, v2, _label} = :digraph.edge(ac.graph, edge)
        goto(ac, v2, i + 1, rest, results)
    end
  end

  defp goto(_ac, _node, _i, [], results) do
    results
  end

  defp results(ac, node) do
    {_vertex, label} = :digraph.vertex(ac.graph, node)
    label
  end


  # Splits a dictionary entry into tokens.
  #
  # could be configurable in the future, but for now default is to tokenize per-
  # character. per-word or something could maybe save memory because less nodes,
  # but that means comparison on each node is now strcomp, partially thwarting
  # the value of aho-corasick itself.
  #
  # also, this should be configurable w.r.t. case-sensitivity. For case-insensitive
  # searches, we should downcase everything here.
  defp tokenize(term) do
    String.split(term, "")
  end

  # determine whether this edge is labelled by this token
  defp edge_matches(ac, edge, token) do
    case :digraph.edge(ac.graph, edge) do
      {_, _, _, {:token, label}} ->
        label == token
      _else ->
        false
    end
  end

end
