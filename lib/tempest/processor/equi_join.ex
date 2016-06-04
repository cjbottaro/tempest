defmodule Tempest.Processor.EquiJoin do
  use Tempest.Processor

  initial_state %{ left_groups: %{}, right_groups: %{} }

  option :joining_fn, required: true
  option :output_fn,  required: false

  def process(context, message) do
    %{ joining_fn: joining_fn } = get_options(context)

    case joining_fn.(message) do
      { :left,  value } -> group(context, :left_groups,  value, message)
      { :right, value } -> group(context, :right_groups, value, message)
      nil -> raise ArgumentError, "cannot determine join key for #{inspect message}"
    end
  end

  def done(context) do
    %{ left_groups: left_groups, right_groups: right_groups } = get_state(context)
    Enum.each left_groups, fn { key, left_messages } ->
      right_messages = right_groups[key]
      if right_messages do
        Enum.each left_messages, fn left_message ->
          Enum.each right_messages, fn right_message ->
            IO.inspect {left_message, right_message}
            emit context, {left_message, right_message}
          end
        end
      end
    end
  end

  defp group(context, group_name, value, message) do
    update_state context, fn state ->
      group = Map.update state[group_name], value, [message], &([ message | &1])
      %{ state | group_name => group }
    end
  end

end
