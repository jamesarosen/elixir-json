defprotocol JSON.Encode do
  
  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """

  def to_json(item)

  def typeof(item)

end

defimpl JSON.Encode, for: Tuple do
  def to_json(item) do
      tuple_to_list(item)
        |>JSON.Encode.to_json
  end

  def typeof(_) do
    JSON.Encode.typeof([]) # same as for lists
  end
end

defimpl JSON.Encode, for: List do

  def to_json([]) do 
    "[]"
  end

  def to_json(list) do 
    if (Keyword.keyword? list) do
      "{#{_keyword_to_json(list, "")}}"
    else 
      "[#{_list_to_json(list, "")}]"
    end
  end
  

  defp _keyword_to_json([], accumulator) when is_bitstring(accumulator) do 
    accumulator
  end

  defp _keyword_to_json([head|tail], "") do 
    _keyword_to_json(tail, _keyword_item_to_json(head))
  end
  
  defp _keyword_to_json([head|tail], accumulator) when is_bitstring(accumulator) do 
    _keyword_to_json(tail, accumulator <> "," <> _keyword_item_to_json(head))
  end

  defp _keyword_item_to_json({key, object}) do 
    JSON.Encode.to_json(key) <> ":" <>  JSON.Encode.to_json(object)
  end

  defp _list_to_json([], accumulator) when is_bitstring(accumulator) do 
    accumulator
  end

  defp _list_to_json([head|tail], "") do 
    _list_to_json(tail, JSON.Encode.to_json(head))
  end

  defp _list_to_json([head|tail], accumulator) when is_bitstring(accumulator) do 
    _list_to_json(tail, accumulator <> "," <> JSON.Encode.to_json(head))
  end

  def typeof([]) do 
    :array
  end
 
  def typeof(list) do
    if (Keyword.keyword? list) do
      :object
    else
      :array
    end
  end
end

defimpl JSON.Encode, for: Number do

  def to_json(number), do: "#{number}" # Elixir convers octal, etc into decimal when putting in strings

  def typeof(_) do 
    :number
  end
end

defimpl JSON.Encode, for: Atom do
   def to_json(false) do
    "false"
  end

  def to_json(true) do
    "true"
  end
  
  def to_json(nil) do
    "null"
  end

  def to_json(atom) when is_atom(atom) do 
    atom_to_binary(atom)
      |>JSON.Encode.to_json
  end

  def typeof(boolean) when is_boolean(boolean) do
    :boolean
  end
  
  def typeof(nil) do 
    :null
  end

  def typeof(atom) when is_atom(atom) do
    :string
  end
end

defimpl JSON.Encode, for: BitString do
  def to_json(bitstring) do 
    "\"" <> _encode_binary_recursive(bitstring, "") <> "\""
  end

  defp _encode_binary_recursive(<< head :: utf8, tail :: binary >>, accumulator) do
    _encode_binary_recursive(tail, accumulator <> _encode_binary_character(head))
  end

  defp _encode_binary_recursive(<<>>, accumulator) do
    accumulator
  end

  defp  _encode_binary_character(?"),   do: "\\\""
  defp  _encode_binary_character(?\b),  do: "\\b"
  defp  _encode_binary_character(?\f),  do: "\\f"
  defp  _encode_binary_character(?\n),  do: "\\n"
  defp  _encode_binary_character(?\r),  do: "\\r"
  defp  _encode_binary_character(?\t),  do: "\\t"
  defp  _encode_binary_character(?/),   do: "\\/"
  defp  _encode_binary_character('\\'), do: "\\\\"
  
  #Anything else < ' ', ascii space = 32
  defp  _encode_binary_character(char) when is_number(char) and char < 32, do: "\u#{_encode_hexadecimal_unicode_control_character(char)}"

  #anything else besides these control characters
  defp  _encode_binary_character(char) when is_number(char), do: <<char>>


  defp _encode_hexadecimal_unicode_control_character(char) when is_number(char) do 
    integer_to_binary(char, 16)
      |> _zero_pad_string(4)
  end

  defp _zero_pad_string(string, desired_length) when is_bitstring(string) and is_number(desired_length) and desired_length > 0 do
    string_length = String.length(string)
    if (string_length >= desired_length) do 
      string
    else 
      _zero_pad_string_recursive(string, string_length - desired_length)
    end
  end

  defp _zero_pad_string_recursive(string, iterations_left) when is_bitstring(string and is_number(iterations_left) and iterations_left > 0 ) do
    _zero_pad_string_recursive("0" <> string, iterations_left - 1)
  end

  defp _zero_pad_string_recursive(string, 0) when is_bitstring(string) do
    string
  end

  def typeof(_) do
    :string
  end
end

defimpl JSON.Encode,  for: Record do
  def to_json(record) do 
    record.to_keywords
      |>JSON.Encode.to_json
  end

  def typeof(_) do 
    :object
  end
end

defimpl JSON.Encode, for: [Any] do

  @any_to_json "[Elixir.Any]"

  def to_json(_) do 
    JSON.Encode.to_json(@any_to_json)
  end

  def typeof(_) do
    JSON.Encode.typeof(@any_to_json)
  end
end
