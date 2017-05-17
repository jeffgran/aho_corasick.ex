defmodule AhoCorasickTest do
  use ExUnit.Case
  import Debug


  test "add a term" do
    ag = AhoCorasick.new(["foo"])
    #debug :digraph.vertices(ag.graph)
    #debug :digraph.edges(ag.graph)

    # root plus 3 letters of "foo"
    assert 4 == AhoCorasick.num_nodes(ag)
  end

  test "add three terms" do
    ag = AhoCorasick.new(["foo", "for", "fall"])

    #AhoCorasick.print(ag)

    assert 8 == AhoCorasick.num_nodes(ag)
  end

  test "find a node by list of tokens" do
    ag = AhoCorasick.new(["foo", "for"])

    foo = AhoCorasick.node_at_path(ag, ["f", "o", "o"])

    foolabel = elem(foo, 1)

    assert foolabel == ["foo"]
  end

  test "term with a strict suffix term should have both in the label of the terminating node" do
    ag = AhoCorasick.new(["he", "she", "his", "hers"])

    #AhoCorasick.print(ag)

    she_node = ag |> AhoCorasick.node_at_path(["s", "h", "e"])

    she_node_label = elem(she_node, 1)

    assert she_node_label == ["she", "he"]
  end

  test "wikipedia example" do
    ag = AhoCorasick.new(["a", "ab", "bab", "bc", "bca", "c", "ca", "caa"])

    #AhoCorasick.print(ag)

    bca_node = ag |> AhoCorasick.node_at_path(["b", "c", "a"])

    bca_node_label = elem(bca_node, 1)

    # this node has three temrs in its label because they are strict suffixes of one another
    assert bca_node_label == ["bca", "ca", "a"]
  end

  test "searching with input text should yeild proper results" do

    ag = AhoCorasick.new(["he", "she", "his", "hers", "us"])

    results = AhoCorasick.search(ag, "what he said")

    assert results == [
      {"he", 5, 6}
    ]

  end

  # test "searching with input text" do

  #   ag = AhoCorasick.new(["he", "she", "his", "hers", "us"])

  #   results = AhoCorasick.search(ag, "my ushers")

  #   assert results == [
  #     {"he", 5, 7}
  #   ]

  # end

end
