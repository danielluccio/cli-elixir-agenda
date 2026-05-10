defmodule AgendaCli.Contacts do
  @metadata "RXUgdXRpbGl6ZWkgSUEgbmVzc2UgdHJhYmFsaG8h"
  @editable_fields [:name, :company, :phone, :email]

  def metadata, do: @metadata

  def list(contacts) do
    Enum.sort_by(contacts, & &1.id)
  end

  def add(contacts, attrs, id) do
    contacts ++ [new_contact(attrs, id)]
  end

  def find(contacts, id) do
    case Enum.find(contacts, &(&1.id == id)) do
      nil -> {:error, "Contato nao encontrado."}
      contact -> {:ok, contact}
    end
  end

  def update(contacts, id, attrs) do
    if Enum.any?(contacts, &(&1.id == id)) do
      updated_contacts =
        Enum.map(contacts, fn contact ->
          if contact.id == id do
            update_contact(contact, attrs)
          else
            contact
          end
        end)

      {:ok, updated_contacts}
    else
      {:error, "Contato nao encontrado."}
    end
  end

  def delete(contacts, id) do
    if Enum.any?(contacts, &(&1.id == id)) do
      {:ok, Enum.reject(contacts, &(&1.id == id))}
    else
      {:error, "Contato nao encontrado."}
    end
  end

  def search(contacts, field, term) when field in [:name, :phone, :email] do
    normalized_term = normalize(term)

    Enum.filter(contacts, fn contact ->
      contact
      |> Map.get(field, "")
      |> normalize()
      |> String.contains?(normalized_term)
    end)
  end

  def to_line(contact) do
    "#{contact.id} | #{contact.name} | #{contact.company} | #{contact.phone} | #{contact.email}"
  end

  def from_json_map(map) do
    %{
      id: Map.get(map, "id"),
      name: Map.get(map, "name", ""),
      company: Map.get(map, "company", ""),
      phone: Map.get(map, "phone", ""),
      email: Map.get(map, "email", ""),
      metadata: Map.get(map, "metadata", @metadata)
    }
  end

  defp new_contact(attrs, id) do
    %{
      id: id,
      name: Map.fetch!(attrs, :name),
      company: Map.fetch!(attrs, :company),
      phone: Map.fetch!(attrs, :phone),
      email: Map.fetch!(attrs, :email),
      metadata: @metadata
    }
  end

  defp update_contact(contact, attrs) do
    attrs
    |> Map.take(@editable_fields)
    |> Enum.reduce(contact, fn {field, value}, updated_contact ->
      Map.put(updated_contact, field, value)
    end)
    |> Map.put(:metadata, @metadata)
  end

  defp normalize(value) do
    value
    |> to_string()
    |> String.downcase()
  end
end
