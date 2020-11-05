---
name: Carl Boettiger
title: Assistant Professor
email: cboettig@berkeley.edu
homepage: https://carlboettiger.info
address: "Nature Magazine"
opening: "Dear Editors:"
closing: "Sincerely,"
campus: ucb
dept: espm
fontsize: 10pt

## Leave this as is, make sure template.tex is in working directory
output:
  pdf_document:
    template: template.tex

## NB: Add an image of your signature called 'signature.png'
---

I am pleased to submit "Bad forecast, good decision: predictive accuracy is not everything" for your consideration.  In the enclosed manuscript, I demonstrate how a model that gives consistently poor forecasts can be a much better guide to management and decision-making than a model which consistently gives much more accurate forecasts.  This is not the result of chance or rare events or a convoluted decision choice: both models generate fully probablistic forecasts, and the decision problem in question is a well studied, classic control problem in the globally important area of fisheries management. Even though the decision is based on probabilistic step-ahead predictions, the model that makes the worst prediction each time consistently leads to the best decision. A manager using model 1 to make their decisions would detect no irregularity when comparing model predictions to outcomes each year, but nevertheless experiences worse ecological and economic outcomes than would a manager using model 2 to manage the very same fishery (though our second manager might be puzzled by how they could be doing so well despite the fact that their model is very obviously making terrible predictions.)

This apparent paradox is easily explained when we step back from the quantitative details of forecasting performance and examine the decision context itself.  In this example, neither model is the "true" model, just as we will never know the "true" model in any complex management problem.  Each model captures different features of that true model to different degrees, but the features which drive the decision outcomes are not the same as those which drive forecast accuracy.  This situation is likely in any case where the quality of decision outcome depends on some wider context (e.g. ecological recovery or economic performance) and does not follow directly from forecast accuracy.

Accurate, probabilistic forecasts are often considered the ultimate out-of-sample prediction and the gold standard of model performance.  A rapid expansion of available data and an equal acceleration predictive methods based on statistical and machine-learning techniques has only made this spotlight more intense.  Today, it is often taken as given that good decisions will require good forecasts.  I hope my results illustrating how easily that premise is disproved will highlight just how badly things might go if we always assert that the model with the best forecast should always be the basis for decision making. 

Thank you for your time and consideration.
