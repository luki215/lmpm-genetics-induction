require 'csv'
#require 'byebug'
require './genetics.rb'
#require 'pp'
class Items
    def initialize
        @items = Array.new
    end
    #Item is RankedItem instance
    def << (item)
        @items << item
    end
    def freeze
        if(!self.frozen?)
            @items.sort_by! {|item| item.id}
            @items.freeze
            @items_rank = @items.map{|item| item.ranking}
            @items_rank.freeze
            super
        end   
    end

    # @evaluators ItemEvaluator instance, 
    # @metrics = lambda(orig_values[], evalved_values[]) -> number how good evaluation was 
    def evaluate(evaluator, metrics)
        metrics.call(@items_rank,  @items.map {|it| evaluator.evaluate(it)})
    end

    def get_items_ranking(evaluator)
        @items.map {|it| evaluator.evaluate(it)}
    end

end

class RankedItem
    attr_accessor :id, :domain_values, :ranking
end

class DomainsContainer
    attr_reader :domains
    # @domains_values = array with values for each domain 
    def add_or_update(domains_values)
        @domains ||= domains_values.each_with_index.map{|dom_val, i| Domain.new i, dom_val }

        @domains.each_with_index do |it, i| 
            it.update_bounds!(domains_values[i])
        end
    end

    def get_min_vector
        @domains.map {|d| d.min}
    end
    
    def get_max_vector
        @domains.map {|d| d.max}
    end
    def freeze
        @domains.freeze
        super
    end
end

class Domain
    attr_accessor :id, :max, :min

    def initialize(id, val)
        @max = @min = val
        @id = id
    end
    def update_bounds!(value)
        @max = value if value > @max
        @min = value if value < @min
    end
end

class DomainEvaluator
    attr_accessor :domain, :ideal_point, :weight

    def evaluate(item)
        val = item.domain_values[domain.id]
        l1 = (ideal_point - domain.min == 0)? 1 : (val-domain.min.to_f)/(ideal_point - domain.min)
        l2 = (ideal_point - domain.max == 0)? 1 : (val-domain.max.to_f)/(ideal_point - domain.max)

        res = (l2 < l1)? l2 : l1
        res * weight
    end
end


class ItemEvaluator
    # domains = DomainsContainer instance
    # domains_params = array with ideal points and weights for all domains 
    #   [d1 point, d1 weight, d2 point, d2 weight, ...]
    def initialize(domains, domains_params)
        @domain_evaluators = Array.new
        domains.domains.each_with_index do |dom, i|
            d = DomainEvaluator.new
            d.domain = dom
            d.ideal_point = domains_params[i*2]
            d.weight = domains_params[i*2 + 1]
            @domain_evaluators << d
        end
    end
    #item = instance of RankedItem
    # does (x1*w1 + x2*w2  + ... xn*wn)/sum(w1..wn) 
    def evaluate(item)
        weight_sum = 0
        weighted_value_sum = 0
        @domain_evaluators.each do |de|
            weighted_value_sum += de.evaluate(item)
            weight_sum += de.weight
        end
        return weighted_value_sum.to_f/weight_sum
    end
end

class Metrics
    def self.rmse
        -> (orig_vals, new_vals) {
            sum = 0
            orig_vals.zip(new_vals).map {|o, n| sum += (o-n)*(o-n) }
            1-Math.sqrt(sum/orig_vals.length)
        }
    end
    def self.top10
        ->(orig_vals, new_vals){
            o = (orig_vals.zip([*1..orig_vals.size]).sort{|x, y| y[0]<=>x[0]})[0..9].map{|val, ord| ord}
            n = new_vals.zip([*1..orig_vals.size]).sort{|x, y| y[0]<=>x[0]}[0..9]
            r = 0
            n.each_with_index do |it, i| 
                r+=1 if o.include? n[i][1] 
            end
            r
        }
    end

    def self.top10ordr
        ->(orig_vals, new_vals){
            o = (orig_vals.zip([*1..orig_vals.size]).sort{|x, y| y[0]<=>x[0]})[0..9].map{|val, ord| ord}
            n = new_vals.zip([*1..orig_vals.size]).sort{|x, y| y[0]<=>x[0]}[0..9]
            r = 0
            n.each_with_index do |it, i| 
                r+=1 if o[i] ==  n[i][1] 
            end
            r
        }
    end

end


# Program
class Program


    def run(file_name)
        # all the items we want to analyze sorted  
        @items = Items.new
        #domains in which we analyze items
        @domains = DomainsContainer.new
        
        load_from_file(file_name)

        

        fitness_fnc = ->(rank_vector){ @items.evaluate( ItemEvaluator.new(@domains, rank_vector), Metrics.top10 ) }
        fitness_fnc = ->(rank_vector){ @items.evaluate( ItemEvaluator.new(@domains, rank_vector), Metrics.top10ordr ) }
        fitness_fnc = ->(rank_vector){ @items.evaluate( ItemEvaluator.new(@domains, rank_vector), Metrics.rmse ) }

        
        darwin = Genetics::Darwin.new(  @domains.get_min_vector.zip([1, 1, 1, 1]).flatten, 
                                        @domains.get_max_vector.zip([4, 4, 4, 4]).flatten, 
                                        fitness_fnc
                                        )
        best_vals, fitness = darwin.run(100, 0.95, 0.05) {|fitness, iterations| iterations < 100 && fitness <= 0.98}
        puts "best params: " + best_vals.to_s
        puts "fitness: " + (fitness).to_s

        # print model value for each item
        # puts @items.get_items_ranking( ItemEvaluator.new(@domains, best_vals) )
    end

    def load_from_file(file_name)
        #csv: ID; dom1, dom2, dom3, dom4, Ranking
        CSV.foreach(file_name, col_sep: ';', converters: :all) do |row|
            @domains.add_or_update(row[1..4])
            
            item = RankedItem.new
            item.id = row[0]
            item.domain_values = row[1..4]
            item.ranking = row[5]
            @items << item
        end

        @items.freeze
        @domains.freeze
    end
end


if ARGV[0].nil?
    puts 'ERROR, must run script.rb <file_to_process>.csv'
    exit(-1)
end
#Program.new.test_run # ARGV[0]
Program.new.run  ARGV[0]
