library(tidyverse)

sims <- read_csv("data/players_Co0cbrYQ-1.csv")

# d
d <- sims |> filter(Position == "DEF") |> arrange(desc(Salary)) |> head(8)
nd <- nrow(d)
combn_list <- combinat::combn(1:nd, m = 2, simplify = FALSE) 
all_def <- map(combn_list, ~ d |> slice(c(.x)))

# m
m <- sims |> filter(Position == "MID") |> arrange(desc(Salary)) |> head(6)
nm <- nrow(m)
combn_list <- combinat::combn(1:nm, m = 4, simplify = FALSE)
all_mid <- map(combn_list, ~ m |> slice(c(.x)), .progress = TRUE)

# r
r <- sims |> filter(Position == "RK")
nr <- nrow(r)
combn_list <- combinat::combn(1:nr, m = 1, simplify = FALSE)
all_rk <- map(combn_list, ~ r |> slice(c(.x)))

# f
f <- sims |> filter(Position == "FWD") |> arrange(desc(Salary)) |> head(8)
nf <- nrow(f)
combn_list <- combinat::combn(1:nf, m = 2, simplify = FALSE)
all_fwd <- map(combn_list, ~ f |> slice(c(.x)))

# Get total salaries for each team
def_salaries <- map(all_def, ~ sum(.x$Salary)) |> enframe() |> unnest() |> rename(def = name, def_salary = value)
mid_salaries <- map(all_mid, ~ sum(.x$Salary)) |> enframe() |> unnest() |> rename(mid = name, mid_salary = value)
rk_salaries <- map(all_rk, ~ sum(.x$Salary)) |> enframe() |> unnest() |> rename(rk = name, rk_salary = value)
fwd_salaries <- map(all_fwd, ~ sum(.x$Salary)) |> enframe() |> unnest() |> rename(fwd = name, fwd_salary = value)

# All possible teams
all_possible_teams <-
  expand.grid("def" = 1:length(all_def),
              "mid" = 1:length(all_mid),
              "rk" = 1:length(all_rk),
              "fwd" = 1:length(all_fwd))

# Join salaries
valid_teams <-
  all_possible_teams |> 
  left_join(def_salaries) |> 
  left_join(mid_salaries) |> 
  left_join(rk_salaries) |> 
  left_join(fwd_salaries) |> 
  mutate(total_salary = def_salary + mid_salary + rk_salary + fwd_salary) |> 
  filter(total_salary <= 100000) |> 
  arrange(desc(total_salary))

# Empty list
draftstars_teams <- vector("list", nrow(valid_teams))

# Populate with every team
for (i in 1:nrow(valid_teams)) {
  def_index = valid_teams[i, 1]
  mid_index = valid_teams[i, 2]
  rk_index = valid_teams[i, 3]
  fwd_index = valid_teams[i, 4]
  
  df <- tidytable::bind_rows(all_def[[def_index]],
                             all_mid[[mid_index]],
                             all_rk[[rk_index]],
                             all_fwd[[fwd_index]])
  
  draftstars_teams[[i]] <- df
}
