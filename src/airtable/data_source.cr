module Airtable

  @[Flags]
  enum DataSource
    Cache
    Backend

    def self.new(string_or_nil : String? = nil, int_or_symbol : Int32? | Symbol? = nil)
      string_or_nil.try { |i| return self.new(i.to_i) }

      if int_or_symbol.is_a?(Int32)
        return self.new(int_or_symbol)
      elsif int_or_symbol.is_a?(Symbol)
        return int_or_symbol
      end
    end
  end

end
