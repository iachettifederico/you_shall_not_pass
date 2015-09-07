module YouShallNotPass
  class Policy
    def initialize(authorizator)
      @authorizator = authorizator
    end

    def call(**options)
      policy(**options)
    end

    def policy(**args)
      raise NotImplementedError
    end
  end

end
