# Import libraries-------------------------------------------------------------
using Tidier, CSV, Combinatorics

# Import data------------------------------------------------------------------
data = CSV.read("data/players_Co0cbrYQ-1.csv", DataFrame)

# Get DataFrames for each position----------------------------------------------
defenders = @chain data begin
    @filter(Position == "DEF")
    @arrange(desc(Salary))
    @slice(1:10)
end

midfielders = @chain data begin
    @filter(Position == "MID")
    @arrange(desc(Salary))
    @slice(1:10)
end

rucks = @chain data begin
    @filter(Position == "RK")
    @arrange(desc(Salary))
    @slice(1:4)
end

forwards = @chain data begin
    @filter(Position == "FWD")
    @arrange(desc(Salary))
    @slice(1:10)
end

# Get all combinations of each position-----------------------------------------
defender_combinations = combinations(1:nrow(defenders), 2)
midfielder_combinations = combinations(1:nrow(midfielders), 4)
ruck_combinations = combinations(1:nrow(rucks), 1)
forward_combinations = combinations(1:nrow(forwards), 2)


# Get all possible teams under budget-------------------------------------------

# Empty list to store teams
best_teams = []

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

                # Total Salary
                total_salary = def_salary + mid_salary + ruck_salary + fwd_salary

                # If total salary is under budget, print team
                if total_salary <= 100000 && total_salary >= 99000
                    team = [def; mid; ruck; fwd]
                    team[!, :team_salary] .= sum(team[!, :Salary])
                    push!(best_teams, team)
                end
            end
        end
    end
end