defmodule Tempest.Processor.EquiJoin do
  use Tempest.Processor

  initial_state %{ left: %{}, right: %{} }

  option :join_fn, required: true
  option :output_fn,  required: false

  def process(context, message) do
    %{ join_fn: join_fn } = get_options(context)

    case join_fn.(message) do
      { :left,  value } -> group(context, :left,  value, message)
      { :right, value } -> group(context, :right, value, message)
    end
  end

  def done(context) do
    %{ left: left, right: right } = get_state(context)
    %{ output_fn: output_fn } = get_options(context)

    Enum.each left, fn { key, left_records } ->
      right_records = right[key]
      if right_records do
        Enum.each left_records, fn left_record ->
          Enum.each right_records, fn right_record ->
            if output_fn do
              emit context, output_fn.(left_record, right_record)
            else
              emit context, { left_record, right_record }
            end
          end
        end
      end
    end
  end

  defp group(context, side, key, record) do
    update_state context, fn state ->
      group = Map.update state[side], key, [record], &([record | &1])
      %{ state | side => group }
    end
  end

end
