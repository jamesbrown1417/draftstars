# Import libraries-------------------------------------------------------------
using Tidier, CSV, Combinatorics, StatsBase

# Import data------------------------------------------------------------------
data = CSV.read("data/input_file.csv", DataFrame)
println("Please wait while the data is being processed...")

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

# Minimum salary constraint
println("What is the minimum salary to be considered?")
min_salary = parse(Int64, readline())

# List to store teams
sampled_teams = []

# Sample 10000 teams
for i in 1:10000
    sampled_team = sample_team(defenders, midfielders, rucks, forwards)
    if sampled_team[1, :total_salary] <= 100000 &&  sampled_team[1, :total_salary] >= min_salary
        push!(sampled_teams, sampled_team)
    end
end

# Take input for the number of teams needed
print("Enter the number of teams needed: ")
num_teams = parse(Int64, readline())

# Get 100 random teams from sampled teams meeting budget constraints-------------
sampled_teams = StatsBase.sample(sampled_teams, num_teams, replace=false)

# Save teams to csv-------------------------------------------------------------
for (i, team) in enumerate(sampled_teams)
    CSV.write("output/team_$i.csv", team)
end

println("Done!")