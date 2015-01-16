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
      puts (" " * (::PSpace.rv.size - rvs.size) * 2) + str
    end

    def learn(rv_target, &block)
      #RubyProf.start

      tkey, tval = split_rv(rv_target)
      rvs = ::PSpace.rv.reject { |rv| rv == tkey }

      @tree = create_node(rv_target, [], rvs, &block)

      #result = RubyProf.stop
      #printer = RubyProf::MultiPrinter.new(result)
      #printer.print(:path => "profile", :profile => "profile")
    end

    def create_node(rv_target, rv_parents, rand_vars, &block)
      tkey, tval = split_rv(rv_target)
      #pkey, pval = split_rv(rv_parent)

      # calculate all gains for remaining rand vars
      gains = rand_vars.reject do |key|
        !block.call(key)
      end.map do |key|
        # FIXME given key should use rv_parents
        [ key, ::PSpace.rv(tkey).given(key).infogain ]

        #[ key, ::PSpace.rv(tkey).given(rv_parents, key).infogain ]
      end
      putss rand_vars, "Gains: #{gains.to_s}"

      # find the next RV
      # use the rkey and remove it from list of candidate rand_vars
      rkey, _ = gains.max { |a, b| a[1] <=> b[1] }
      gains.delete_if { |ig| ig[0] == rkey }
      new_rv_parents = rv_parents.clone + [rkey]
      new_rand_vars = gains.map { |g| g[0] }

      # create node to attach to parent node
      putss rand_vars, "Using :#{rkey} for node with parents :#{rv_parents}"
      node = Node.new(rkey)

      # base case 1
      # TODO rkey should be rv_parents
      ent = ::PSpace.rv(tkey).given(rkey).entropy
      if ent == 0.0
        putss rand_vars,  "  Leaf node(#{rkey}) : Base Case 1"
        return node
      end

      # base case 2
      if gains.all? { |ig| ig[1] == 0.0 }
        putss rand_vars, "  Leaf node(#{rkey}) : Base Case 2"
        return node
      end

      # create a child node for every value of selected rkey
      ::PSpace.uniq_vals(rkey).each do |rval|
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
    true
  elsif rv == :education_num
    false
  elsif rv == :marital_status
    true
  elsif rv == :occupation
    false
  elsif rv == :relationship
    false
  elsif rv == :race
    true
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
