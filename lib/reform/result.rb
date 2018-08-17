module Reform
  class Contract < Disposable::Twin
    # Collects all native results of a form of all groups and provides
    # a unified API: #success?, #errors, #messages, #hints.
    # #success? returns validity of the branch.
    class Result
      def initialize(results, nested_results = []) # DISCUSS: do we like this?
        @results = results # native Result objects, e.g. `#<Dry::Validation::Result output={:title=>"Fallout", :composer=>nil} errors={}>`
        @failure = (results + nested_results).find(&:failure?) # TODO: test nested.
      end

      def failure?; !!@failure end # rubocop:disable Style/DoubleNegation

      def success?; !failure? end

      def errors(*args);   filter_for(:errors, *args) end

      def messages(*args); filter_for(:messages, *args) end

      def hints(*args);    filter_for(:hints, *args) end

      private

      def filter_for(method, *args)
        @results.collect { |r| r.public_send(method, *args) }
                .inject({}) { |hsh, errs| hsh.merge(errs) }
                .find_all { |k, v| v.is_a?(Array) } # filter :nested=>{:something=>["too nested!"]} #DISCUSS: do we want that here?
                .to_h
      end

      # Note: this class will be redundant in Reform 3, where the public API
      # allows/enforces to pass options to #errors (e.g. errors(locale: "br"))
      # which means we don't have to "lazy-handle" that with "pointers".
      # :private:
      class Pointer
        extend Forwardable

        def initialize(result, path)
          @result, @path = result, path
        end

        def_delegators :@result, :success?, :failure?

        def errors(*args);   traverse_for(:errors, *args) end

        def messages(*args); traverse_for(:messages, *args) end

        def hints(*args);    traverse_for(:hints, *args) end

        def advance(*path)
          path = @path + path.compact # remove index if nil.
          return if traverse(@result.errors, path) == {}

          Pointer.new(@result, path)
        end

        private

        def traverse(hash, path)
          path.inject(hash) { |errs, segment| errs[segment] || {} } # FIXME. test if all segments present.
        end

        def traverse_for(method, *args)
          traverse(@result.public_send(method, *args), @path) # TODO: return [] if nil
        end
      end
    end
  end
end
