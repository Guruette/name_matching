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
      |> Enum.reject(fn x -> String.length(x)==1 end)
  end

  # Jaro Distance between (0, 1)
  defp token_similarity(a, b) do
    max_len = max(String.length(a), String.length(b))
    if max_len == 0 do
      1.0
    else
      String.jaro_distance(a, b)
    end
  end

  # Soft Jaccard similarity using Jaro (accounts for symmetry)
  def jaccard_similarity(tokens1, tokens2) do
    matrix = for t1 <- tokens1 do
      for t2 <- tokens2 do
        token_similarity(t1, t2)
      end
    end

    # take best of row and best of col
    row_max = Enum.map(matrix, &Enum.max/1)
    col_max = matrix |> List.zip() |> Enum.map(&Tuple.to_list/1) |> Enum.map(&Enum.max/1)

    avg_max = (Enum.sum(row_max) + Enum.sum(col_max)) / (length(row_max) + length(col_max))
    avg_max
  end


  # Token Count Similarity (boost)
  def structure_score(input_tokens, candidate_tokens) do
    input_length = length(input_tokens)
    candidate_length = length(candidate_tokens)
    1 - abs(input_length - candidate_length) / max(input_length, candidate_length)
  end


  defp entropy_weighted_score(input_tokens, candidate_tokens, entropy_map) do
    input_set = MapSet.new(input_tokens)
    candidate_set = MapSet.new(candidate_tokens)

    intersection = MapSet.intersection(input_set, candidate_set)
    union = MapSet.union(input_set, candidate_set)

    sum_weights = fn set ->
      set
      |> Enum.map(fn token ->
        entropy = Map.get(entropy_map, token, 1.0)
        1.0 / (1.0 + entropy)
      end)
      |> Enum.sum()
    end

    intersection_sum = sum_weights.(intersection)
    union_sum = sum_weights.(union)

    if union_sum > 0, do: intersection_sum / union_sum, else: 0.0
  end

  defp dynamic_threshold(tokens) do
    case length(tokens) do
      2 -> 0.85
      3 -> 0.80
      4 -> 0.75
      5 -> 0.7
      _ -> 0.65
    end
  end


  def find_matches(input, candidates, entropy_map) do
    input_tokens = normalise_string(input)

    candidates
    |> Enum.map(fn candidate ->
      candidate_tokens = normalise_string(candidate)
      jaccard = jaccard_similarity(input_tokens, candidate_tokens)

      if jaccard >= 0.5 do
        entropy_score = entropy_weighted_score(input_tokens, candidate_tokens, entropy_map)
        structure_score = structure_score(input_tokens, candidate_tokens)
        weighted_score = 0.6 * entropy_score + 0.3 * jaccard + 0.1 * structure_score
        {candidate, weighted_score}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    # |> Enum.reject(fn {_name, score} -> score < dynamic_threshold(input_tokens) end) # remove this if you want them all
    |> Enum.sort_by(fn {_name, score} -> score end, :desc)

  end
end



names = [
  "Smith-Brown, Adam John",
  "Adam John Smith-Brown",
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
  "Xerxes Murphy",
]

# Calculate entropy map for all candidates
entropy_map = NameMatcher.calculate(names)

input = "Smith Brown Adam John Done"

# Find matches for an input name
res = NameMatcher.find_matches(input, names, entropy_map)

IO.inspect(res)
