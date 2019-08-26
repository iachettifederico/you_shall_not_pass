require "callable"

module YouShallNotPass
  class Authorizator
    def initialize(**attrs)
      attrs.each do |attr, value|
        send "#{attr}=", value
      end
    end

    def can?(permission, **args)
      Array(policies.fetch(permission)).all? do |policy|
        Callable(policy).call(**args) == true
      end
    end

    def can_all?(*permissions, **args)
      permissions.all? { |permission| can?(permission, **args)}
    end

    def can_any?(*permissions, **args)
      permissions.any? { |permission| can?(permission, **args)}
    end

    def perform_if(permission, **args)
      yield if can?(permission, **args)
    end

    def perform_unless(permission, **args)
      yield unless can?(permission, **args)
    end

    def perform_if_all(*permissions, **args)
      yield if can_all?(*permissions, **args)
    end

    def perform_unless_all(*permissions, **args)
      yield unless can_all?(*permissions, **args)
    end

    def perform_if_any(*permissions, **args)
      yield if can_any?(*permissions, **args)
    end

    def perform_unless_any(*permissions, **args)
      yield unless can_any?(*permissions, **args)
    end

    def policies
      @policies ||= __set_policies__
    end

    private

    def self.policy(name, &block)
      __dsl_policies__[name] = proc { block }
    end

    def self.attribute(attr)
      attr_accessor attr
    end
    private_class_method :attribute

    def __set_policies__
      __method_policies__.merge!(__dsl_policies__)
    end

    def __method_policies__
      methods.grep(/_policies\z/).
        each_with_object({}) { |name, res| res.merge!(send(name)) }
    end

    def __dsl_policies__
      self.class.__dsl_policies__. each_with_object({}) { |(name, value), res|
        res[name] = instance_eval(&value)
      }
    end

    def self.__dsl_policies__
      @__dsl_policies__ ||= {}
    end
  end
end
