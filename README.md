## Motivation

Using the [Norm library](https://hexdocs.pm/norm/Norm.html) for JSON payload validation has several downsides:
1. It validates all Elixir data types, not the subset that are produced from parsed json, e.g., via [Jason](https://hexdocs.pm/jason/Jason.html).
1. Confusing interface (subjective).
1. Requires writing functions or lambdas to check anything other than type.
1. Does not return messages suitable for http responses.

## Design goals

1. Error messages in plain english for bad JSON payloads.
1. A batteries-included library that has build-in support for most requirements.
1. Extensible.
1. Prevents the developer from making incorrect or nonsensical specs.

## Implementation Decisions

### Polymorphism mechanism

#### Option: Schemas represented by a map or single struct with a `type` field

    name_spec = %Spec{type: :str, min_len: 1, nil_ok?} 

    age_spec = %Spec{type: :int, gte: 18, lt: 130, nil_ok?: true}

    user_spec = %Spec{type: :rec, required: %{"name" => name_spec}, optional: %{"age" => age_spec}}

    payload_spec = %Spec{type: :rec, required: %{"users" => %Spec{type: :lst, of: user_spec}}}

Cons: 
1. If a map, there is no compile-time key checking.
1. If a struct, still too many keys.
1. May be harder to organize code.
1. No way to let a user (dev) define a new type.


#### Option: Each type represented by a separate struct which implements a common Behaviour

[Mold with Behaviour](https://github.com/dyackson/mold/commit/567ce900bb11f60d4c596d495d3e394ea9e21aea#diff-5e6562bf07d79618f747b1b369b9bbd8f9eafcbb747109b7ba50d5be0b756c9c)

Pros:
1. Compile-time checking and each struct only includes keys it needs.
1. Checks at compile time that callbacks are implemented via `@impl`
1. A user (dev) can create a new spec/mold in a callback module.
1. Common checks don't have to be implemented in each callback module.
1. Can enforce common (`nullable`/`nil_ok?`, `and_fn`/`but`)fields exists via `use` macro.

Cons:
1. Users (devs) have to create specs/molds that work with common callback modules.
1. If enforcing common fields via `use` macro may be unnecessary for custom specs/molds.
1. Implementation is more complicated if using `use` macro.

#### Option: Each type represented by a separate struct that implements a common protocol.

Pros:
1. Compile-time checking and each struct only includes keys it needs.
1. A user (dev) can create a new spec that implements the protocol.
1. Simpler than Behaviour + `use` macro

Cons:
1. More boilerplate in each struct module.
1. Cannot enforce common fields.
1. Protocol implementation is checked at runtime, not compile time.
1. `exam` function isn't chainable because mold/spec must be the first argument to implementation function.

1. Can enforce common fields exists via `use` macro.
 - Polymorphism: `type` field vs Behavior vs Protocol (not chainable)
 - Structs - for some compile-time checking
 - Macros
 - Validate the mold (spec) to prevent nonsense

### Mold validation via `Mold.check/1`

Ensures that the mold/spec is coherent. E.g.,
1. Can't have nonsensical bounds (example)[https://github.com/dyackson/mold/blob/main/test/mold/dec_test.exs#L32]
1. Strings can use `regex`, `regex`, `one_of`, `one_of_ci`, *XOR* length fields. (example)[https://github.com/dyackson/mold/blob/main/test/mold/str_test.exs#L56]
1. A `Rec` field can't be both optional and required. (example)[https://github.com/dyackson/mold/blob/main/test/mold/rec_test.exs#L66]
Pros:
This helps users (devs) find usage mistakes more quickly.
There is less need for tests that ensure you've used the library correctly.
(Molds using `but` field should be tested.)

Cons:
An extra function call.

### Extensibility Mechanisms

1. `error_message` field (example)[https://github.com/dyackson/mold/blob/main/test/mold/rec_test.exs#L214]
1. `regex` field on `Str` (example)[https://github.com/dyackson/mold/blob/main/test/mold/str_test.exs#L167]
1. `but` field (example)[https://github.com/dyackson/mold/blob/main/test/mold/lst_test.exs#L134]
1. `Any` mold (example)[https://github.com/dyackson/mold/blob/main/test/mold/any_test.exs#L51]
1. `Mold.Protocol`(definition)[https://github.com/dyackson/mold/blob/main/lib/mold/protocol.ex]

### Miscellaneous highlights

1. Error tuple structure (example)[https://github.com/dyackson/mold/blob/main/test/mold/mold_test.exs#L206]
1. `Dic` mold (example)[https://github.com/dyackson/mold/blob/main/test/mold/dic_test.exs#L162]
1. (Macros)[https://github.com/dyackson/mold/blob/main/lib/mold.ex#L5] for creating molds.
1. Interface is a wrapper around the protocol.

### Potential changes / new features
1. Normalized error maps.

    %{
      "lucky_numbers" => %{
        0 => "must be an integer",
        2 => "must be an integer"
      },
      "favorite_songs_by_genre" => %{
        "bluegrass" => %{"title" => "must be a string"},
        "jazz" => %{"title" => "must be a string"},
        "calypso" => %{"title" => "must be a string"}
      }
    }


    %{
      "__map__" =>  %{
        "lucky_numbers" => %{0 => 0, 2 => 0},
        "favorite_songs_by_genre" => %{
          "bluegrass" => %{"title" => 1},
          "jazz" => %{"title" => 1},
          "calypso" => %{"title" => 1}
        }
      },
      "__messages__" => %{
        0 => "must be an integer",
        1 => "must be a string"
      }
    }

1. Use generate forms
1. Use to generate (OpenAPI)[https://www.openapis.org/] specs. A library that does this: (open-api-spex)[https://github.com/open-api-spex/open_api_spex]
