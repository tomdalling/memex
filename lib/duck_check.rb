module DuckCheck
  extend self

  extend Forwardable
  def_delegators :default_registry,
    *%i(implements check! infringements)

  def default_registry
    @default_registry ||= Registry.new
  end

  def monkey_patch!
    Module.include(default_registry.class_methods_mixin)
  end

  private

    class Record
      value_semantics do
        implementor Module
        interface Module
      end
    end
end

require_relative 'duck_check/registry'
