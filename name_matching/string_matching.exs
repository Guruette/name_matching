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

# Normalize the possible candidate strings
normalised_candidates =
  possible_match_list
  |> Enum.map(&NameMatching.normalise_string/1)

# TODO: remove the items that are phonetically not close then do the next steps

IO.inspect(normalised_candidates, label: "final candidates")

# Calculate Jaccard similarities
similarities =
  normalised_inputs
  |> Enum.map(fn input ->
    Enum.map(normalised_candidates, fn candidate ->
      similarity = Jaccard.compare(input, candidate)
      {input, candidate, similarity}
    end)
  end)

IO.inspect(similarities, label: "Jaccard Similarities")
