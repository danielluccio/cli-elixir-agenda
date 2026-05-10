defmodule AgendaCliTest do
  use ExUnit.Case

  alias AgendaCli.Contacts

  @attrs %{
    name: "Ana Lima",
    company: "Acme",
    phone: "85912345678",
    email: "ana.lima@acme.com"
  }

  test "adds contacts with fixed metadata" do
    [contact] = Contacts.add([], @attrs, 1)

    assert contact.id == 1
    assert contact.name == "Ana Lima"
    assert contact.metadata == Contacts.metadata()
  end

  test "updates only editable contact fields" do
    contacts = Contacts.add([], @attrs, 1)

    assert {:ok, [updated]} = Contacts.update(contacts, 1, %{phone: "85912341234"})
    assert updated.phone == "85912341234"
    assert updated.name == "Ana Lima"
    assert updated.metadata == Contacts.metadata()
  end

  test "search is case insensitive and uses substring" do
    contacts = Contacts.add([], @attrs, 1)

    assert [%{id: 1}] = Contacts.search(contacts, :name, "ana")
    assert [%{id: 1}] = Contacts.search(contacts, :email, "ACME")
    assert [%{id: 1}] = Contacts.search(contacts, :phone, "85")
  end

  test "parse_search writes string results to lib/parse.json" do
    contacts = Contacts.add([], @attrs, 1)

    assert {:ok, ["1 | Ana Lima | Acme | 85912345678 | ana.lima@acme.com"]} =
             AgendaCli.parse_search({["--name", "Ana"], contacts})

    assert {:ok, ["1 | Ana Lima | Acme | 85912345678 | ana.lima@acme.com"]} =
             "lib/parse.json"
             |> File.read!()
             |> Jason.decode()
  after
    File.rm("lib/parse.json")
  end
end
