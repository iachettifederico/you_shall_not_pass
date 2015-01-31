require "callable"

module YouShallNotPass
  class Authorizator
    def can?(permission, **args)
      Array(policies.fetch(permission)).all? do |policy|
        Callable(policy).call(**args) == true
      end
    end

    def policies
      {}
    end

  end

end
