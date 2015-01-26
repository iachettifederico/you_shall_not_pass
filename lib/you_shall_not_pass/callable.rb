module YouShallNotPass

  module Callable
    def Callable( callable_or_not )
      callable_or_not.respond_to?(:call) ? callable_or_not : proc { |*args| callable_or_not }
    end

    def callable
      Callable( self )
    end

    def callable?
      self.respond_to? :call
    end
  end
end
