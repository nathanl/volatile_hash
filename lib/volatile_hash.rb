require 'time'
class VolatileHash
  def initialize(options)
    strategy = options.fetch(:strategy, :ttl)
    case strategy.to_sym
    when :ttl
      self.storage = TTL.new(options.fetch(:ttl, 3600), options.fetch(:refresh, false))
    when :lru
      self.storage = LRU.new(options.fetch(:max, 10))
    end
  end

  def [](key)
    storage[key]
  end

  def []=(key, val)
    storage[key] = val
  end

  private
  attr_accessor :storage

  class TTL
    attr_accessor :ttl, :data, :refresh

    def initialize(time, refresh)
      self.ttl     = time
      self.refresh = !!refresh
      self.data    = {}
    end

    def [](key)
      return nil unless data.has_key?(key)
      if (Time.now - data[key][:time]) > ttl
        data.delete(key)
        nil
      else
        data[key][:time] = Time.now if refresh
        data[key][:value]
      end
    end

    def []=(key, val)
      data[key] = {time: Time.now, value: val}
    end
  end

  class LRU
  end
end

class VolatileHash
end
