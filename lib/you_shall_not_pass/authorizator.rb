require "callable"
require "fattr"

module YouShallNotPass
  class Authorizator
    def initialize(**attrs)
      attrs.each do |attr, value|
        send attr, value
      end
    end

    def can?(permission, **args)
      Array(policies.fetch(permission)).all? do |policy|
        Callable(policy).call(**args) == true
      end
    rescue KeyError => exception
      break_down_can(permission, exception, **args)
    end

    def break_down_can(permission, exception, **args)
      case permission
      when /_and_/
        permission.to_s.split("_and_").all? { |policy| can?(policy.to_sym, **args)}
      when /_or_/
        permission.to_s.split("_or_").any? { |policy| can?(policy.to_sym, **args)}
      when /\Anot_/
        policy = permission.to_s.gsub(/\Anot_/, "")
        ! can?(policy.to_sym, **args)
      else
        raise exception
      end
    end

    def perform_for(permission, **args)
      yield if can?(permission, **args)
    end

    def policies
      @policies ||= __set_policies__
    end

    private

    def __set_policies__
      the_policies = methods.grep(/_policies\z/).map {|name| send(name)}.each_with_object({}) do |curr, res|
        res.merge!(curr)
      end

      the_policies.merge!( self.class.__dsl_policies__.each_with_object({}) { |policy, h|
                            block =  policy.last
                            h[policy.first] = instance_eval(&block)
                          })

      the_policies
    end

    def self.__dsl_policies__
      @__dsl_policies__ ||= {}
    end

    def self.authorize(name, &block)
      __dsl_policies__[name] = block
    end

    def self.attribute(attr)
      fattr attr
    end
    private_class_method :attribute
  end
end
