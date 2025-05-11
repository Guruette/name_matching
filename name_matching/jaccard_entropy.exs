defmodule NameMatcher do
  @moduledoc """
  Name matching system with Jaccard similarity and entropy-based ranking
  """

    def calculate(names) do
      tokens =
        names
        |> Enum.map(fn name -> normalise_string(name) end)
        |> List.flatten()

      total = length(tokens)

      tokens
      |> Enum.frequencies()
      |> Enum.map(fn {token, count} ->
        prob = count / total
        entropy = -prob * :math.log2(prob)
        {token, entropy}
      end)
      |> Map.new()
    end

    def normalise_string(input_string) do
      input_string
      |> String.normalize(:nfd)
      |> String.replace(~r/[\p{Mn}]/u, "")  # Remove diacritical marks
      |> String.replace(~r/[^a-zA-Z\s]/u, " ")  # Remove non-alphabetic characters
      |> String.replace(~r/\s+/u, " ")  # Replace multiple spaces with a single space
      |> String.downcase()
      |> String.trim()
      |> String.split()
  end

  def jaccard_similarity(tokens1, tokens2) do
    set1 = MapSet.new(tokens1)
    set2 = MapSet.new(tokens2)

    intersection = MapSet.intersection(set1, set2) |> MapSet.size()
    union = MapSet.union(set1, set2) |> MapSet.size()

    if union == 0, do: 0.0, else: intersection / union
  end


  defp entropy_weighted_score(input_tokens, candidate_tokens, entropy_map) do
    input_set = MapSet.new(input_tokens)
    candidate_set = MapSet.new(candidate_tokens)

    intersection = MapSet.intersection(input_set, candidate_set)
    union = MapSet.union(input_set, candidate_set)

    sum_weights = fn set ->
      set
      |> Enum.map(fn token -> 1 - Map.get(entropy_map, token, 1.0) end)
      |> Enum.sum()
    end

    intersection_sum = sum_weights.(intersection)
    union_sum = sum_weights.(union)

    if union_sum > 0, do: intersection_sum / union_sum, else: 0.0
  end



  def find_matches(input, candidates, entropy_map) do
    input_tokens = normalise_string(input)

    candidates
    |> Enum.map(fn candidate ->
      candidate_tokens = normalise_string(candidate)
      jaccard = jaccard_similarity(input_tokens, candidate_tokens)

      if jaccard >= 0.5 do
        weighted_score = entropy_weighted_score(input_tokens, candidate_tokens, entropy_map)
        {candidate, weighted_score}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {_name, score} -> score end, :desc)
  end
end



names = [
  "Smith-Brown, Adam John",
  "Smith Brown, Adam John",
  "Smith Brown, Aadam John",
  "Smith Bròwn, Adam John",
  "Smith Bròwn, Adam Jon",
  "Smith, Alexandra",
  "Smith, John",
  "Smith, Mary",
  "Brown, Adam",
  "Ahmed, Adam",
  "Gordon, James",
  "Jessica, Brown",
  "John Adam Brown",
  "John Adam Murphy",
  "Smith Murphy",
  "Adam John Smith",
  "Xerxes Smith",
  "Adam Jon Jones",
]

# 2. Calculate entropy map
entropy_map =
  NameMatcher.calculate(names)

# 3. Find matches for an input name
input = "Smith Brown Adam John Done"

res =
    NameMatcher.find_matches(input, names, entropy_map)


IO.inspect(res)