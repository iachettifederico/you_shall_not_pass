module YouShallNotPass
  class Policy
    include Callable
    attr_reader :user

    def initialize(authorizator)
      @authorizator = authorizator
      @user         = authorizator.user
    end

    def call(**options)
      policy(**options)
    end

    def policy(**args)
      raise NotImplementedError
    end
  end

end
