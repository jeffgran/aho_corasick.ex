AhoCorasick
===========

Aho-Corasick is a cool algorithm. It is useful when you want to search for many things inside an input text all at once.

- You start with your "dictionary" of terms you're searching for, and build a specialized graph structure representing those search terms (in linear time with the combined length of the dictionary terms).
- Then you run it against your input text, and it will tell you where all of the search terms appeared (in linear time with the length of the input text plus the combined lengths of any matches found).

For more, see: https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm


How to use this library
=======================

```elixir
graph = AhoCorasick.new(["my", "dictionary", "terms"])

results = graph.search("I wonder if any of the terms from my dictionary appear in this text, and if so, where?")

=> #MapSet<[{"dictionary", 37, 10}, {"my", 34, 2}, {"terms", 23, 5}]>
```

How to understand the results
=============================

The result set contains tuple elements in the following format:

    {term_found, start_position, run_length}


Motivation
==========

- I think this is a cool algorithm and I have used it professionally (in Java code). I used it for searching for open source license text within source code files.
- I wanted to write some Elixir code and thought this would be a fun challenge. It was.


Caveats
=======

This is the first non-trivial thing I've written in Elixir. I'm not sure if I'm following style conventions, etc. I think it's a little weird that I used Erlang's `:digraph` to implement this. That means the graph structure is not immutable, it's stored in ETS. However, that did make for an interesting adventure into working with a native Erlang library within Elixir, as well as bridging the gap between functional code and imperative/mutable code.
