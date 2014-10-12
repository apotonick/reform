require 'forwardable'
require 'uber/inheritable_attr'
require 'uber/delegates'

require 'reform/representer'

module Reform
  # Gives you a DSL for defining the object structure and its validations.
  class Contract # DISCUSS: make class?
    extend Uber::Delegates

    extend Uber::InheritableAttr
    # representer_class gets inherited (cloned) to subclasses.
    inheritable_attr :representer_class
    self.representer_class = Reform::Representer.for(:form_class => self) # only happens in Contract/Form.
    # this should be the only mechanism to inherit, features should be stored in this as well.


    # each contract keeps track of its features and passes them onto its local representer_class.
    # gets inherited, features get automatically included into inline representer.
    # TODO: the representer class should handle that, e.g. in options (deep-clone when inheriting.)
    inheritable_attr :features
    self.features = {}


    RESERVED_METHODS = [:model, :aliased_model, :fields, :mapper] # TODO: refactor that so we don't need that.


    module PropertyMethods
      def property(name, options={}, &block)
        options[:as] = options.delete(:as)

        options[:coercion_type] = options.delete(:type)

        options[:features] ||= []
        options[:features] += features.keys if block_given?

        definition = representer_class.property(name, options, &block)
        setup_form_definition(definition) if block_given? or options[:form]

        create_accessor(options[:as] || name)
        definition
      end

      def collection(name, options={}, &block)
        options[:collection] = true

        property(name, options, &block)
      end

      def properties(names, options={})
        names.each { |name| property(name, options.dup) }
      end

      def setup_form_definition(definition)
        options = {
          # TODO: make this a bit nicer. why do we need :form at all?
          :form         => (definition.representer_module) || definition[:form], # :form is always just a Form class name.
          :pass_options => true, # new style of passing args
          :prepare      => lambda { |form, args| form }, # always just return the form without decorating.
          :representable => true, # form: Class must be treated as a typed property.
        }

        definition.merge!(options)
      end

    private
      def create_accessor(name)
        handle_reserved_names(name)

        delegates :fields, name, "#{name}=" # Uber::Delegates
      end

      def handle_reserved_names(name)
        raise "[Reform] the property name '#{name}' is reserved, please consider something else using :as." if RESERVED_METHODS.include?(name)
      end
    end
    extend PropertyMethods


    # FIXME: make AM optional.
    require 'active_model'
    include ActiveModel::Validations



    attr_accessor :model

    require 'reform/contract/setup'
    include Setup
    require 'reform/contract/validate'
    include Validate


    def errors # FIXME: this is needed for Rails 3.0 compatibility.
      @errors ||= Errors.new(self)
    end


  private
    attr_accessor :fields
    attr_writer :errors # only used in top form. (is that true?)

    def mapper
      self.class.representer_class
    end

    def self.register_feature(mod)
      features[mod] = true
    end

    # allows including representers from Representable, Roar or disposable.
    def self.inherit_module!(representer) # called from Representable::included.
      # representer_class.inherit_module!(representer)
      representer.representable_attrs.each do |dfn|
        next if dfn.name == "links" # wait a second # FIXME what is that?

        # TODO: remove manifesting and do that in representable, too!
        args = [dfn.name, dfn.instance_variable_get(:@options)] # TODO: dfn.to_args (inluding &block)

        property(*args) and next unless dfn.representer_module
        property(*args) { include dfn.representer_module } # nested.
      end
    end

    alias_method :aliased_model, :model


    # Keeps values of the form fields. What's in here is to be displayed in the browser!
    # we need this intermediate object to display both "original values" and new input from the form after submitting.
    class Fields < OpenStruct
      def initialize(properties, values={})
        fields = properties.inject({}) { |hsh, attr| hsh.merge!(attr => nil) }
        super(fields.merge!(values))  # TODO: stringify value keys!
      end
    end # Fields
  end
end

require 'reform/contract/errors'