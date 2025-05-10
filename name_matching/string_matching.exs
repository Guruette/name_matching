possible_match_list = [
  "Smith-Brown, Adam John",
  "Smith Brown, Adam John",
  "Smith, Alexandra",
  "Smith, John",
  "Smith, Mary",
  "Brown, Adam",
  "Ahmed, Adam",
  "Gordon, James",
]

input_strings = [
  "Adam John Smith Brown",
  "Adam Jon Smith-Brown",
  "Adam J Smith-Brown",
  "Adam J Brown",
  "Adam J Smith",
  "Smith Brown, Adam John",
  "Adam Jóhn Smith Brown",
  "Smith-Brown, Adam Jóhn",
  "Adam Smith-Brown",
  "Smith, Adam"
]

defmodule PhoneticRules do
  # Function that returns primary and secondary codes after applying the rules
  def double_metaphone(word) when is_binary(word) do
    word
    |> String.upcase()
    |> remove_non_alphabetic_chars()
    |> apply_pronunciation_rules()
    |> apply_replacement_rules()
    |> generate_alternative_codes()
  end

  # Remove all non-alphabetic characters from the word
  defp remove_non_alphabetic_chars(word) do
    word
    |> String.replace(~r/[^A-Z]/, "")
  end

  # Apply pronunciation rules
  defp apply_pronunciation_rules(word) do
    word
    |> String.replace(~r/(C|K)/, "K")   # Convert C and K to K
    |> String.replace("PH", "F")         # Convert PH to F
    |> handle_w_h()                 # Handle W and H rules
  end

  defp handle_w_h(word) do
    if String.length(word) > 1 do
      word
      |> String.replace(~r/([HW])(?!^)/, "")  # Remove W and H if not at the start
    else
      word
    end
  end

  # Apply replacement rules
  defp apply_replacement_rules(word) do
    word
    |> String.replace(~r/G(?=[EIY])/, "J")  # Replace G with J if followed by E, I, or Y
    |> String.replace(~r/C(?=[EIY])/, "S")  # Replace C with S if followed by E, I, or Y
    |> String.replace("X", "KS")            # Replace X with KS
    |> remove_endings()                    # Remove endings like S, ED, ING, etc.
    |> handle_starting_letters()           # Handle starting letter rules
  end

  # Remove certain suffixes
  defp remove_endings(word) do
    cond do
      String.ends_with?(word, "S") -> String.slice(word, 0..-2)  # Remove final S
      String.ends_with?(word, "ED") -> String.slice(word, 0..-3) # Remove ED
      String.ends_with?(word, "ING") -> String.slice(word, 0..-4) # Remove ING
      String.ends_with?(word, "ES") -> String.slice(word, 0..-3)  # Remove ES
      true -> word
    end
  end

  # Handle starting letters (KN, GN, etc.)
  defp handle_starting_letters(word) do
    cond do
      String.starts_with?(word, "KN") -> String.slice(word, 1..-1)   # Remove first K
      String.starts_with?(word, "GN") -> String.slice(word, 1..-1)   # Remove first G
      String.starts_with?(word, "PN") -> String.slice(word, 1..-1)   # Remove first P
      String.starts_with?(word, "AE") -> String.slice(word, 1..-1)   # Remove first A
      String.starts_with?(word, "WR") -> String.slice(word, 1..-1)   # Remove first W
      String.starts_with?(word, "WH") -> String.slice(word, 1..-1)   # Remove first H
      String.starts_with?(word, "X") -> String.slice(word, 0..1)     # Retain first 2 chars
      String.starts_with?(word, "Z") -> String.slice(word, 0..1)     # Retain first 2 chars
      true -> word
    end
  end


  defp generate_alternative_codes(word) do

    primary_code = word
    alternative_code = String.reverse(word) # For simplicity, reversing the word for now
    {primary_code, alternative_code}
  end
end


defmodule NameMatching do
  def normalise_string(input_string) do
    input_string
    |> String.normalize(:nfd)
    |> String.replace(~r/[\p{Mn}]/u, "")  # Remove diacritical marks
    |> String.replace(~r/[^a-zA-Z\s]/u, " ")  # Remove non-alphabetic characters
    |> String.replace(~r/\s+/u, " ")  # Replace multiple spaces with a single space
    |> String.downcase()
    |> String.trim()
  end
end

defmodule Jaccard do
  # Function to calculate Jaccard similarity between two strings, ignoring order
  def compare(str1, str2) do
    set1 = string_to_set(str1)
    set2 = string_to_set(str2)

    intersection = Enum.count(Enum.filter(set1, &Enum.member?(set2, &1)))
    union = Enum.count(set1) + Enum.count(set2) - intersection

    if union == 0, do: 0.0, else: intersection / union
  end

  # Convert a string to a set of unique words (this can be adjusted for other use cases)
  defp string_to_set(str) do
    str
    |> String.split()  # Split the string into words
    |> Enum.uniq()     # Ensure that each word appears only once
  end
end

# Normalize the input strings
normalised_inputs =
  input_strings
  |> Enum.map(&NameMatching.normalise_string/1)

IO.inspect(normalised_inputs, label: "final inputs")

split_strings_input =
  Enum.map(normalised_inputs, fn string ->
    String.split(string)
  end)
  |> Enum.map(fn words ->
    Enum.map(words, fn word ->

      PhoneticRules.double_metaphone(word)
    end)
  end)

IO.inspect(split_strings_input)

# Normalize the possible candidate strings
normalised_candidates =
  possible_match_list
  |> Enum.map(&NameMatching.normalise_string/1)

# TODO: remove the items that are phonetically not close then do the next steps

IO.inspect(normalised_candidates, label: "final candidates")


split_strings_candidates =
  Enum.map(normalised_candidates, fn string ->
    String.split(string)
  end)
  |> Enum.map(fn words ->
    Enum.map(words, fn word ->

      PhoneticRules.double_metaphone(word)
    end)
  end)

IO.inspect(split_strings_input)

## Calculate Jaccard similarities
#similarities =
#  normalised_inputs
#  |> Enum.map(fn input ->
#    Enum.map(normalised_candidates, fn candidate ->
#      similarity = Jaccard.compare(input, candidate)
#      {input, candidate, similarity}
#    end)
#  end)
#
#IO.inspect(similarities, label: "Jaccard Similarities")
