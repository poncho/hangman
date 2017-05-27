defmodule Hangman.Game do

  import IEx.Helpers, only: [clear: 0]

  @max_errors 6

  def start do
    word = select_word()
    word
    |> format_word
    |> game_loop([], %{wrong: 0})
  end

  @spec select_word :: String.t
  def select_word do
    File.read!("movies.txt")
    |> String.split("\n")
    |> Enum.filter(fn word -> word != "" end)
    |> get_random_word
  end

  @spec get_random_word(list) :: String.t
  def get_random_word(word_list) do
    :random.seed(:erlang.now)
    Enum.random(word_list)
  end

  def format_word(word) do
    word
    |> String.codepoints
    |> Enum.map(&String.capitalize(&1))
  end

  @spec game_loop(list, list, map) :: none
  def game_loop(word, correct, _) when length(word) == length(correct) do
    clear()
    print_win()
    start() # Starts again
  end
  def game_loop(word, correct, data) do
    clear()
    IO.inspect([length(Enum.uniq(word)), length(word), length(correct)])
    print_word(word, correct)

    letter = choose_letter()
    case letter do
      "" ->
        game_loop(word, correct, data)
      _  ->
        case validate_letter(letter, word) do
          [] ->
            data = Map.put(data, :wrong, data.wrong + 1)
            IO.gets " The letter '#{letter}' doesn't appear in this word.\nFAILS: #{data.wrong} "

            data.wrong < @max_errors
            && game_loop(word, correct, data)
            || (print_lose(word) && start())
          correct_guess ->
            correct = Enum.uniq(correct ++ correct_guess)

            total_letters =
              word
              |> Enum.uniq
              |> Enum.filter(fn letter -> letter != " " end)
              |> length

            total_letters != length(correct)
            && game_loop(word, correct, data)
            || (print_win() && start())
            game_loop(word, correct, data)
        end
    end
  end

  def print_word(word, correct) do
    Enum.reduce(word, 0,
      fn (letter, index) ->
        case Enum.find(correct, fn x -> x == index end) || letter == " " do
          false ->
            IO.write "__ "
          _ ->
            IO.write "#{letter} "
        end

        index + 1
      end
    )
    IO.puts "\n"
  end

  def choose_letter do
    letter = IO.gets "LETTER: "
    case Regex.match?(~r/[a-zA-Z]{1}/, letter) do
      true ->
        String.replace(letter, "\n", "")
      false ->
        IO.gets "Press ENTER to choose a letter: "
        ""
    end
  end

  def validate_letter(guess, word) do
    word
    |> Enum.with_index
    |> Enum.filter(fn {letter, _index} -> letter == String.capitalize(guess) end)
    |> Enum.map(fn {_letter, index} -> index end)
  end
  
  def print_win do
    IO.puts "YOU WIN, CONGRATULATIONS!"
    IO.gets ""
  end

  def print_lose(word) do
    IO.puts "YOU LOSE! THE WORD WAS #{word}"
    IO.gets ""
  end
end
