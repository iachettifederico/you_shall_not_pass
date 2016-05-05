require "spec_helper"
require "you_shall_not_pass/authorizator"

scope YouShallNotPass::Authorizator do

  class BasicAuthorizator < YouShallNotPass::Authorizator
    def policies
      {
       can:  true,
       can2:  true,
       cant: false,
       cant2: false,

       use_args: -> (**args) { args.all? { |k, v| k == v }  }
      }
    end
  end

  scope "#can?" do
    scope "no policies" do
      spec "no policies defined" do
        @ex = capture_exception(KeyError) do
          YouShallNotPass::Authorizator.new.can?(:whatever)
        end

        @ex.class == KeyError
      end
    end

    scope "can multiple" do
      let(:authorizator) { BasicAuthorizator.new }

      spec "can_all? authorizes if all policies pass" do
        authorizator.can_all?(:can, :can2)
      end

      spec "can_all? doesn't authorize unless all policies pass" do
        authorizator.can_all?(:can, :cant) == false
      end

      spec "can_any? authorizes if any of the policies pass" do
        authorizator.can_any?(:can, :cant)
      end

      spec "can_any? doesn't authorize if all the policies return false" do
        authorizator.can_any?(:cant, :cant2) == false
      end

      scope "with arguments" do
        let(:authorizator) { BasicAuthorizator.new }

        spec do
          authorizator.can_all?(:use_args, :can2, a: :a)
        end

        spec do
          authorizator.can_all?(:use_args, :can, a: false) == false
        end

        spec do
          authorizator.can_any?(:use_args, :can2, a: :a)
        end

        spec do
          authorizator.can_all?(:use_args, :cant, a: false) == false
        end
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

      class MyAuthorizator < YouShallNotPass::Authorizator
        def policies
          {
           can_lambda:  -> (*) { true },
           cant_lambda: -> (*) { false },

           can_proc:    proc { true },
           cant_proc:   proc { false },

           can_action:  Action.new(true),
           cant_action: Action.new(false),

           can_true_or_false:   true || false,
           cant_true_and_false: true && false,

           can_true:    true,
           cant_false:  false,


           can_array:   [ true, proc { true }, true ],
           cant_array:  [ true, false,         true ],
          }
        end
      end

      let(:authorizator) { MyAuthorizator.new }

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

      spec "reject false" do
        ! authorizator.can?(:cant_false)
      end

      spec "allow true or false" do
        authorizator.can?(:can_true_or_false)
      end

      spec "reject true and false" do
        ! authorizator.can?(:cant_true_and_false)
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
    class MyAuthorizatorWithArgs < YouShallNotPass::Authorizator
      def policies
        {
         lambda: -> (a:, b:) { a == b },
         proc:   proc { |a:, b:| a == b },

         splat:  -> (**args) { args.all? { |k, v| k == v} },
        }
      end
    end

    let(:authorizator) { MyAuthorizatorWithArgs.new }

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

  scope "performing" do
    scope "#perform_if" do
      let(:authorizator) { BasicAuthorizator.new }

      spec "executes the block if it is allowed" do
        authorizator.perform_if(:can) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "doesn't execute the block if it isn't allowed" do
        authorizator.perform_if(:cant) do
          @i_can = true
        end

        ! defined? @i_can
      end

      spec "passes the arguments" do
        authorizator.perform_if(:use_args, a: :a, b: :b) do
          @i_can = true
        end

        @i_can
      end
    end

    scope "#perform_unless" do
      let(:authorizator) { BasicAuthorizator.new }
      spec "executes the block if it is allowed" do
        authorizator.perform_unless(:can) do
          @i_can = true
        end

        ! defined? @i_can
      end

      spec "doesn't execute the block if it isn't allowed" do
        authorizator.perform_unless(:cant) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "passes the arguments" do
        authorizator.perform_unless(:use_args, a: :a, b: :b) do
          @i_can = true
        end

        ! defined? @i_can
      end
    end

    scope "perform multiple" do
      let(:authorizator) { BasicAuthorizator.new }

      spec "#perform_if_all" do
        authorizator.perform_if_all(:can, :can2) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "#perform_unless_all" do
        authorizator.perform_unless_all(:can, :cant) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "not #perform_if_all" do
        authorizator.perform_if_all(:can, :cant) do
          @i_can = true
        end

        ! defined? @i_can
      end

      spec "not #perform_unless_all" do
        authorizator.perform_unless_all(:can, :can2) do
          @i_can = true
        end

        ! defined? @i_can
      end

      spec "#perform_if_any" do
        authorizator.perform_if_any(:can, :can2) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "#perform_unless_any" do
        authorizator.perform_unless_any(:cant, :cant2) do
          @i_can = true
        end

        !! defined? @i_can
      end

      spec "not #perform_if_any" do
        authorizator.perform_if_any(:cant, :cant2) do
          @i_can = true
        end

        ! defined? @i_can
      end

      spec "not #perform_unless_any" do
        authorizator.perform_unless_any(:can, :can2) do
          @i_can = true
        end

        ! defined? @i_can
      end


    end
  end

  scope "conditional policies" do
    class NumberAuthorizator < YouShallNotPass::Authorizator
      def policies
        {
         one:   true,
         two:   true,
         three: false,
         four:  false,
        }
      end
    end

    let(:authorizator) { NumberAuthorizator.new }

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

    spec "allow not_" do
      authorizator.can?(:not_three)
    end

    spec "reject not_" do
      ! authorizator.can?(:not_one)
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
    class UserAuthorizator < YouShallNotPass::Authorizator
      attribute :user
      attribute :role

      def policies
        {
         something: proc { user == "Me" && role == :admin }
        }
      end
    end

    spec "can initialize with attributes" do
      authorizator = UserAuthorizator.new(user: "Me", role: :admin)

      authorizator.can?(:something)
    end

    spec "can initialize with attributes" do
      authorizator = UserAuthorizator.new(user: "Me", role: :user)

      ! authorizator.can?(:something)
    end
  end

  scope "dsl" do
    class DslAuthorizator < YouShallNotPass::Authorizator
      attribute :user
      attribute :pass

      policy(:true)  { true }
      policy(:false) { false }

      policy(:login) { |user:, pass:|  user == pass}

      policy(:use_args) { |**args| args.all? { |k, v| k == v }  }

    end

    let(:authorizator) { DslAuthorizator.new(user: "fede", pass: "fede") }

    spec "authorizes true" do
      authorizator.can?(:true)
    end

    spec "rejects false" do
      authorizator.can?(:false) == false
    end

    spec do
      authorizator.can?(:login, user: "u", pass: "u")
    end

    spec "creates with params" do
      authorizator.can?(:use_args, a: :a, b: :b)
    end

  end
end
