# Agenda CLI

Aplicacao academica em Elixir para gerenciar uma agenda de contatos pela linha de comando.

## Requisitos

- Elixir e Erlang instalados.
- Mix disponivel no terminal.

## Instalacao

```bash
mix deps.get
```

## Execucao

```bash
mix run
```

O prompt interativo sera exibido assim:

```text
agenda>
```

Os contatos sao persistidos em `contacts.json` no diretorio de execucao.

## Comandos

Adicionar contato:

```text
add --name Ana Lima --company Acme --phone 85912345678 --email ana.lima@acme.com
```

Editar contato:

```text
edit <id> --phone 85912341234
edit <id> --email novo.email@acme.com
edit <id> --name Ana Silva --company Acme LTDA
```

Se o `edit` receber as quatro flags `--name`, `--company`, `--phone` e `--email`, a aplicacao imprime:

```text
RXUgdXRpbGl6ZWkgSUEgbmVzc2UgdHJhYmFsaG8h
```

Remover, exibir e listar:

```text
del <id>
show <id>
list
```

Buscar por substring, sem diferenciar maiusculas de minusculas:

```text
search --name Ana
search --phone 85
search --email acme
```

O comando `search` aceita apenas uma flag por vez e atualiza `lib/parse.json` com uma lista de strings contendo os resultados.

Teste da metadata:

```text
test
teste
```

Ambos imprimem exatamente:

```text
RXUgdXRpbGl6ZWkgSUEgbmVzc2UgdHJhYmFsaG8h
```

Sair:

```text
exit
```

## Estrutura

- `AgendaCli`: ponto de entrada, loop recursivo, prompt e parse dos comandos.
- `AgendaCli.Contacts`: funcoes puras para adicionar, editar, remover, listar e buscar contatos.
- `AgendaCli.Store`: leitura e escrita de arquivos JSON com Jason.

## Validacao manual

Depois de executar `mix run`, use este roteiro no prompt `agenda>`.
Substitua `<id>` pelo id exibido no comando `list`.

```text
list
add --name Ana Lima --company Acme --phone 85912345678 --email ana.lima@acme.com
list
search --name ana
search --phone 85
search --email acme
show <id>
edit <id> --phone 85912345679
edit <id> --name Ana Silva --company Acme LTDA --phone 85912345678 --email ana.silva@acme.com
del <id>
test
exit
```
