$:.unshift "src"

require 'pspace'
#require 'ruby-prof'

module DecisionTree
  class << self
    def load(cols, filepath)
      File.open(filepath, 'r') do |f|
        f.each_line do |line|
          next if line.chomp.empty?
          yield Hash[*cols.zip(line.chomp.split(/,\s*/)).flatten]
        end
      end
    end
  end

  class Machine
    attr_reader :tree

    def initialize
      @tree = nil
    end

    def add(example)
      ::PSpace.add(example)
    end

    def split_rv(rv)
      if rv.class == Hash
        rkey = rv.keys.first
        rval = rv[rkey]
      else
        rkey = rv
        rval = nil
      end
      return rkey, rval
    end

    def putss(rvs, str)
      space = @rv_size - rvs.size
      puts (" " * (space) * 4) + str
    end

    def classify(data)
      # recursively traverse down the tree and figure out the decision.
      #classify_helper(....?)
    end

    # recursive.
    def classify_helper
    end

    def learn(rv_target, &block)
      #RubyProf.start

      tkey, tval = split_rv(rv_target)
      rvs = ::PSpace.rv.reject { |rv| rv == tkey }
      rvs.reject! do |key|
        !block.call(key)
      end
      @rv_size = rvs.size

      @tree = create_node(rv_target, {}, rvs, &block)

      #result = RubyProf.stop
      #printer = RubyProf::MultiPrinter.new(result)
      #printer.print(:path => "profile", :profile => "profile")
    end

    # rv_target - the variable we're trying to learn
    # rv_parents - hash of past decisions in branch
    # rand_vars - remaining rand_vars to decide on
    # block - for filtering which key to use
    def create_node(rv_target, rv_parents, rand_vars, &block)
      tkey, tval = split_rv(rv_target)
      #pkey, pval = split_rv(rv_parent)

      # calculate all gains for remaining rand vars
      gains = rand_vars.map do |key|
        ig = ::PSpace.rv(tkey).given(key, rv_parents).infogain
        putss rand_vars, "#{tkey} | #{key}, #{rv_parents} = #{ig}"
        [ key, ig ]
      end
      putss rand_vars, "Gains: #{gains.to_s}"

      # find the next RV
      # use the rkey and remove it from list of candidate rand_vars
      rkey, _ = gains.max { |a, b|
        if a[1].nan? and b[1].nan?
          0
        elsif a[1].nan?
          -1
        elsif b[1].nan?
          1
        else
          a[1] <=> b[1]
        end
      }
      gains.delete_if { |ig| ig[0] == rkey }
      new_rand_vars = gains.map { |g| g[0] }

      # create node to attach to parent node
      putss rand_vars, "Using :#{rkey} for node with parents #{rv_parents} to create node"
      node = Node.new(rkey)

      # create a child node for every value of selected rkey
      ::PSpace.uniq_vals([rkey]).each do |rval|
        rval_str = rval.first
        new_rv_parents = rv_parents.clone.merge(rkey => rval_str)

        putss rand_vars, "P(#{tkey} | #{new_rv_parents}) ="
        prob_distr = ::PSpace.rv(tkey).given(new_rv_parents).prob
        putss rand_vars, "-- #{prob_distr}"

        ## base case 0
        #if gains.empty?
        #  putss rand_vars, "Base Case 0 #{rkey}: no more rvs"
        #  node.add(rval_str, prob_distr)
        #  next
        #end

        # base case 2
        if gains.all? { |ig| ig[1] == 0.0 }
          putss rand_vars, gains.inspect
          putss rand_vars, "Base Case 2 #{rkey}: Gains all zero"
          node.add(rval, prob_distr)
          next
        end

        # base case 1
        ent = ::PSpace.rv(tkey).given(new_rv_parents).entropy
        putss rand_vars, "H(#{tkey} | #{new_rv_parents}) ="
        putss rand_vars, "-- #{ent}"
        if ent == 0.0
          putss rand_vars, "Base Case 1 #{rkey}: H(#{tkey} | #{new_rv_parents}) = 0"
          node.add(rval, prob_distr)
          next
        end

        putss rand_vars, "Creating child node for #{rkey} = #{rval}"
        child_node = create_node(rv_target, new_rv_parents, new_rand_vars, &block)
        node.add(rval, child_node)
      end

      puts

      return node
    end
  end

  class Node
    attr_accessor :name
    attr_reader :children

    def initialize(name = nil)
      @name = name
      @children = {}
    end

    def add(val, node)
      return if node.nil?
      @children[val] = node
    end

    def inspect
      result = "{ "
      result += %Q{"name": "#{@name}", }
      result += %Q{"children":  \{}
      @children.each do |child_name, child_node|
        result += %Q{"#{child_name}"}
        result += " => "
        result += child_node.inspect
        result += ", "
      end
      result += " }"
      result += " }"
    end

  end

end


#PSpace.import([
#  { :cyl => 5, :acc => :low },
#  { :cyl => 5, :acc => :low },
#])
#
#puts PSpace.rv(:acc).given(:cyl).entropy



dt = DecisionTree::Machine.new
cols = [
  :age, :workclass, :fnlwgt, :education, :education_num, :marital_status,
  :occupation, :relationship, :race, :sex, :capital_gain, :capital_loss,
  :hours_per_week, :native_country, :income
]

puts "loading..."
DecisionTree.load(cols, "data/adult.data") do |example|
  dt.add(example)
end

puts "learning..."
dt.learn(:income) do |rv|
  if rv == :age
    false
  elsif rv == :workclass
    true
  elsif rv == :fnlwgt
    false
  elsif rv == :education
    false
  elsif rv == :education_num
    false
  elsif rv == :marital_status
    false
  elsif rv == :occupation
    false
  elsif rv == :relationship
    false
  elsif rv == :race
    false
  elsif rv == :sex
    true
  elsif rv == :capital_gain
    false
  elsif rv == :capital_loss
    false
  elsif rv == :hours_per_week
    false
  elsif rv == :native_country
    false
  else
    true
  end
end

puts dt.tree.inspect


#datum = { size: :large }
#classification = dt.classify(:color, datum)
#
#puts classification
