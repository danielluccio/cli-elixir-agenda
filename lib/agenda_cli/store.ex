defmodule AgendaCli.Store do
  alias AgendaCli.Contacts

  @contacts_file "contacts.json"
  @parse_file "lib/parse.json"

  def load_contacts do
    case File.read(@contacts_file) do
      {:ok, content} -> decode_contacts(content)
      {:error, :enoent} -> []
      {:error, _reason} -> []
    end
  end

  def save_contacts(contacts) do
    contacts
    |> Jason.encode!(pretty: true)
    |> then(&File.write(@contacts_file, &1))
  end

  def save_parse_results(results) do
    results
    |> Jason.encode!(pretty: true)
    |> then(&File.write(@parse_file, &1))
  end

  defp decode_contacts(content) do
    case Jason.decode(content) do
      {:ok, contacts} when is_list(contacts) ->
        Enum.map(contacts, &Contacts.from_json_map/1)

      _invalid ->
        []
    end
  end
end
