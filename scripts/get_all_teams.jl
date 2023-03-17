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

# Get all possible teams under budget-------------------------------------------

# Empty list to store teams
best_teams = []
best_score = 0
counter = 0

# Loop through and add potential teams
for i in defender_combinations
    for j in midfielder_combinations
        for k in ruck_combinations
            for l in forward_combinations
                # Positions
                def = defenders[i, :]
                mid = midfielders[j, :]
                ruck = rucks[k, :]
                fwd = forwards[l, :]

                # Salaries
                def_salary = sum(def[:, :Salary])
                mid_salary = sum(mid[:, :Salary])
                ruck_salary = sum(ruck[:, :Salary])
                fwd_salary = sum(fwd[:, :Salary])
                
                # Fantasy scores
                def_score = sum(def[:, :fantasy_score])
                mid_score = sum(mid[:, :fantasy_score])
                ruck_score = sum(ruck[:, :fantasy_score])
                fwd_score = sum(fwd[:, :fantasy_score])

                # Total Salary
                total_salary = def_salary + mid_salary + ruck_salary + fwd_salary
                
                # Total Score
                total_score = def_score + mid_score + ruck_score + fwd_score
                
                # Get progress
                counter += 1
                percent_complete = round(counter / num_combinations * 100, digits = 2)
                print("\rPercent complete: $percent_complete%")

                # If total salary is under budget, print team
                if total_salary <= 100000 && total_score > best_score
                    team = [def; mid; ruck; fwd]
                    team[!, :team_salary] .= sum(team[!, :Salary])
                    push!(best_teams, team)
                    best_score = total_score
                end
            end
        end
    end
end

# Filter number of players in team equal to 9----------------------------------
best_teams = [team for team in best_teams if length(unique(team[:, :Name])) == 9]

# For best team, print team and score-------------------------------------------
for best_team in best_teams
    println("Team Salary: $(best_team[1, :team_salary])")
    println("Team Score: $(sum(best_team[:, :fantasy_score]))")
end

# Write out best team
CSV.write("output/best_team_rich_carl.csv", best_teams[end])