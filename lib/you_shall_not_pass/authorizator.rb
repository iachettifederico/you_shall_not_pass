require "callable"

module YouShallNotPass
  class Authorizator
    def can?(permission)
      Array(policies.fetch(permission)).all? do |policy|
        Callable(policy).call == true
      end
    end

    def policies
      {}
    end

      end

end
