# Linear monotone preference model induction - by genetic algorithm
Genetic algorithm to estimate linear monotone preference model attributes from given data. Semestral project for Information models with ordering.

## How to run & use
Requires Ruby 2.4>=
`ruby script.rb file_to_process.csv'

It process csv file with 6 columns, where 1. is ID, 2. - 5. are domain values and 6. is given rating of item
Default weights for each attribute are between 1 and 4 for each attr. It can be changed in script.rb in initialization of Genetics::Darwin
If you want to compute with any other number of domains than 4, you can modify script.rb in load_from_file method.

## Genetics library
genetics.rb is general library for evolution. All you have to do is initialize Genetics::Darwin with 3 params:
  - min values vector
  - max values vector
  - fitness function that takes specific vector and returns ranking ( better ranking => better vector)
and then call run method on this object with params:
  - population size
  - crossover propability
  - mutation propability
  - block with condition to stop evolution ( two input params - current fitness, number of iterations )

Library just selects vectors in values between max vector and min vector and evolve them with respect to fitness function.

## My usage, results
We had users.csv file from which we should estimate LMPM. We should try to optimalize our estimated model with respect to two metrics - #hits in TOP10 (respecting order) and RMSE.

This algorithm gained RMSE about 0.014 and got all 10 of 10 hits in top10. Unfortunately I have deleted values for 0.014 RMSE, but i have it for 0,0214214902. Results and orignal assigment document you can see as NeznamyUzivatel.xlsx
