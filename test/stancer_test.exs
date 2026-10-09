defmodule StancerTest do
  use ExUnit.Case
  doctest Stancer

  test "greets the world" do
    assert Stancer.hello() == :world
  end
end
