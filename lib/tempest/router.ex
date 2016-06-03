defmodule Tempest.Router do

  def route(router, message) do
    # Is this gross? Am I too OO? Would I be shunned?
    router.__struct__.route(router, message)
  end

end
