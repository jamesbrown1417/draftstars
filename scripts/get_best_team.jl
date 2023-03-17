# Import libraries-------------------------------------------------------------
using Tidier, CSV, Combinatorics, RCall

# Import data------------------------------------------------------------------
data = CSV.read("data/input_file.csv", DataFrame)

# Get score data from R--------------------------------------------------------
@rput data
R"library(tidyverse)"
R"player_stats <- fitzRoy::fetch_player_stats_afl(season = 2023, round_number = 1)"
R"player_stats <- player_stats  |> mutate(player_name = paste(player.player.player.givenName, player.player.player.surname))"
R"player_stats <-  player_stats |> select(player_name, fantasy_score=dreamTeamPoints)"
R"new_data <- left_join(data, player_stats, by = c('Name' = 'player_name'))"
R"new_data <- new_data  |> filter(!is.na(fantasy_score))"
@rget new_data

# Function to format possible number of teams-----------------------------------
function commas(num::Integer)
    str = string(num)
    return replace(str, r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")
end

# Function to get the number of unique players----------------------------------
function get_unique_players(team_indices::NTuple{4,Vector{Int64}})
    def_players = defenders[team_indices[1], :Name]
    mid_players = midfielders[team_indices[2], :Name]
    ruck_players = rucks[team_indices[3], :Name]
    fwd_players = forwards[team_indices[4], :Name]
    return length(unique([def_players; mid_players; ruck_players; fwd_players]))
end

# Get DataFrames for each position----------------------------------------------
defenders = @chain new_data begin
    @filter(Position == "DEF")
    @arrange(desc(Salary))
end

midfielders = @chain new_data begin
    @filter(Position == "MID")
    @arrange(desc(Salary))
end

rucks = @chain new_data begin
    @filter(Position == "RK")
    @arrange(desc(Salary))
end

forwards = @chain new_data begin
    @filter(Position == "FWD")
    @arrange(desc(Salary))
end


# Get all combinations of each position-----------------------------------------
defender_combinations = combinations(1:nrow(defenders), 2)
midfielder_combinations = combinations(1:nrow(midfielders), 4)
ruck_combinations = combinations(1:nrow(rucks), 1)
forward_combinations = combinations(1:nrow(forwards), 2)

# Print number of combinations--------------------------------------------------
num_combinations = length(defender_combinations) * length(midfielder_combinations) * length(ruck_combinations) * length(forward_combinations)
num_combinations_format = commas(num_combinations)
println("Number of possible teams: $num_combinations_format")

# Get Salary for each team------------------------------------------------------
def_salaries = [sum(defenders[i, :Salary]) for i in defender_combinations]
mid_salaries = [sum(midfielders[i, :Salary]) for i in midfielder_combinations]
ruck_salaries = [sum(rucks[i, :Salary]) for i in ruck_combinations]
fwd_salaries = [sum(forwards[i, :Salary]) for i in forward_combinations]

# Get all salaries--------------------------------------------------------------
all_salaries = collect(Iterators.product(def_salaries, mid_salaries, ruck_salaries, fwd_salaries))
all_salaries = all_salaries[:]
allowed_salaries = findall(x -> sum(x) < 100000, all_salaries)

# Get all teams-----------------------------------------------------------------
all_teams = collect(Iterators.product(defender_combinations, midfielder_combinations, ruck_combinations, forward_combinations))
all_teams = all_teams[:]

# Get all legal teams-----------------------------------------------------------
all_legal_teams = all_teams[allowed_salaries]

# Get scores for each team------------------------------------------------------
def_scores = [sum(defenders[i, :fantasy_score]) for i in defender_combinations]
mid_scores = [sum(midfielders[i, :fantasy_score]) for i in midfielder_combinations]
ruck_scores = [sum(rucks[i, :fantasy_score]) for i in ruck_combinations]
fwd_scores = [sum(forwards[i, :fantasy_score]) for i in forward_combinations]

# Get all scores by a legal team------------------------------------------------
all_scores = collect(Iterators.product(def_scores, mid_scores, ruck_scores, fwd_scores))
all_scores = all_scores[:]
all_scores_legal_team = all_scores[allowed_salaries]

# Sort teams by score-----------------------------------------------------------
all_teams_sorted = sortperm(all_scores_legal_team, by = x -> sum(x), rev = true)

# Empty variable to store best team---------------------------------------------
best_team = []

# Loop through the best teams until we find one with 9 unique players-----------
for i in all_teams_sorted
    team_indices = all_legal_teams[i]
    num_unique_players = get_unique_players(team_indices)
    if num_unique_players == 9
        best_team = team_indices
        break
    end
end

# Return best team--------------------------------------------------------------
def_players = defenders[best_team[1], :]
mid_players = midfielders[best_team[2], :]
ruck_players = rucks[best_team[3], :]
fwd_players = forwards[best_team[4], :]

best_team = [def_players; mid_players; ruck_players; fwd_players]

# Add total salary and score to best team---------------------------------------
best_team = @chain best_team begin
    @mutate(total_salary = sum(Salary), total_score = sum(fantasy_score))
end