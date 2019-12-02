defmodule Ring do
  @moduledoc """
  Process ring implementation in Elixir

  Create a ring of `n` processes where the parent process knows the
  child process so that it can send messages to it.

  Every process should wait for a message and then forward it to its
  child process. The message should keep a counter that will
  incremented every time the message is sent so that we can check if
  the whole ring is completed.

  We should be able to make `m` rounds of messages in the ring and
  benchmark how much time does it take.

  Ideas:
  - Create a message to shutdown the ring
  - Create a ring where the root of the ring is not the current process
  - Shutdown the ring by killing the root of the ring
  - Implement the ring with OTP `GenServer`s and benchmark the difference
  - Implement the Ring behaviour by refactoring the `GenServer` implementation
  """

  @spec start(np :: pos_integer, nm :: pos_integer) :: any
  def start(np, nm) do
    create(np)
    |> run(nm, np)
  end

  @spec create(pos_integer) :: pid
  defp create(np), do: create(self(), np)

  @spec create(pid, pos_integer) :: pid
  defp create(next, 0) do
    next
  end

  defp create(next, np) do
    spawn(__MODULE__, :init, [next])
    |> create(np - 1)
  end

  @spec run(pid, pos_integer, pos_integer) :: any
  defp run(ring, 0, _) do
    send(ring, :shutdown)

    receive do
      :shutdown ->
        IO.inspect("Bye Bye")

      message ->
        IO.inspect("Received unknown message #{inspect(message)}")
        {:error, message}
    end
  end

  defp run(ring, nm, np) do
    send(ring, message = {:counter, 0})
    IO.inspect("Sent #{inspect(message)}")

    receive do
      {:counter, ^np} = message ->
        IO.inspect("Received #{inspect(message)}")
        run(ring, nm - 1, np)

      message ->
        IO.inspect("Received unknown message #{inspect(message)}")
        {:error, message}
    end
  end

  def init(next) do
    IO.inspect("Process #{inspect(self())} -> #{inspect(next)}")
    loop(next)
  end

  def loop(next) do
    receive do
      {:counter, n} ->
        send(next, {:counter, n + 1})
        loop(next)

      :shutdown = message ->
        IO.inspect("Bye #{inspect(self())}")
        send(next, message)
    end
  end
end
