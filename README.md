# Reform

Decouple your models from forms. Reform gives you a form object with validations and nested setup of models. It is completely framework-agnostic and doesn't care about your database.

## Installation

Add this line to your Gemfile:

```ruby
gem 'reform'
```

## Defining Forms

Say you need a form for song requests on a radio station. Internally, this would imply associating `songs` table and the `artists` table. You don't wanna reflect that in your web form, do you?

```ruby
class SongRequestForm < Reform::Form
  include DSL

  property :title,  on: :song
  property :name,   on: :artist

  validates :name, :title, presence: true
end
```

The `::property` method allows defining the fields of the form. Using `:on` delegates this field to a nested object in your form.

__Note__: There is a convenience method `::properties` that allows you to pass an array of fields at one time.

## Using Forms

In your controller you'd create a form instance and pass in the models you wanna work on.

```ruby
def new
  @form = SongRequestForm.new(song: Song.new, artist: Artist.new)
end
```

You can also setup the form for editing existing items.

```ruby
def edit
  @form = SongRequestForm.new(song: Song.find(1), artist: Artist.find(2))
end
```

## Rendering Forms

Your `@form` is now ready to be rendered, either do it yourself or use something like `simple_form`.

```haml
= simple_form_for @form do |f|

  = f.input :name
  = f.input :title
```

## Validating Forms

After a form submission, you wanna validate the input.

```ruby
def create
  @form = SongRequestForm.new(song: Song.new, artist: Artist.new)

  #=> params: {song_request: {title: "Rio", name: "Duran Duran"}}

  if @form.validate(params[:song_request])
```

`Reform` uses the validations you provided in the form - and nothing else.


## Saving Forms

We provide a bullet-proof way to save your form data: by letting _you_ do it!

```ruby
  if @form.validate(params[:song_request])

    @form.save do |data, nested|
      #=> data:   <title: "Rio", name: "Duran Duran">
      #
      #   nested: {song:   {title: "Rio"},
      #            artist: {name: "Duran Duran"}}

      SongRequest.new(nested[:song][:title])
    end
```

While `data` gives you an object exposing the form property readers, `nested` already reflects the nesting you defined in your form earlier.

To push the incoming data to the models directly, call `#save` without the block.

```ruby
    @form.save  #=> populates song and artist with incoming data
                #   by calling @form.song.name= and @form.artist.title=.
```

## ActiveModel - Rails Integration

Reform offers ActiveModel support to easily make this accessible in Rails based projects.  You simply `include Reform::Form::ActiveModel` in your form object and the Rails specific code will be handled for you.

### Simple Integration
#### Form Class

You have to include a call to `model` to specifiy which is the main object of the form.

```ruby
class UserProfileForm < Reform::Form
  include Reform::Form::ActiveModel
  include DSL

  model :user, on: :user

  property :email,        on: :user
  properties [:gender, :age],   on: :profile

  validates :email, :gender, presence: true
  validates :age, numericality: true
end
```

#### View Form

The form becomes __very__ dumb as it knows nothing about the backend assocations or data binding to the database layer.  This simply takes input and passes it along to the controller as it should.

```erb
<%= form_for @form do |f| %>
  <%= f.email_field :email %>
  <%= f.input :gender %>
  <%= f.number_field :age %>
  <%= f.submit %>
<% end %>
```

#### Controller

In the controller you can easily create helpers to build these form objects for you.  In the create and update actions Reform allows you total control of what to do with the data being passed via the form. How you interact with the data is entirely up to you.

```ruby
class UsersController < ApplicationController

  def create
    @form = create_new_form
    if @form.validate(params[:user])
      @form.save do |data, map|
        new_user = User.new(map[:user])
        new_user.build_user_profile(map[:profile])
        new_user.save!
      end
    end
  end


  private
  def create_new_form
    UserProfileForm.new(user: User.new, profile: UserProfile.new)
  end
end
```

__Note__: this can also be used for the update action as well.

## Security

By explicitely defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.
