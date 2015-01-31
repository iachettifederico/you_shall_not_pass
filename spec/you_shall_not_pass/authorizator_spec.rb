require "spec_helper"
require "you_shall_not_pass/authorizator"

scope YouShallNotPass::Authorizator do
  scope "#can?" do
    scope "no policies" do
      spec "no policies defined" do
        @ex = capture_exception(KeyError) do
          YouShallNotPass::Authorizator.new.can?(:whatever)
        end

        @ex.class == KeyError
      end
    end

    scope "lambdas, procs and other callables" do
      class Action
        def initialize(val)
          @val = val
        end

        def call(*)
          @val
        end
      end

      class MyAuthenticator < YouShallNotPass::Authorizator
        def policies
          {
            can_lambda:  -> (*) { true },
            cant_lambda: -> (*) { false },

            can_proc:    proc { true },
            cant_proc:   proc { false },

            can_action:  Action.new(true),
            cant_action: Action.new(false),

            can_true:    true,
            cant_false:  false,

            can_array:   [ true, proc { true }, true ],
            cant_array:  [ true, false,         true ],
          }
        end
      end

      let(:authorizator) { MyAuthenticator.new }

      spec "allow lambda" do
        authorizator.can?(:can_lambda)
      end

      spec "reject lambda" do
        ! authorizator.can?(:cant_lambda)
      end

      spec "allow proc" do
        authorizator.can?(:can_proc)
      end

      spec "reject proc" do
        ! authorizator.can?(:cant_proc)
      end

      spec "allow action" do
        authorizator.can?(:can_action)
      end

      spec "reject action" do
        ! authorizator.can?(:cant_action)
      end

      spec "allow true" do
        authorizator.can?(:can_true)
      end

      spec "reject false" do
        ! authorizator.can?(:cant_false)
      end

      spec "allow array" do
        authorizator.can?(:can_array)
      end

      spec "reject array" do
        ! authorizator.can?(:cant_array)
      end
    end
  end

  scope "arguments" do
    class MyAuthenticatorWithArgs < YouShallNotPass::Authorizator
      def policies
        {
          lambda: -> (a:, b:) { a == b },
          proc:   proc { |a:, b:| a == b },

          splat:  -> (**args) { args.all? { |k, v| k == v} },
        }
      end
    end

    let(:authorizator) { MyAuthenticatorWithArgs.new }

    spec "allow lambda" do
      authorizator.can?(:lambda, a: 1, b: 1)
    end

    spec "reject lambda" do
      ! authorizator.can?(:lambda, a: 1, b: 2)
    end

    spec "allow proc" do
      authorizator.can?(:proc, a: 1, b: 1)
    end

    spec "reject proc" do
      ! authorizator.can?(:proc, a: 1, b: 2)
    end

    spec "allow splat" do
      authorizator.can?(:splat, a: :a , b: :b , c: :c )
    end

    spec "reject splat" do
      ! authorizator.can?(:splat, a: :a, b: :b, c: :a)
    end
  end

  scope "#perform_for" do
    class BasicAuthorizator < YouShallNotPass::Authorizator
      def policies
        {
          can:  true,
          cant: false,

          use_args: -> (**args) { args.all? { |k, v| k == v }  }
        }
      end
    end

    let(:authorizator) { BasicAuthorizator.new }

    spec "executes the block if it is allowed" do
      authorizator.perform_for(:can) do
        @i_can = true
      end

      !! defined? @i_can
    end

    spec "doesn't execute the block if it isn't allowed" do
      authorizator.perform_for(:cant) do
        @i_can = true
      end

      ! defined? @i_can
    end

    spec "passes the arguments" do
      authorizator.perform_for(:use_args, a: :a, b: :b) do
        @i_can = true
      end

      !! defined? @i_can
    end
  end

  scope "conditional policies" do
    class NumberAuthenticator < YouShallNotPass::Authorizator
      def policies
        {
          one:   true,
          two:   true,
          three: false,
          four:  false,
        }
      end
    end

    let(:authorizator) { NumberAuthenticator.new }

    spec "allow _and_" do
      authorizator.can?(:one_and_two)
    end

    spec "reject _and_" do
      ! authorizator.can?(:one_and_three)
    end

    spec "allow _or_" do
      authorizator.can?(:one_or_two)
    end

    spec "reject _or_" do
      ! authorizator.can?(:three_or_four)
    end

    spec "allow _and_or_" do
      authorizator.can?(:one_and_two_or_three)
    end

    spec "reject _and_or_" do
      ! authorizator.can?(:one_and_three_or_four)
    end

    scope "regular policies vs conditional policies" do
      class ConditionalAuthorizator < YouShallNotPass::Authorizator
        def policies
          {
            one: true,
            two: true,
            one_and_two: false,
            one_or_two: false
          }
        end
      end

      let(:authorizator) { ConditionalAuthorizator.new }

      spec "_and_" do
        ! authorizator.can?(:one_and_two)
      end

      spec "_or_" do
        ! authorizator.can?(:one_or_two)
      end
    end
  end

  scope "#polices" do
    class MergePolicies < YouShallNotPass::Authorizator
      def action_policies
        {
          create_user: true,
          update_user: true,
        }
      end

      def role_policies
        {
          admin: true,
          editor: true,
        }
      end

      def feature_policies
        {
          avatars: true,
          random_player: true,
        }
      end
    end

    spec do
      YouShallNotPass::Authorizator.new.policies == {}
    end

    let(:authorizator) { MergePolicies.new }
    
    spec "merges all the policies" do
      @expected = {
          create_user: true,
          update_user: true,
          admin: true,
          editor: true,
          avatars: true,
          random_player: true,
      }

      authorizator.policies == @expected
    end
  end

  scope ".attribute" do
    xspec do
    end
  end
end
