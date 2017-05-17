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

    AhoCorasick.print(ag)

    assert 8 == AhoCorasick.num_nodes(ag)
  end

  test "add terms and find matches" do
    ag = AhoCorasick.new(["he", "she", "his", "hers"])

    AhoCorasick.print(ag)

    # TODO search against "ushers"

  end

end
