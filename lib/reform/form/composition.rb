require "reform/form/active_model"

class Reform::Form
  # Automatically creates a Composition object for you when initializing the form.
  module Composition
    def self.included(base)
      base.class_eval do
        extend Reform::Form::ActiveModel::ClassMethods # ::model.
        extend ClassMethods
      end
    end

    module ClassMethods
      #include Reform::Form::ActiveModel::ClassMethods # ::model.

      def model_class # DISCUSS: needed?
        rpr = representer_class
        @model_class ||= Class.new(Reform::Composition) do
          map_from rpr
        end
      end

      def property(name, options={})
        super
        delegate options[:on] => :@model
      end

      # Same as ActiveModel::model but allows you to define the main model in the composition
      # using +:on+.
      #
      # class CoverSongForm < Reform::Form
      #   model :song, on: :cover_song
      def model(main_model, options={})
        super

        composition_model = options[:on] || main_model

        delegate composition_model => :model # #song => model.song

        # FIXME: this should just delegate to :model as in FB, and the comp would take care of it internally.
        delegate [:persisted?, :to_key, :to_param] => composition_model  # #to_key => song.to_key

        alias_method main_model, composition_model # #hit => model.song.
      end
    end

    def initialize(models)
      composition = self.class.model_class.new(models)
      super(composition)
    end

    def to_nested_hash
      model.nested_hash_for(to_hash)  # use composition to compute nested hash.
    end
  end


  # TODO: remove me in 1.3.
  module DSL
    include Composition

    def self.included(base)
      warn "[DEPRECATION] Reform::Form: `DSL` is deprecated.  Please use `Composition` instead."

      base.class_eval do
        extend Composition::ClassMethods
      end
    end
  end
end
