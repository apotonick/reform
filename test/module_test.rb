require "test_helper"
require 'reform/form/coercion'

class ModuleInclusionTest < MiniTest::Spec
  module BandPropertyForm
    include Reform::Form::Module

    property :band do
      property :title

      validates :title, presence: true

      def id # gets mixed into Form, too.
        2
      end
    end

    def id # gets mixed into Form, too.
      1
    end

    property :name

    def name=(new_value)
      super("new#{new_value}")
    end

    validates :band, presence: true

    property :cool, type: Virtus::Attribute::Boolean # test coercion.
  end

  # TODO: test if works, move stuff into inherit_schema!
  module AirplaysPropertyForm
    include Reform::Form::Module

    collection :airplays do
      property :station
      validates :station, presence: true
    end
    validates :airplays, presence: true
  end


  # test:
  # by including BandPropertyForm into multiple classes we assure that options hashes don't get messed up by AM:V.
  class HitForm < Reform::Form
    include BandPropertyForm
  end

  class SongForm < Reform::Form
    include Coercion
    property :title

    include BandPropertyForm
  end


  let (:song) { OpenStruct.new(:band => OpenStruct.new(:title => "Time Again")) }

  # nested form from module is present and creates accessor.
  it { SongForm.new(song).band.title.must_equal "Time Again" }

  # methods from module get included.
  it { SongForm.new(song).id.must_equal 1 }
  it { SongForm.new(song).band.id.must_equal 2 }

  # validators get inherited.
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate({})
    form.errors.messages.must_equal({:band=>["can't be blank"]})
  end

  # coercion works
  it do
    form = SongForm.new(OpenStruct.new)
    form.validate({cool: "1"})
    form.cool.must_equal true
  end

  # includes setters
  it do
    form = HitForm.new(OpenStruct.new)
    form.validate({name: "1"})
    form.name.must_equal "new1"
  end

  # include a module into a module into a class :)
  module AlbumFormModule
    include Reform::Form::Module
    include BandPropertyForm

    property :name
    validates :name, :presence => true
  end

  class AlbumForm < Reform::Form
    include AlbumFormModule

    # pp heritage
    property :band, :inherit => true do
      property :label
      validates :label, :presence => true
    end
  end

  it do
    form = AlbumForm.new(OpenStruct.new(:band => OpenStruct.new))
    form.validate({"band" => {}})
    form.errors.messages.must_equal({:"band.title"=>["can't be blank"], :"band.label"=>["can't be blank"], :name=>["can't be blank"]})
  end


  describe "module with custom accessors" do
    module SongModule
      include Reform::Form::Module

      property :id    # no custom accessor for id.
      property :title # has custom accessor.

      module InstanceMethods
        def title
          super.upcase
        end
      end
    end

    class IncludingSongForm < Reform::Form
      include SongModule
    end

    let (:song) { OpenStruct.new(id: 1, title: "Instant Mash") }

    it do
      IncludingSongForm.new(song).id.must_equal 1
      IncludingSongForm.new(song).title.must_equal "INSTANT MASH"
    end
  end
end
