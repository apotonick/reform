require 'test_helper'

class NestedFormTest < MiniTest::Spec
  class AlbumForm < Reform::Form
    property :title

    # class SongForm < Reform::Form
    #   property :title
    #   validates :title, :presence => true
    # end

    #form :hit, :class => SongForm
    property :hit do
      property :title
      validates :title, :presence => true
    end

    collection :songs do
      property :title
      validates :title, :presence => true
    end

    validates :title, :presence => true
  end

  # AlbumForm::collection :songs, :form => SongForm
  # should be: AlbumForm.new(songs: [Song, Song])

  let (:album) do
    OpenStruct.new(
      :title  => "Blackhawks Over Los Angeles",
      :hit    => song,
      :songs  => songs # TODO: document this requirement
    )
  end
  let (:song)  { OpenStruct.new(:title => "Downtown") }
  let (:songs) { [OpenStruct.new(:title => "Calling")] }
  let (:form)  { AlbumForm.new(album) }

  it "responds to #to_hash" do
    form.to_hash.must_equal({"hit"=>{"title"=>"Downtown"}, "title" => "Blackhawks Over Los Angeles", "songs"=>[{"title"=>"Calling"}]})
  end


  it "creates nested forms" do
    form.hit.must_be_kind_of Reform::Form
    form.songs.must_be_kind_of Reform::Form::Forms
  end
  describe "#initialize" do
    describe "with empty object" do
      let(:albumn_with_empty_openstruct) { AlbumForm.new(OpenStruct.new) }
      it "allows initialization with empty properties" do
        albumn_with_empty_openstruct
      end
      it "must support #validate when initialized with empty properties" do
        albumn_with_empty_openstruct.validate({})
        albumn_with_empty_openstruct.errors.messages.must_equal(:title=>["can't be blank"], :"hit.title"=>["can't be blank"], :"songs.title"=>["can't be blank"])
      end
      it "must support #validate with attributes when initialized with empty properties" do
        albumn_with_empty_openstruct.validate("hit"=>{"title"=>"Downtown"}, "title" => "Blackhawks Over Los Angeles", "songs"=>[{"title"=>"Calling"}])
        albumn_with_empty_openstruct.title.must_eql "Blackhawks Over Los Angeles"
        albumn_with_empty_openstruct.errors.messages.must_equal([])
      end
    end
    describe "with no argument (effectively nil)" do
      let(:albumn_with_no_model) { AlbumForm.new }
      it "allows initialization with nil object" do
        albumn_with_no_model
      end
      it "must support #validate when initialized with a nil object" do
        albumn_with_no_model.validate({})
        albumn_with_no_model.errors.messages.must_equal(:title=>["can't be blank"], :"hit.title"=>["can't be blank"], :"songs.title"=>["can't be blank"])
      end
      it "must support #validate with attributes when initialized with empty properties" do
        albumn_with_no_model.validate({"hit"=>{"title"=>"Downtown"}, "title" => "Blackhawks Over Los Angeles", "songs"=>[{"title"=>"Calling"}]})
        albumn_with_empty_openstruct.title.must_eql "Blackhawks Over Los Angeles"
        albumn_with_empty_openstruct.errors.messages.must_equal([])
      end
    end
  end


  describe "rendering" do
    it { form.title.must_equal "Blackhawks Over Los Angeles" }
    it { form.hit.title.must_equal "Downtown" }
    it { form.songs[0].title.must_equal "Calling" }
  end

  describe "#save" do
    before { @result = form.validate(
      "hit"   =>{"title" => "Sacrifice"},
      "title" =>"Second Heat",
      "songs" => [{"title" => "Scarified"}])
    }

    it "updates internal Fields" do
      data = {}

      form.save do |f, nested_hash|
        data[:title]        = f.title
        data[:hit_title]    = f.hit.title
        data[:first_title]  = f.songs.first.title
      end

      data.must_equal(:title=>"Second Heat", :hit_title => "Sacrifice", :first_title => "Scarified")
    end

    it "passes form instances in first argument" do
      frm = nil

      form.save { |f, hsh| frm = f }

      frm.must_equal form
      frm.title.must_be_kind_of String
      frm.hit.must_be_kind_of Reform::Form
      frm.songs.first.must_be_kind_of Reform::Form
    end

    it "returns nested hash with indifferent access" do
      nested = nil

      form.save do |hash, nested_hash|
        nested = nested_hash
      end

      nested.must_equal("title"=>"Second Heat", "hit"=>{"title"=>"Sacrifice"}, "songs"=>[{"title"=>"Scarified"}])

      nested[:title].must_equal "Second Heat"
      nested["title"].must_equal "Second Heat"
      nested[:hit][:title].must_equal "Sacrifice"
      nested["hit"]["title"].must_equal "Sacrifice"
    end

    it "pushes data to models" do
      form.save

      album.title.must_equal "Second Heat"
      song.title.must_equal "Sacrifice"
      songs.first.title.must_equal "Scarified"
    end

    describe "with invalid args" do
      it "allows empty collection values" do
        form.validate({})

        form.songs.size.must_equal 1
        form.songs[0].title.must_equal "Scarified"
      end
    end
  end

  # describe "with aliased nested form name" do
  #   let (:form) do
  #     Class.new(Reform::Form) do
  #       form :hit, :class => AlbumForm::SongForm, :as => :song
  #     end.new(OpenStruct.new(:hit => OpenStruct.new(:title => "")))
  #   end

  #   it "uses alias in errors" do
  #     form.validate({})
  #     form.errors.messages.must_equal({})
  #   end
  # end

  class ExplicitNestedFormTest < MiniTest::Spec
    let (:song)  { OpenStruct.new(:title => "Downtown") }
    let (:album) do
      OpenStruct.new(
        :title  => "Blackhawks Over Los Angeles",
        :hit    => song,
      )
    end
    let (:form) { AlbumForm.new(album) }

    class SongForm < Reform::Form
      property :title
      validates_presence_of :title
    end

    class AlbumForm < Reform::Form
      property :title

      property :hit, :form => SongForm #, :parse_strategy => :sync, :instance => true
    end


    it "allows rendering" do
      form.hit.title.must_equal "Downtown"
    end

    it { form.validate({"hit" => {"title" => ""}})
      form.errors[:"hit.title"].must_equal(["can't be blank"])
    }
  end

  class UnitTest < self
    it "keeps Forms for form collection" do
      form.send(:fields).songs.must_be_kind_of Reform::Form::Forms
    end

    describe "#validate" do
      it "keeps Form instances" do
        form.validate("songs"=>[{"title" => "Atwa"}])
        form.songs.first.must_be_kind_of Reform::Form
      end
    end
  end
end
