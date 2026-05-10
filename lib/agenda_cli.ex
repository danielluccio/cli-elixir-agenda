defmodule AgendaCli do
  use Application

  alias AgendaCli.Contacts
  alias AgendaCli.Store

  @impl true
  def start(_type, _args) do
    main()
    {:ok, self()}
  end

  def main do
    Store.load_contacts()
    |> loop()
  end

  defp loop(contacts) do
    case IO.gets("agenda> ") do
      value when value in [nil, :eof] ->
        :ok

      input ->
        input
        |> String.trim()
        |> split_command()
        |> handle_command(contacts)
        |> continue_loop()
    end
  end

  defp continue_loop(:stop), do: :ok
  defp continue_loop({:continue, contacts}), do: loop(contacts)

  defp split_command(""), do: []
  defp split_command(input), do: String.split(input)

  defp handle_command([], contacts) do
    {:continue, contacts}
  end

  defp handle_command(["exit"], _contacts) do
    :stop
  end

  defp handle_command(["test"], contacts) do
    IO.puts(Contacts.metadata())
    {:continue, contacts}
  end

  defp handle_command(["teste"], contacts) do
    IO.puts(Contacts.metadata())
    {:continue, contacts}
  end

  defp handle_command(["list"], contacts) do
    contacts
    |> Contacts.list()
    |> print_contact_list()

    {:continue, contacts}
  end

  defp handle_command(["show", id_text], contacts) do
    with {:ok, id} <- parse_id(id_text),
         {:ok, contact} <- Contacts.find(contacts, id) do
      print_contact(contact)
    else
      {:error, message} -> IO.puts(message)
    end

    {:continue, contacts}
  end

  defp handle_command(["del", id_text], contacts) do
    updated_contacts =
      with {:ok, id} <- parse_id(id_text),
           {:ok, updated_contacts} <- Contacts.delete(contacts, id),
           :ok <- Store.save_contacts(updated_contacts) do
        IO.puts("Contato removido.")
        updated_contacts
      else
        {:error, message} ->
          IO.puts(message)
          contacts
      end

    {:continue, updated_contacts}
  end

  defp handle_command(["add" | args], contacts) do
    updated_contacts =
      with {:ok, attrs} <- parse_flags(args, %{}),
           :ok <- require_fields(attrs, [:name, :company, :phone, :email]),
           updated_contacts <- Contacts.add(contacts, attrs, timestamp_id()),
           :ok <- Store.save_contacts(updated_contacts) do
        IO.puts("Contato adicionado.")
        updated_contacts
      else
        {:error, message} ->
          IO.puts(message)
          contacts
      end

    {:continue, updated_contacts}
  end

  defp handle_command(["edit", id_text | args], contacts) do
    updated_contacts =
      with {:ok, id} <- parse_id(id_text),
           {:ok, attrs} <- parse_flags(args, %{}),
           :ok <- require_any_field(attrs),
           {:ok, updated_contacts} <- Contacts.update(contacts, id, attrs),
           :ok <- Store.save_contacts(updated_contacts) do
        print_edit_result(attrs)
        updated_contacts
      else
        {:error, message} ->
          IO.puts(message)
          contacts
      end

    {:continue, updated_contacts}
  end

  defp handle_command(["search" | args], contacts) do
    case parse_search({args, contacts}) do
      {:ok, results} -> print_search_results(results)
      {:error, message} -> IO.puts(message)
    end

    {:continue, contacts}
  end

  defp handle_command(_tokens, contacts) do
    IO.puts("Comando invalido.")
    {:continue, contacts}
  end

  def parse_search({args, contacts}) do
    case parse_search_args(args) do
      {:ok, field, term} ->
        results =
          contacts
          |> Contacts.search(field, term)
          |> Enum.map(&Contacts.to_line/1)

        Store.save_parse_results(results)
        {:ok, results}

      {:error, message} ->
        Store.save_parse_results([])
        {:error, message}
    end
  end

  def parse_search(_invalid) do
    Store.save_parse_results([])
    {:error, "Search invalido."}
  end

  defp parse_search_args(["--name" | rest]), do: parse_single_search_flag(:name, rest)
  defp parse_search_args(["--phone" | rest]), do: parse_single_search_flag(:phone, rest)
  defp parse_search_args(["--email" | rest]), do: parse_single_search_flag(:email, rest)
  defp parse_search_args([]), do: {:error, "Informe uma flag para buscar."}
  defp parse_search_args(_args), do: {:error, "Search aceita apenas --name, --phone ou --email."}

  defp parse_single_search_flag(field, tokens) do
    case collect_value(tokens, []) do
      {"", _remaining} -> {:error, "Informe um valor para buscar."}
      {value, []} -> {:ok, field, value}
      {_value, _remaining} -> {:error, "Search aceita apenas uma flag por vez."}
    end
  end

  defp parse_flags([], attrs), do: {:ok, attrs}
  defp parse_flags(["--name" | rest], attrs), do: parse_flag(:name, rest, attrs)
  defp parse_flags(["--company" | rest], attrs), do: parse_flag(:company, rest, attrs)
  defp parse_flags(["--phone" | rest], attrs), do: parse_flag(:phone, rest, attrs)
  defp parse_flags(["--email" | rest], attrs), do: parse_flag(:email, rest, attrs)
  defp parse_flags([unknown | _rest], _attrs), do: {:error, "Flag invalida: #{unknown}"}

  defp parse_flag(field, tokens, attrs) do
    case collect_value(tokens, []) do
      {"", _remaining} ->
        {:error, "Valor ausente para #{field}."}

      {value, remaining} ->
        parse_flags(remaining, Map.put(attrs, field, value))
    end
  end

  defp collect_value([], acc), do: {join_value(acc), []}

  defp collect_value([<<"--", _rest::binary>> | _tail] = remaining, acc) do
    {join_value(acc), remaining}
  end

  defp collect_value([token | rest], acc) do
    collect_value(rest, [token | acc])
  end

  defp join_value(tokens) do
    tokens
    |> Enum.reverse()
    |> Enum.join(" ")
    |> String.trim()
  end

  defp parse_id(text) do
    case Integer.parse(text) do
      {id, ""} -> {:ok, id}
      _invalid -> {:error, "Id invalido."}
    end
  end

  defp require_fields(attrs, fields) do
    missing_fields = Enum.reject(fields, &Map.has_key?(attrs, &1))

    case missing_fields do
      [] -> :ok
      _missing -> {:error, "Informe name, company, phone e email."}
    end
  end

  defp require_any_field(attrs) when map_size(attrs) > 0, do: :ok
  defp require_any_field(_attrs), do: {:error, "Informe ao menos uma flag para editar."}

  defp print_edit_result(attrs) do
    if complete_edit?(attrs) do
      IO.puts(Contacts.metadata())
    else
      IO.puts("Contato atualizado.")
    end
  end

  defp complete_edit?(attrs) do
    Enum.all?([:name, :company, :phone, :email], &Map.has_key?(attrs, &1))
  end

  defp timestamp_id do
    System.system_time(:millisecond)
  end

  defp print_contact_list([]), do: IO.puts("Nenhum contato cadastrado.")

  defp print_contact_list(contacts) do
    Enum.each(contacts, &IO.puts(Contacts.to_line(&1)))
  end

  defp print_search_results([]), do: IO.puts("Nenhum contato encontrado.")

  defp print_search_results(results) do
    Enum.each(results, &IO.puts/1)
  end

  defp print_contact(contact) do
    IO.puts("""
    ID: #{contact.id}
    Nome: #{contact.name}
    Empresa: #{contact.company}
    Telefone: #{contact.phone}
    Email: #{contact.email}
    Metadata: #{contact.metadata}
    """)
  end
end
