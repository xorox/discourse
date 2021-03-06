require 'spec_helper'
require_dependency 'distributed_memoizer'

describe DistributedMemoizer do

  before do
    $redis.del(DistributedMemoizer.redis_key("hello"))
    $redis.del(DistributedMemoizer.redis_lock_key("hello"))
    $redis.unwatch
  end

  # NOTE we could use a mock redis here, but I think it makes sense to test the real thing
  # let(:mock_redis) { MockRedis.new }

  def memoize(&block)
    DistributedMemoizer.memoize("hello", duration = 120, &block)
  end

  it "returns the value of a block" do
    memoize do
      "abc"
    end.should == "abc"
  end

  it "return the old value once memoized" do

    memoize do
      "abc"
    end

    memoize do
      "world"
    end.should == "abc"
  end

  it "memoizes correctly when used concurrently" do
    results = []
    threads = []

    5.times do
      threads << Thread.new do
        results << memoize do
          sleep 0.001
          SecureRandom.hex
        end
      end
    end

    threads.each(&:join)
    results.uniq.length.should == 1
    results.count.should == 5

  end

end
