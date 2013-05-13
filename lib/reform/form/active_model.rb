require 'reform/form'

module Reform::Form::ActiveModel
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def model(*args)
      @model_options  = args  # FIXME: make inheritable!
      main_model      = args.last[:on]

      delegate main_model, :to => :model  # #song => model.song
      delegate :persisted?, :to_key, :to_param, :to => main_model  # #to_key => song.to_key

      alias_method args.first, main_model # #hit => model.song.
    end

    def property(name, options={})
      delegate options[:on], :to => :model
      super
    end

    def model_name
      ::ActiveModel::Name.new(self, nil, @model_options.first.to_s.camelize)
    end
  end
end
