bad forecast good decision
================
Carl Boettiger

``` r
## Plotting theme settings -- aesthetics only, all can be omitted without consequence
library(ggthemes)
library(hrbrthemes)
library(ggplot2)
library(Cairo)
library(extrafont)
extrafont::loadfonts()
ggplot2::theme_set(hrbrthemes::theme_ipsum_rc())
#theme_set(theme_solarized(base_size=16))

scale_colour_discrete <- function(...) ggthemes::scale_colour_solarized()
scale_fill_discrete <- function(...) ggthemes::scale_fill_solarized()
pal <- ggthemes::solarized_pal()(6)
txtcolor <- "#586e75"
```

``` r
## Required computational libraries
library(tidyverse)
library(MDPtoolbox)
library(expm)
library(mdplearning) # remotes::install_github("boettiger-lab/mdplearning")
```

``` r
states <- seq(0,24, length.out = 240)
actions <- states
obs <- states
sigma_g <- 0.05
reward_fn <- function(x,h) pmin(x,h)
discount <- 0.99

# K is at twice max of f3; 8 * K_3 / 5
f1 <- function(x, h = 0, r = 2, K = 10 * 8 / 5){
  s <- pmax(x - h, 0)
  s + s * (r * (1 - s / K) )
}
f2 <- function(x, h = 0, r = 0.5, K = 10){
  s <- pmax(x - h, 0)
  s + s * (r * (1 - s / K) )
}

# max is at 4 * K / 5 
f3  <- function(x, h = 0, r = .002, K = 10){
  s <- pmax(x - h, 0)
  s + s ^ 4 * r * (1 - s / K)
}

# looks even closer to f2; not used
#f4  <- function(x, h = 0, r = 4e-7, K = 10){
#  s <- pmax(x - h, 0)
#  s + s ^ 8 * r * (1 - s / K) + s * (1 - s / K)
#}

models <- list(f1 = f1, f2 = f2, f3 = f3)
model_sigmas <- c(sigma_g, 1.5 * sigma_g, sigma_g)

true_model <- "f3"
```

``` r
# A function to compute the transition matrices for each model:
transition_matrices <- function(f,
                      states,
                      actions,
                      sigma_g){

  n_s <- length(states)
  n_a <- length(actions)

  transition <- array(0, dim = c(n_s, n_s, n_a))
  for (k in 1:n_s) {
    for (i in 1:n_a) {
      nextpop <- f(states[k], actions[i])
      if(nextpop <= 0){
        transition[k, , i] <- c(1, rep(0, n_s - 1))
      } else if(sigma_g > 0){
        x <- dlnorm(states, log(nextpop), sdlog = sigma_g)
        if(sum(x) == 0){ ## nextpop is computationally zero
          transition[k, , i] <- c(1, rep(0, n_s - 1))
        } else {
          x <- x / sum(x) # normalize evenly
          transition[k, , i] <- x
        }
      } else {
        stop("sigma_g not > 0")
      }
      reward[k, i] <- reward_fn(states[k], actions[i])
    }
  }
  transition
}

## Compute reward matrix (shared across all models)
n_s <- length(states)
n_a <- length(actions)
reward <- array(0, dim = c(n_s, n_a))
for (k in 1:n_s) {
  for (i in 1:n_a) {
    reward[k, i] <- reward_fn(states[k], actions[i])
  }
}

## Now compute the transition matrices for each model
transitions <- lapply(seq_along(models), 
                      function(i) transition_matrices(models[[i]], 
                                                      states, 
                                                      actions, 
                                                      model_sigmas[[i]]))
names(transitions) <- c("f1", "f2", "f3")
```

``` r
## This is the most (only) computationally expensive code chunk:
policies <- 
  map_dfr(transitions, 
          function(P){
    soln <- mdp_value_iteration(P, reward, discount = discount)
    escapement <- states - actions[soln$policy]
    tibble(states, policy = soln$policy, escapement)
    }, 
  .id = "model")
```

``` r
library(mdplearning)
Tmax <- 100
x0 <- which.min(abs(states - 6))
reps <- 100
set.seed(12345)


## Simulate each policy reps times, with `f3` as the true model:

sims <- map_dfr(names(transitions), 
                function(m){
                  policy <- policies %>% filter(model == m) %>% pull(policy)
                  map_dfr(1:reps, 
                          function(i){
                            mdp_planning(transitions[[true_model]], reward, discount,
                                     policy = policy, x0 = x0, Tmax = Tmax) %>%
                              select(value, state_index = state, time, action_index = action)  %>% 
                              mutate(state = states[state_index]) # index->value
                            },
                          .id = "reps")
                },
                .id = "model")
```

## Forecast skill

Note the low variability in the predicted value is a result of the
decision strategy, which tweaks harvest up or down with variation.

``` r
compare <- sims %>%
  mutate(next_state = dplyr::lead(state_index), model = as.integer(model)) %>%
  rowwise() %>%
  mutate(prob =  transitions[[model]][state_index, next_state, action_index],
         expected = transitions[[model]][state_index, , action_index]  %*% states,
         low = states[ max(which(cumsum(transitions[[model]][state_index,,action_index]) < 0.025)) ],
         high = states[ min(which(cumsum(transitions[[model]][state_index,,action_index]) > 0.975)) ],
         true = states[ next_state],
         model = as.character(model)) %>%
 select(time, model, true, expected, low, high, prob, reps)


compare %>% filter(model != "3") %>%  filter(reps == 3, time < 10) %>%
  ggplot(aes(time, col = model, fill = model)) + 
  geom_point(aes(y = true), pch = "*", size = 12) +
  geom_point(aes(y = expected)) + 
  geom_errorbar(aes(ymin = low, ymax = high))
```

![](bad-forecast-good-decision_files/figure-gfm/plot_stepahead-1.png)<!-- -->

``` r
compare_unfished <- sims
compare_unfished$state_index <- rep(sims$state_index[sims$model == "1"],3)
compare_unfished <- compare_unfished %>% 
  mutate(next_state = dplyr::lead(state_index), model = as.integer(model)) %>%
  rowwise() %>%
  mutate(expected = transitions[[model]][state_index, , 1]  %*% states,
         low = states[ max(which(cumsum(transitions[[model]][state_index,,1]) < 0.025)) ],
         high = states[ min(which(cumsum(transitions[[model]][state_index,,1]) > 0.975)) ],
         true = states[ next_state ],
         model = as.character(model)) %>% filter(reps == 2, time < 10, model != "3")


compare_unfished %>%
  ggplot(aes(time, col = model, fill = model)) + 
  geom_point(aes(y = expected)) + 
  geom_errorbar(aes(ymin = low, ymax = high)) +
  geom_point(aes(y = true), pch = "*", size = 12, col = "grey20", show.legend = FALSE)
```

![](bad-forecast-good-decision_files/figure-gfm/plot_stepahead_unfished-1.png)<!-- -->

``` r
scores <- sims %>%
  mutate(next_state = dplyr::lead(state_index), model = as.integer(model)) %>%
  filter(model < 3) %>%
  rowwise() %>%
  mutate(prob =  transitions[[model]][state_index, next_state, action_index] ) %>% 
  group_by(reps, model) %>%
  summarise(score = sum(log(prob))) 

scores %>% group_by(model) %>% summarise(mean_score = mean(score))
```

    ## # A tibble: 2 x 2
    ##   model mean_score
    ##   <int>      <dbl>
    ## 1     1     -5670.
    ## 2     2      -365.

``` r
scores %>% mutate(model = as.factor(model)) %>% 
  ggplot(aes(x = score, group = model, fill = model)) +
  geom_histogram(binwidth = 70)
```

![](bad-forecast-good-decision_files/figure-gfm/prob_scores-1.png)<!-- -->

## Simulations

``` r
fig_ts <- 
  sims %>%
  filter(time < 25, reps < 5) %>%
  ggplot(aes(time, state, col=model, group = interaction(model,reps))) + 
  geom_line(alpha=0.3) 
fig_ts
```

![](bad-forecast-good-decision_files/figure-gfm/plot_sims-1.png)<!-- -->

``` r
##  Net Present Value accumulates over time, equivalent for models with near-identical management stategy
npv_df <- sims %>% 
  group_by(model, reps) %>%
  mutate(npv = cumsum(value * discount ^ time)) %>%
  group_by(time, model)  %>% 
  summarise(mean_npv = mean(npv)) %>% 
  arrange(model, time) %>% ungroup()

optimal <- select(filter(npv_df, model == "3"), time, mean_npv)

npv_df %>%
  filter(model != "3", time %in% seq(1,100, by = 5)) %>%
  ggplot(aes(time, mean_npv)) +
  geom_line(data = optimal, lwd = 1.5, col = "grey20") +
  geom_point(aes(col=model), size = 4, alpha = 0.8) + 
  ylab("Net present value") + xlab("time")  
```

![Corresponding utility (measured as mean net present value, that is:
cumulative value, discounting future values by \(\delta^t\), averaged
across replicates). Note that the exepcted utility under model 1, which
has the worst forecast, is nearly identical to the optimal utility
achieved by managing under the correct model, 3. The utility derived
from model 2 is far smaller, despite it’s overall better performance in
long term
forecasts.](bad-forecast-good-decision_files/figure-gfm/plot_npv-1.png)

``` r
d <- map_dfc(models, function(f) f(states) - states) %>% mutate(state = states)
d %>% pivot_longer(names(models), "model") %>%
  ggplot(aes(state, value, col=model)) +
  geom_point() + 
  geom_hline(aes(yintercept = 0)) + 
  coord_cartesian(ylim = c(-5, 8), xlim = c(0,16))
```

![](bad-forecast-good-decision_files/figure-gfm/plot_models-1.png)<!-- -->

``` r
policies %>%
  ggplot(aes(states,escapement, col=model, lty=model)) + geom_line(lwd=2)
```

![](bad-forecast-good-decision_files/figure-gfm/plot_policies-1.png)<!-- -->

## Conclusions

  - A good forecast does not mean good management
  - A bad forecast does not mean the model is bad for management
  - A model permitting successful management does not imply the model is
    “correct” or generally “good at forecasting”

Model with the egregiously optimistic long-term forecast for the stock
size of an unexploited fishery nevertheless actually leads to more
conservative management. In contrast, the model which correctly predicts
the long-term average stock size without fishing nevertheless leads to
substantial over-harvesting.

# Appendix

### Unharvested forecasting performance

Here we examine the forecasts under each model, `Tmax` steps into the
future, ignoring harvesting. This largely highlights only the
differences in the unfished equilibria of the models. It less surprising
that bad performance in predicting the long-term equilibrium would not
necessarily mean bad management.

``` r
sim <- function(f, x0, Tmax, reps = 1){
  map_dfr(1:reps, 
          function(i){
            x <- numeric(length(Tmax))
            x[1] <- x0
            for(t in 2:Tmax){
              mu <- f(x[t-1])
              x[t] <-  rlnorm(1, log(mu), sdlog = sigma_g)
            }
            tibble(t = 1:Tmax, x= x)
          },
          .id="rep")
}
models[names(models) != true_model]
```

    ## $f1
    ## function(x, h = 0, r = 2, K = 10 * 8 / 5){
    ##   s <- pmax(x - h, 0)
    ##   s + s * (r * (1 - s / K) )
    ## }
    ## <bytecode: 0x55bf7273bc80>
    ## 
    ## $f2
    ## function(x, h = 0, r = 0.5, K = 10){
    ##   s <- pmax(x - h, 0)
    ##   s + s * (r * (1 - s / K) )
    ## }
    ## <bytecode: 0x55bf78e00a48>

``` r
true_sim <- sim(models[[true_model]], 5, 100, 1) %>%
  mutate(model = true_model, mean = x, ymin = NA, ymax = NA)
df <- map_dfr(models[1:2], sim, 5, 100, 100, .id = "model")
forecast <- df %>% 
  group_by(model, t) %>% summarise(mean = mean(x), sd = sd(x))
```

    ## `summarise()` regrouping output by 'model' (override with `.groups` argument)

``` r
forecast %>%
  ggplot(aes(t, mean, col=model)) +
  geom_line() + 
  geom_line(data = true_sim) + 
  geom_ribbon(aes(fill= model, ymin = mean - 2*sd, ymax = mean + 2*sd), alpha=0.1, col=NA)
```

![](bad-forecast-good-decision_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

``` r
d <- forecast %>% group_by(model) %>% 
  mutate(true = true_sim$x) %>%
  summarise(rmsd = sqrt(mean( (mean - true) ^ 2 )),
            r2 = 1 - sum( (mean - true) ^ 2  ) / sum( mean ^ 2 )
            )
```

    ## `summarise()` ungrouping output (override with `.groups` argument)

``` r
rmsd <- d %>% pull(rmsd)
names(rmsd) <- d %>% pull(model)

opt <- sqrt(mean((true_sim$x - 10)^2))
opt
```

    ## [1] 1.26398

Model 2 clearly outperforms model 1 in predictive capacity. The root
mean squared deviation between the model 2 mean and the realization is
0.9817174, far lower than model 1 at 6.2573924.

``` r
# Simulate the evolution of probability distribution directly using a matrix exponent
prob_dynamics <- function(M, X, Tmax){
  probability <- t(M) %^% Tmax %*% X 
  data.frame(state = states, probability)
}

x0 <- which.min(abs(states - 6))
X <- numeric(length=length(states))
X[x0] <- 1

map_dfr(transitions, 
        function(m) prob_dynamics(m[,,1], X, 100),
        .id = "model") %>%
  group_by(model) %>%
  ggplot(aes(state, probability, col=model)) +
  geom_line()
```

![](bad-forecast-good-decision_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->