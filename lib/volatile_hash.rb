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
    attr_accessor :max_keys, :data, :keys

    def initialize(max_keys)
      self.max_keys = max_keys
      self.data     = {}
      self.keys     = []
    end

    def [](key)
      return nil unless data.has_key?(key)
      keys.unshift(keys.delete_at(keys.index(key)))
      data[key]
    end

    def []=(key, val)
      keys.unshift(key)
      data[key] = val
      if keys.length > max_keys
        keep, toss = keys[0..max_keys - 1], keys[max_keys..-1]
        self.keys = keep
        toss.each {|k| data.delete(k) }
      end
      val
    end

  end
end
