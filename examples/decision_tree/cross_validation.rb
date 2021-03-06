#datum = { size: :large }
#classification = dt.classify(:color, datum)
#
#puts classification


require_relative 'decision_tree'

class CrossValidation

  def initialize(cols, options = {})
    @data = []
    @cols = cols
  end

  def setup
    yield self
    partition_sets
  end

  def add(datum)
    @data << datum
  end

  def run(target_rv)

    learner_and_errors = models.map do |columns|
      puts "Model size: #{columns.length}"
      ::Ps.reset
      learner = ::DecisionTree::Machine.new

      puts "loading..."
      learner.load(@training_set)

      puts "learning #{target_rv} for #{columns}"

      learner.learn(target_rv) do |rv|
        columns.include?(rv)
      end

      puts "checking for errors..."
      errors = @cross_validation_set.map do |datum|
        expected = [datum[target_rv]]
        actual = learner.classify(datum)
        expected != actual
      end
      
      error_rate = errors.count { |e| e == true }.to_f / errors.length
      puts "Error rate is #{error_rate.round(4)}"
      puts

      [learner, columns, error_rate]
    end

    puts "!!!!!!!!!!!! learner_and_errors !!!!!!!!!!!!!!"
    puts Hash[*learner_and_errors.flatten].values.inspect
    puts

    learner_and_errors.each do |learner, columns, _|
      # run model on test set for generalized error
      errors = @test_set.map do |datum|
        expected = [datum[target_rv]]
        actual = learner.classify(datum)
        expected != actual
      end

      error_rate = errors.count { |e| e == true }.to_f / errors.length

      puts "#{columns.inspect} error rate: #{error_rate.round(4)}"
    end
    puts

    # select model based on least model error
    learner, _ = learner_and_errors.min { |a, b| a[1] <=> b[1] }

    # run model on test set for generalized error
    errors = @test_set.map do |datum|
      expected = [datum[target_rv]]
      actual = learner.classify(datum)
      expected != actual
    end

    error_rate = errors.count { |e| e == true }.to_f / errors.length

    puts "Test set error rate: #{error_rate.round(4)}"
  end

  private

  def partition_sets
    sixty = (@data.length * 0.6).floor
    eighty = (@data.length * 0.8).floor

    @training_set = @data[0..sixty]
    @cross_validation_set = @data[sixty..eighty]
    @test_set = @data[eighty..@data.length]
  end

  def models
    [4,4].map { |n|
      @cols.reject { |c|
        [:fnlwgt, :education_num, :native_country].include?(c)
      }.sample(n)
    }
  end

end
