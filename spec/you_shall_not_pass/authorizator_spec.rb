require "spec_helper"
require "you_shall_not_pass/authorizator"

RSpec.describe YouShallNotPass::Authorizator do

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

  describe "#can?" do
    describe "no policies" do
      it "no policies defined" do
        expect { YouShallNotPass::Authorizator.new.can?(:whatever) }.to raise_error(KeyError)
      end
    end

    describe "can multiple" do
      let(:authorizator) { BasicAuthorizator.new }

      it "can_all? authorizes if all policies pass" do
        expect(authorizator.can_all?(:can, :can2)).to eql(true)
      end

      it "can_all? doesn't authorize unless all policies pass" do
        expect(authorizator.can_all?(:can, :cant)).to eql(false)
      end

      it "can_any? authorizes if any of the policies pass" do
        expect(authorizator.can_any?(:can, :cant)).to eql(true)
      end

      it "can_any? doesn't authorize if all the policies return false" do
        expect(authorizator.can_any?(:cant, :cant2)).to eql(false)
      end

      describe "with arguments" do
        let(:authorizator) { BasicAuthorizator.new }

        it do
          expect(authorizator.can_all?(:use_args, :can2, a: :a)).to eql(true)
        end

        it do
          expect(authorizator.can_all?(:use_args, :can, a: false)).to eql(false)
        end

        it do
          expect(authorizator.can_any?(:use_args, :can2, a: :a)).to eql(true)
        end

        it do
          expect(authorizator.can_all?(:use_args, :cant, a: false)).to eql(false)
        end
      end
    end

    describe "lambdas, procs and other callables" do
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

      it "allow lambda" do
        expect(authorizator.can?(:can_lambda)).to eql(true)
      end

      it "reject lambda" do
        expect(authorizator.can?(:cant_lambda)).to eql(false)
      end

      it "allow proc" do
        expect(authorizator.can?(:can_proc)).to eql(true)
      end

      it "reject proc" do
        expect(authorizator.can?(:cant_proc)).to eql(false)
      end

      it "allow action" do
        expect(authorizator.can?(:can_action)).to eql(true)
      end

      it "reject action" do
        expect(authorizator.can?(:cant_action)).to eql(false)
      end

      it "allow true" do
        expect(authorizator.can?(:can_true)).to eql(true)
      end

      it "reject false" do
        expect(authorizator.can?(:cant_false)).to eql(false)
      end

      it "reject false" do
        expect(authorizator.can?(:cant_false)).to eql(false)
      end

      it "allow true or false" do
        expect(authorizator.can?(:can_true_or_false)).to eql(true)
      end

      it "reject true and false" do
        expect(authorizator.can?(:cant_true_and_false)).to eql(false)
      end

      it "allow array" do
        expect(authorizator.can?(:can_array)).to eql(true)
      end

      it "reject array" do
        expect(authorizator.can?(:cant_array)).to eql(false)
      end
    end
  end

  describe "arguments" do
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

    it "allow lambda" do
      expect(authorizator.can?(:lambda, a: 1, b: 1)).to eql(true)
    end

    it "reject lambda" do
      expect(authorizator.can?(:lambda, a: 1, b: 2)).to eql(false)
    end

    it "allow proc" do
      expect(authorizator.can?(:proc, a: 1, b: 1)).to eql(true)
    end

    it "reject proc" do
      expect(authorizator.can?(:proc, a: 1, b: 2)).to eql(false)
    end

    it "allow splat" do
      expect(authorizator.can?(:splat, a: :a , b: :b , c: :c )).to eql(true)
    end

    it "reject splat" do
      expect(authorizator.can?(:splat, a: :a, b: :b, c: :a)).to eql(false)
    end
  end

  describe "performing" do
    describe "#perform_if" do
      let(:authorizator) { BasicAuthorizator.new }

      it "executes the block if it is allowed" do
        authorizator.perform_if(:can) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "doesn't execute the block if it isn't allowed" do
        authorizator.perform_if(:cant) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end

      it "passes the arguments" do
        authorizator.perform_if(:use_args, a: :a, b: :b) do
          @i_can = true
        end

        expect(@i_can).to eql(true)
      end
    end

    describe "#perform_unless" do
      let(:authorizator) { BasicAuthorizator.new }

      it "executes the block if it is allowed" do
        authorizator.perform_unless(:can) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end

      it "doesn't execute the block if it isn't allowed" do
        authorizator.perform_unless(:cant) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "passes the arguments" do
        authorizator.perform_unless(:use_args, a: :a, b: :b) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end
    end

    describe "perform multiple" do
      let(:authorizator) { BasicAuthorizator.new }

      it "#perform_if_all" do
        authorizator.perform_if_all(:can, :can2) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "#perform_unless_all" do
        authorizator.perform_unless_all(:can, :cant) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "not #perform_if_all" do
        authorizator.perform_if_all(:can, :cant) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end

      it "not #perform_unless_all" do
        authorizator.perform_unless_all(:can, :can2) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end

      it "#perform_if_any" do
        authorizator.perform_if_any(:can, :can2) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "#perform_unless_any" do
        authorizator.perform_unless_any(:cant, :cant2) do
          @i_can = true
        end

        expect(!! defined? @i_can).to eql(true)
      end

      it "not #perform_if_any" do
        authorizator.perform_if_any(:cant, :cant2) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end

      it "not #perform_unless_any" do
        authorizator.perform_unless_any(:can, :can2) do
          @i_can = true
        end

        expect(! defined? @i_can).to eql(true)
      end


    end
  end

  describe "conditional policies" do
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

    describe "regular policies vs conditional policies" do
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

      it "_and_" do
        expect(authorizator.can?(:one_and_two)).to eql(false)
      end

      it "_or_" do
        expect(authorizator.can?(:one_or_two)).to eql(false)
      end
    end
  end

  describe "#polices" do
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

    it do
      expect(YouShallNotPass::Authorizator.new.policies).to eql({})
    end

    let(:authorizator) { MergePolicies.new }

    it "merges all the policies" do
      @expected = {
        create_user: true,
        update_user: true,
        admin: true,
        editor: true,
        avatars: true,
        random_player: true,
      }

      expect(authorizator.policies).to eql(@expected)
    end
  end

  describe ".attribute" do
    class UserAuthorizator < YouShallNotPass::Authorizator
      attribute :user
      attribute :role

      def policies
        {
          something: proc { user == "Me" && role == :admin }
        }
      end
    end

    it "can initialize with attributes" do
      authorizator = UserAuthorizator.new(user: "Me", role: :admin)

      expect(authorizator.can?(:something)).to eql(true)
    end

    it "can initialize with attributes" do
      authorizator = UserAuthorizator.new(user: "Me", role: :user)

      expect(authorizator.can?(:something)).to eql(false)
    end
  end

  describe "dsl" do
    class DslAuthorizator < YouShallNotPass::Authorizator
      attribute :user
      attribute :pass

      policy(:true)  { true }
      policy(:false) { false }

      policy(:login) { |user:, pass:|  user == pass}

      policy(:use_args) { |**args| args.all? { |k, v| k == v }  }

    end

    let(:authorizator) { DslAuthorizator.new(user: "fede", pass: "fede") }

    it "authorizes true" do
      expect(authorizator.can?(:true)).to eql(true)
    end

    it "rejects false" do
      expect(authorizator.can?(:false)).to eql(false)
    end
    
    it do
      expect(authorizator.can?(:login, user: "u", pass: "u")).to eql(true)
    end

    it "creates with params" do
      expect(authorizator.can?(:use_args, a: :a, b: :b)).to eql(true)
    end

  end
end
