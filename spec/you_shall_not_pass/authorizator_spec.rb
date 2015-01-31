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

        def call
          @val
        end
      end

      class MyAuthenticator < YouShallNotPass::Authorizator
        def policies
          {
            can_lambda:  -> { true },
            cant_lambda: -> { false },

            can_proc:    proc { true },
            cant_proc:   proc { false },

            can_action:  Action.new(true),
            cant_action: Action.new(false),

            can_true:    true,
            cant_false:  false,

            can_array:   [true, true, true],
            cant_array:  [true, false, true],
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

  scope "#polices" do
  end
end
