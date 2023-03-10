# Import libraries-------------------------------------------------------------
using Tidier, CSV, Combinatorics, StatsBase

# Import data------------------------------------------------------------------
data = CSV.read("../data/players_Co0cbrYQ-1.csv", DataFrame)

# Get DataFrames for each position----------------------------------------------
defenders = @chain data begin
    @filter(Position == "DEF")
    @arrange(desc(Salary))
end

midfielders = @chain data begin
    @filter(Position == "MID")
    @arrange(desc(Salary))
end

rucks = @chain data begin
    @filter(Position == "RK")
    @arrange(desc(Salary))
end

forwards = @chain data begin
    @filter(Position == "FWD")
    @arrange(desc(Salary))
end

# Function to Randomly sample a team--------------------------------------------
function sample_team(defenders, midfielders, rucks, forwards)
    # Sample indices
    def_indices = StatsBase.sample(1:nrow(defenders), 2, replace=false)
    mid_indices = StatsBase.sample(1:nrow(midfielders), 4, replace=false)
    ruck_indices = StatsBase.sample(1:nrow(rucks), 1, replace=false)
    fwd_indices = StatsBase.sample(1:nrow(forwards), 2, replace=false)

    # Create team
    team = vcat(defenders[def_indices, :], midfielders[mid_indices, :], rucks[ruck_indices, :], forwards[fwd_indices, :])
    
    # Add total salary and return
    team = @chain team begin
        @mutate(total_salary = sum(Salary))
    end
    return team
end

# Sample team-------------------------------------------------------------------

# List to store teams
sampled_teams = []

# Sample 10000 teams
for i in 1:10000
    sampled_team = sample_team(defenders, midfielders, rucks, forwards)
    if sampled_team[1, :total_salary] <= 100000 &&  sampled_team[1, :total_salary] >= 90000
        push!(sampled_teams, sampled_team)
    end
end

# Get 100 random teams from sampled teams meeting budget constraints-------------
sampled_teams = StatsBase.sample(sampled_teams, 100, replace=false)
