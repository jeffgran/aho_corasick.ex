defmodule AhoCorasickTest do
  use ExUnit.Case
  import Debug


  test "new" do
    %AhoCorasick{graph: g} =  AhoCorasick.new()
    t = elem(g, 0)
    assert t == :digraph
  end

  test "add a term" do
    ag = AhoCorasick.new()
    AhoCorasick.add_term(ag, "foo")
    #debug :digraph.vertices(ag.graph)
    #debug :digraph.edges(ag.graph)

    # root plus 3 letters of "foo"
    assert 4 == AhoCorasick.num_nodes(ag)
  end

  test "add tokens should return the final node" do
    ag = AhoCorasick.new()
    terminus = ag |> AhoCorasick.add_tokens(["a", "b", "c"])

    label = AhoCorasick.label(ag, terminus)

    assert label == "c"
  end


  test "add three terms" do
    ag = AhoCorasick.new()
    ag
    |> AhoCorasick.add_term("foo")
    |> AhoCorasick.add_term("for")
    |> AhoCorasick.add_term("fall")

    AhoCorasick.print(ag)

    assert 8 == AhoCorasick.num_nodes(ag)
  end




end
