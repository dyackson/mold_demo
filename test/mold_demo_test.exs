defmodule MoldDemoTest do
  use ExUnit.Case
  doctest MoldDemo

  test "greets the world" do
    assert MoldDemo.hello() == :world
  end
end
