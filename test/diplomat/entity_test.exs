defmodule Diplomat.EntityTest do
  use ExUnit.Case
  alias Diplomat.{Entity, Property, Value, Key}

  test "some JSON w/o null values" do
    ent = ~s<{"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Diplomat.Entity.proto

    # ensure we can encode this crazy thing
    assert <<_::binary>> = Diplomat.Proto.Entity.encode(ent)
  end

  test "some JSON with null values" do
    ent = ~s<{"geo_lat":null,"geo_long":null,"id":1089,"log_type":"view","access_token":"778efaf8333b2ac840f097448154bb6b","ip_address":"127.0.0.1","created_at":"2016-01-28T23:03:27.000Z","updated_at":"2016-01-28T23:03:27.000Z","log_guid":"2016-1-0b68c093a68b4bb5b16b","user_guid":"58GQA26TZ567K3C65VVN","vbid":"12345","brand":"vst","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36"}>
            |> Poison.decode!
            |> Diplomat.Entity.proto

    # ensure we can encode this crazy thing
    assert <<_::binary>> = Diplomat.Proto.Entity.encode(ent)
  end

  test "converting to proto from Entity" do
    proto = %Entity{properties: %{"hello" => "world"}}
            |> Entity.proto

    assert ^proto = %Diplomat.Proto.Entity{
                      property: [%Diplomat.Proto.Property{
                        name: "hello", value: %Diplomat.Proto.Value{string_value: "world"}
                      }]
                    }
  end

  @entity %Diplomat.Proto.Entity{
    key: %Diplomat.Proto.Key{
      path_element: [%Diplomat.Proto.Key.PathElement{kind: "Random", id: 1234567890}]
    },
    property: [
      %Diplomat.Proto.Property{name: "hello",  value: %Diplomat.Proto.Value{string_value: "world"}},
      %Diplomat.Proto.Property{name: "math", value: %Diplomat.Proto.Value{entity_value:
                                                          %Diplomat.Proto.Entity{
                                                            property: [%Diplomat.Proto.Property{
                                                                name: "pi",
                                                                value: %Diplomat.Proto.Value{double_value: 3.1415}
                                                              }]
                                                          }
                                                        }
                               }
    ]
  }

  test "converting from a protobuf struct" do
    @entity
    |> Diplomat.Entity.from_proto

    assert %Entity{
      key: %Key{kind: "Random", id: 1234567890},
      properties: [
        %Property{name: "math", value: %Value{value: %Entity{}}},
        %Property{name: "hello", value: %Value{value: "world"}}
      ]
    } = Entity.from_proto(@entity)
  end


  test "generating an Entity from a flat map" do
    map = %{"access_token" => "778efaf8333b2ac840f097448154bb6b", "brand" => "vst",
            "geo_lat" => nil, "geo_long" => nil, "id" => 1089, "ip_address" => "127.0.0.1",
            "log_guid" => "2016-1-0b68c093a68b4bb5b16b", "log_type" => "view",
            "updated_at" => "2016-01-28T23:03:27.000Z",
            "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36",
            "user_guid" => "58GQA26TZ567K3C65VVN", "vbid" => "12345"}
    ent = Entity.new(map, "Log")
    assert map |> Dict.keys |> length ==
             ent.properties |> length
    assert ent.kind == "Log"
  end

  test "generating an Entity from a nested map" do
    ent = %{"person" => %{"firstName" => "Phil", "lastName" => "Burrows"}} |> Entity.new("Person")
    person_val = List.first(ent.properties).value

    assert ent.kind == "Person"
    assert ent.properties |> length == 1

    assert %Diplomat.Value{
      value: %Diplomat.Entity{
        properties: [
          %Diplomat.Property{name: "firstName", value: %Value{value: "Phil"}},
          %Diplomat.Property{name: "lastName",  value: %Value{value: "Burrows"}}
        ]
      }
    } = person_val
  end

  test "encoding an entity that has a nested entity" do
    ent = %{"person" => %{"firstName" => "Phil"}} |> Entity.new("Person")
    # IO.puts "proto: #{inspect Entity.proto(ent)}"
    assert <<_ :: binary>> = ent |> Entity.proto |> Diplomat.Proto.Entity.encode 
  end

  test "I can extract flat properties as a map from an entity" do
    map = %{"person" => "Phil Burrows"}
    ent = map |> Entity.new("Person")
    assert ^map = Entity.properties(ent)
  end

  test "I can extract nested properties from an entity" do
    map = %{"person" => %{"name" => "Phil Burrows"}}
    ent = map |> Entity.new("Person")
    assert ^map = Entity.properties(ent)
  end
end
