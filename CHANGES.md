## 0.2.5

* Allow proper form inheritance. When having `HitForm < SongForm < Reform::Form` the `HitForm` class will contain `SongForm`'s properties in addition to its own fields.
* `::model` is now inherited properly.

## 0.2.4

* Accessors for properties (e.g. `title` and `title=`) can now be overridden in the form *and* call `super`. This is extremely helpful if you wanna do "manual coercion" since the accessors are invoked in `#validate`. Thanks to @cj for requesting this.
* Inline forms now know their class name from the property that defines them. This is needed for I18N where `ActiveModel` queries the class name to compute translation keys. If you're not happy with it, use `::model`.

## 0.2.3

* `#form_for` now properly recognizes a nested form when declared using `:form` (instead of an inline form).
* Multiparameter dates as they're constructed from the Rails date helper are now processed automatically. As soon as an incoming attribute name is `property_name(1i)` or the like, it's compiled into a Date. That happens in `MultiParameterAttributes`. If a component (year/month/day) is missing, the date is considered `nil`.

## 0.2.2

* Fix a bug where `form.save do .. end` would call `model.save` even though a block was given. This no longer happens, if there's a block to `#save`, you have to manually save data (ActiveRecord environment, only).
* `#validate` doesn't blow up anymore when input data is missing for a nested property or collection.
* Allow `form: SongForm` to specify an explicit form class instead of using an inline form for nested properties.

## 0.2.1

* `ActiveRecord::i18n_scope` now returns `activerecord`.
* `Form#save` now calls save on the model in `ActiveRecord` context.
* `Form#model` is public now.
* Introduce `:empty` to have empty fields that are accessible for validation and processing, only.
* Introduce `:virtual` for read-only fields the are like `:empty` but initially read from the decorated model.
* Fix uniqueness validation with `Composition` form.
* Move `setup` and `save` logic into respective representer classes. This might break your code in case you overwrite private reform classes.


## 0.2.0

* Added nested property and collection for `has_one` and `has_many` relationships. . Note that this currently works only 1-level deep.
* Renamed `Reform::Form::DSL` to `Reform::Form::Composition` and deprecated `DSL`.
* `require 'reform'` now automatically requires Rails stuff in a Rails environment. Mainly, this is the FormBuilder compatibility layer that is injected into `Form`. If you don't want that, only require 'reform/form'.
* Composition now totally optional
* `Form.new` now accepts one argument, only: the model/composition. If you want to create your own representer, inject it by overriding `Form#mapper`. Note that this won't create property accessors for you.
* `Form::ActiveModel` no longer creates accessors to your represented models, e.g. having `property :title, on: :song` doesn't allow `form.song` anymore. This is because the actual model and the form's state might differ, so please use `form.title` directly.

## 0.1.3

* Altered `reform/rails` to conditionally load `ActiveRecord` code and created `reform/active_record`.

## 0.1.2

* `Form#to_model` is now delegated to model.
* Coercion with virtus works.

## 0.1.1

* Added `reform/rails` that requires everything you need (even in other frameworks :).
* Added `Form::ActiveRecord` that gives you `validates_uniqueness_with`. Note that this is strongly coupled to your database, thou.
* Merged a lot of cleanups from sweet @parndt <3.

## 0.1.0

* Oh yeah.