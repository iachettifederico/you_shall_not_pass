require "callable"

module YouShallNotPass
  class Authorizator
    def can?(permission, **args)
      Array(policies.fetch(permission)).all? do |policy|
        Callable(policy).call(**args) == true
      end
    rescue KeyError => e
      if permission =~ /_and_/
        permission.to_s.split("_and_").all? { |policy| can?(policy.to_sym, **args)}
      elsif permission =~ /_or_/
        permission.to_s.split("_or_").any? { |policy| can?(policy.to_sym, **args)}
      else
        raise e
      end
      
    end

    def policies
      {}
    end

    def perform_for(permission, **args)
      yield if can?(permission, **args)
    end

  end

end
