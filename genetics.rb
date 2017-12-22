require 'benchmark'
require 'byebug'
module Genetics
    
    class Darwin
        # fitness = lambda taking vector of size inserted vectors and returning numeric value
        def initialize(min_vector, max_vector, fitness)
            @min_vector = min_vector
            @max_vector = max_vector
            @individual_size = @max_vector.size
            @fitness_f = fitness
            @random = Random.new

            @best_gen = nil
            @best_fitness = 0
        end

        # block(actual fitness, iteration) -> true/false if continue
        # population size should be even
        def run(population_size, crossover_prop, mutation_prop)
            @crossover_prop = crossover_prop
            @mutation_prop = mutation_prop
            generate_population population_size 
            
            iteration = 0
            while(yield(@best_fitness, iteration))
                new_population = selection
                i = 0
                while i < new_population.size 
                    gen1 = new_population[i]
                    gen2 = new_population[i+1]
                    gen1, gen2 = crossover gen1, gen2
                    new_population[i] = mutate gen1
                    new_population[i+1] = mutate gen2
                    i = i+2
                end
                @population = new_population
                update_fitness_vector
                iteration+=1

                max = @fitness_vector.max
                if max > @best_fitness
                    @best_fitness = max
                    @best_gen = @population[@fitness_vector.index(max)]
                end
                puts max
                
            end

            return @best_gen, @best_fitness
        end

        private
        def generate_population(population_size)
            @population = []

            @population = Array.new(population_size) { Array.new(@min_vector.size) {|i| @random.rand( @min_vector[i]..@max_vector[i])}  }
            update_fitness_vector
        end

        def selection
            # as here https://en.wikipedia.org/wiki/Selection_(genetic_algorithm)
            new_fit = @fitness_vector
            fitness_sum = new_fit.reduce(0, :+)
            sum = 0
            fitness_acc = new_fit.map{|it| sum += it.to_f/fitness_sum}
            fitness_acc[fitness_acc.length-1] = 1
            fitness_acc.freeze
            new_population = []
            

            while new_population.size < @population.size
                r = @random.rand
                item_index = 0
                fitness_acc.each_index do |i|
                    if r <= fitness_acc[i]
                      item_index = i 
                      break
                    end
                  end
                new_population << @population[item_index]                
            end     
            return new_population     
        end
        def crossover(g1, g2)
            # if we do crossover or not
            if @random.rand <= @crossover_prop
                sp = @random.rand(1..g1.size-2)
                sp2 = @random.rand(1..g1.size - 2)
                sp, sp2 = sp2, sp if sp > sp2
                r1 = g1[0..sp] + g2[sp+1..sp2] + g1[sp2+1..g2.size-1]
                r2 = g2[0..sp] + g1[sp+1..sp2] + g2[sp2+1..g1.size-1]
                return r1, r2
            end
            return g1, g2
        end
        def mutate(g)
            if @random.rand <= @mutation_prop
                for i in 0..g.size-1
                    g[i] =  (@random.rand( @min_vector[i]..@max_vector[i])) if @random.rand < 0.125 
                    
                end
            end
            g
        end

        def update_fitness_vector
            @fitness_vector = @population.map{|individual| @fitness_f.(individual)}
        end


        def prp(pop)
            fit = pop.map{|individual| @fitness_f.(individual)}
            pop.each_with_index do |p, i|
                puts p.to_s + "-" + fit[i].to_s
            end
        end
        def fs(pop)
            fit = pop.map{|individual| @fitness_f.(individual)}
            fit.reduce(0, :+)
        end

    end

end