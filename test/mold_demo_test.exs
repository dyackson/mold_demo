defmodule MoldDemoTest do
  use ExUnit.Case
  import Norm
  import Mold

  @user %{"name" => "joe", "age" => 25}
  @too_young %{"name" => "joe", "age" => 10}
  @no_name %{"age" => 25}
  @nil_name %{"name" => nil, "age" => 25}

  defp payload_schema do
    user_schema =
      schema(%{
        "name" => spec(is_binary() and (&(String.length(&1) > 0))),
        "age" => spec(is_nil() or (is_integer() and (&(&1 >= 18 and &1 < 130))))
      })
      |> selection(["name"])

    schema(%{
      "users" => coll_of(user_schema, kind: &is_list(&1))
    })
    |> selection(["users"])
  end

  def payload_mold do
    user_mold =
      rec(
        required: %{"name" => str(min: 1)},
        optional: %{"age" => int(gte: 18, lt: 130, nil_ok?: true)}
      )

    rec(
      required: %{
        "users" => lst(of: user_mold, min: 1)
      }
    )
    |> prep!()
  end

  test "valid payload" do
    payload = %{"users" => [@user]}

    assert {:ok, _} = conform(payload, payload_schema())

    assert :ok = exam(payload_mold(), payload)
  end

  test "invalid_payload" do
    payload = %{"users" => [@user, @too_young, @no_name, @nil_name]}

    assert {:error,
            [
              %{input: 10, path: ["users", 1, "age"], spec: "is_nil()"},
              %{input: 10, path: ["users", 1, "age"], spec: "&(&1 >= 18 and &1 < 130)"},
              %{input: %{"age" => 25}, path: ["users", 2, "name"], spec: ":required"},
              %{input: nil, path: ["users", 3, "name"], spec: "is_binary()"}
            ]} =
             conform(payload, payload_schema())

    assert {:error,
            %{
              "users" => %{
                1 => %{
                  "age" =>
                    "if not nil, must be an integer greater than or equal to 18 and less than 130"
                },
                2 => %{"name" => "is required"},
                3 => %{"name" => "must be a string with at least 1 characters"}
              }
            }} = exam(payload_mold(), payload)
  end
end
