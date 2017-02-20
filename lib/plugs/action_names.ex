defmodule Plugs.ActionNames do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      names =
        "#{conn.private.phoenix_controller} #{conn.private.phoenix_action}"
        |> String.split(".")
        |> Enum.map(fn(x) -> String.replace(Macro.underscore(x), "_", "-") end)
        |> Enum.join(" ")

      assign(conn, :action_names, names)
    end
end
