# Import libraries-------------------------------------------------------------
using Tidier, CSV, Combinatorics, StatsBase

# Import data------------------------------------------------------------------
data = CSV.read("data/input_file.csv", DataFrame)
println("Please wait while the data is being processed...")

# Function to format possible number of teams-----------------------------------
function commas(num::Integer)
    str = string(num)
    return replace(str, r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => ",")
end

# Fix data names---------------------------------------------------------------
data = @chain data begin
    @rename("Player_ID" = "Player ID", "Playing_Status" = "Playing Status")
end

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

# Count the number of possible teams--------------------------------------------
num_teams = binomial(nrow(defenders), 2) * binomial(nrow(midfielders), 4) * binomial(nrow(rucks), 1) * binomial(nrow(forwards), 2)
num_teams = commas(num_teams)
println("From the players provided, there are $num_teams possible teams.")

# Get weights for each position-------------------------------------------------
def_wts = defenders[!, :Weight]
mid_wts = midfielders[!, :Weight]
rk_wts = rucks[!, :Weight]
fwd_wts = forwards[!, :Weight]

# Function to Randomly sample a team--------------------------------------------
function sample_team(defenders, midfielders, rucks, forwards)
    # Sample indices
    def_indices = StatsBase.wsample(1:nrow(defenders), def_wts, 2, replace=false)
    mid_indices = StatsBase.wsample(1:nrow(midfielders), mid_wts, 4, replace=false)
    ruck_indices = StatsBase.wsample(1:nrow(rucks), rk_wts, 1, replace=false)
    fwd_indices = StatsBase.wsample(1:nrow(forwards), fwd_wts, 2, replace=false)

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
print("What is the minimum salary to be considered?: ")
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

# Remove duplicates if any exist------------------------------------------------

# Hash value of each team's set of player names
team_hashes = [hash(Set(team.Name)) for team in sampled_teams]

# Get indices of unique teams
unique_indices = unique(i -> team_hashes[i], 1:length(team_hashes))

# Get unique teams
sampled_teams = sampled_teams[unique_indices]

# Take input for the number of teams needed-------------------------------------
print("Enter the number of teams needed: ")
num_teams = parse(Int64, readline())

# Get 100 random teams from sampled teams meeting budget constraints-------------
sampled_teams = StatsBase.sample(sampled_teams, num_teams, replace=false)

# Remove all existing files in output folder------------------------------------

# Get all CSV files in output folder
output_files = readdir("output", join=true)
output_files = filter(x -> endswith(x, ".csv"), output_files)

# Delete files
for file in output_files
    rm(file)
end

# Get teams in one DataFrame----------------------------------------------------

# Create a dataframe with empty columns
empty_team = DataFrame(
    Player_ID = Missing[missing],
    Position = Missing[missing],
    Name = Missing[missing],
    Team = Missing[missing],
    Opponent = Missing[missing],
    Salary = Missing[missing],
    FPPG = Missing[missing],
    Form = Missing[missing],
    Playing_Status = Missing[missing],
    Weight = Missing[missing],
    total_salary = Missing[missing],
    team_number = Missing[missing])

# Create a new list to store teams with empty team included between each team
new_sampled_teams = []

# Create a dataframe with all teams
for (i, team) in enumerate(sampled_teams)
    team[!, :team_number] .= i
    push!(new_sampled_teams, team)
    push!(new_sampled_teams, empty_team)
end

# Remove last empty team
pop!(new_sampled_teams)

# Create a dataframe with all teams
all_teams = vcat(new_sampled_teams...)

# Save teams to csv-------------------------------------------------------------
CSV.write("output/$(num_teams)_sampled_teams.csv", all_teams)

println("Done!")