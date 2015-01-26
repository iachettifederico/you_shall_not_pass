require "you_shall_not_pass/callable"
module YouShallNotPass
  class Authorizator
    include Callable

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def can_all?(action, **options, &block)
      available_policies = Array(policies[action.to_sym])
      can = available_policies.any? && available_policies.all? do |policy|
        Callable(policy).call(**options)
      end

      if block_given?
        yield if can
      else
        can
      end
    end
    alias :can? :can_all?

    def can_any?(action, **options, &block)
      available_policies = Array(policies[action.to_sym])
      can = available_policies.any? && available_policies.any? do |policy|
        Callable(policy).call(**options)
      end

      if block_given?
        yield if can
      else
        can
      end
    end

    def policies
      @policies ||= methods.grep(/_policies\Z/).map {|name| send(name)}.each_with_object({}) do |curr, res|
        res.merge!(curr)
      end
    end

    private

    def get_policies
      if policies_dir
        entries  = Dir.new(policies_dir).entries
        policy_files = entries.grep(/_policy.rb/)
          .map { |p|
          p["_policy.rb"] = ""
          policy_class = "#{p.camelize}Policy".constantize
          [p.to_sym, policy_class.new(self)]
        }.to_h
      else
        Hash.new
      end
    end

    def self.set_policies_dir(dir)
      @policies_dir = dir
    end

    def self.policies_dir
      @policies_dir
    end

    def policies_dir
      self.class.policies_dir
    end
  end

end
