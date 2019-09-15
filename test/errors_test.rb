require "test_helper"

# TODO:
# This test should, at some point soon, only test the `Errors` object and its
# Rails-ish API. No validation specifics, etc. to be tested here.

class ErrorsTest < MiniTest::Spec
  class AlbumForm < TestForm
    property :title
    validation do
      required(:title).filled
    end

    property :artists, default: []
    property :producer do
      property :name
    end

    property :hit do
      property :title
      validation do
        required(:title).filled
      end
    end

    collection :songs do
      property :title
      validation do
        required(:title).filled
      end
    end

    property :band do # yepp, people do crazy stuff like that.
      property :name
      property :label do
        property :name
        validation do
          required(:name).filled
        end
      end
      # TODO: make band a required object.

      validation do
        configure do
          config.messages_file = "test/fixtures/dry_error_messages.yml"

          def good_musical_taste?(value)
            value != "Nickelback"
          end
        end

        required(:name).filled(:good_musical_taste?)
      end
    end

    validation do
      required(:title).filled
      required(:artists).each(:str?)
      required(:producer).schema do
        required(:name).filled
      end
    end
  end

  let(:album_title) { "Blackhawks Over Los Angeles" }
  let(:album) do
    OpenStruct.new(
      title: album_title,
      hit: song,
      songs: songs, # TODO: document this requirement,
      band: Struct.new(:name, :label).new("Epitaph", OpenStruct.new),
      producer: Struct.new(:name).new("Sun Records")
    )
  end
  let(:song)  { OpenStruct.new(title: "Downtown") }
  let(:songs) { [song = OpenStruct.new(title: "Calling"), song] }
  let(:form)  { AlbumForm.new(album) }

  describe "#validate with invalid array property" do
    it do
      form.validate(
        title: "Swimming Pool - EP",
        band: {
          name: "Marie Madeleine",
          label: {name: "Ekler'o'shocK"}
        },
        artists: [42, "Good Charlotte", 43]
      ).must_equal false
      form.errors.messages.must_equal(artists: {0 => ["must be a string"], 2 => ["must be a string"]})
      form.errors.size.must_equal(1)
    end
  end

  describe "#errors without #validate" do
    it do
      form.errors.size.must_equal 0
    end
  end

  describe "blank everywhere" do
    before do
      form.validate(
        "hit" => {"title" => ""},
        "title" => "",
        "songs" => [{"title" => ""}, {"title" => ""}],
        "producer" => {"name" => ""}
      )
    end

    it do
      form.errors.messages.must_equal(
        title: ["must be filled"],
        "hit.title": ["must be filled"],
        "songs.title": ["must be filled"],
        "band.label.name": ["must be filled"],
        "producer.name": ["must be filled"]
      )
    end

    # it do
    #   form.errors.must_equal({:title  => ["must be filled"]})
    #   TODO: this should only contain local errors?
    # end

    # nested forms keep their own Errors:
    it { form.producer.errors.messages.must_equal(name: ["must be filled"]) }
    it { form.hit.errors.messages.must_equal(title: ["must be filled"]) }
    it { form.songs[0].errors.messages.must_equal(title: ["must be filled"]) }

    it do
      form.errors.messages.must_equal(
        title: ["must be filled"],
        "hit.title": ["must be filled"],
        "songs.title": ["must be filled"],
        "band.label.name": ["must be filled"],
        "producer.name": ["must be filled"]
      )
      form.errors.size.must_equal(5)
    end
  end

  describe "#validate with main form invalid" do
    it do
      form.validate("title" => "", "band" => {"label" => {name: "Fat Wreck"}}, "producer" => nil).must_equal false
      form.errors.messages.must_equal(title: ["must be filled"], producer: ["must be a hash"])
      form.errors.size.must_equal(2)
    end
  end

  describe "#validate with middle nested form invalid" do
    before { @result = form.validate("hit" => {"title" => ""}, "band" => {"label" => {name: "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal("hit.title": ["must be filled"]) }
    it { form.errors.size.must_equal(1) }
  end

  describe "#validate with collection form invalid" do
    before { @result = form.validate("songs" => [{"title" => ""}], "band" => {"label" => {name: "Fat Wreck"}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal("songs.title": ["must be filled"]) }
    it { form.errors.size.must_equal(1) }
  end

  describe "#validate with collection and 2-level-nested invalid" do
    before { @result = form.validate("songs" => [{"title" => ""}], "band" => {"label" => {}}) }

    it { @result.must_equal false }
    it { form.errors.messages.must_equal("songs.title": ["must be filled"], "band.label.name": ["must be filled"]) }
    it { form.errors.size.must_equal(2) }
  end

  describe "#validate with nested form using :base invalid" do
    it do
      result = form.validate("songs" => [{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      result.must_equal false
      form.errors.messages.must_equal("band.name": ["you're a bad person"])
      form.errors.size.must_equal(1)
    end
  end

  describe "#add" do
    let(:album_title) { nil }
    it do
      result = form.validate("songs" => [{"title" => "Someday"}], "band" => {"name" => "Nickelback", "label" => {"name" => "Roadrunner Records"}})
      result.must_equal false
      form.errors.messages.must_equal(title: ["must be filled"], "band.name": ["you're a bad person"])
      # add a new custom error
      form.errors.add(:policy, "error_text")
      form.errors.messages.must_equal(title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text"])
      # does not duplicate errors
      form.errors.add(:title, "must be filled")
      form.errors.messages.must_equal(title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text"])
      # merge existing errors
      form.errors.add(:policy, "another error")
      form.errors.messages.must_equal(title: ["must be filled"], "band.name": ["you're a bad person"], policy: ["error_text", "another error"])
    end
  end

  describe "correct #validate" do
    before do
      @result = form.validate(
        "hit"   => {"title" => "Sacrifice"},
        "title" => "Second Heat",
        "songs" => [{"title" => "Heart Of A Lion"}],
        "band"  => {"label" => {name: "Fat Wreck"}}
      )
    end

    it { @result.must_equal true }
    it { form.hit.title.must_equal "Sacrifice" }
    it { form.title.must_equal "Second Heat" }
    it { form.songs.first.title.must_equal "Heart Of A Lion" }
    it do
      skip "WE DON'T NEED COUNT AND EMPTY? ON THE CORE ERRORS OBJECT"
      form.errors.size.must_equal(0)
      form.errors.empty?.must_equal(true)
    end
  end

  describe "Errors#to_s" do
    before { form.validate("songs" => [{"title" => ""}], "band" => {"label" => {}}) }

    # to_s is aliased to messages
    it {
      skip "why do we need Errors#to_s ?"
      form.errors.to_s.must_equal "{:\"songs.title\"=>[\"must be filled\"], :\"band.label.name\"=>[\"must be filled\"]}"
    }
  end
end
