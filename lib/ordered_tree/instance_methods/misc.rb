module OrderedTree
  module InstanceMethods
    module Misc
      protected

      def foreign_key_column
        :"#{ordered_tree_config[:foreign_key]}"
      end

      def order_column
        :"#{ordered_tree_config[:order]}"
      end

      private

      def scope_condition
        return @scope_condition if defined?(@scope_condition)
        scope = self.class.ordered_tree_config[:scope]
        # If the scope is something like :person, then turn it into :person_id
        scope = :"#{scope}_id" if scope.is_a?(Symbol) && scope.to_s !~ /_id$/

        @scope_condition = if scope
          self.class.send(:sanitize_sql_hash_for_conditions, {scope => send(scope)})
        else
          "1=1"
        end
      end
    end
  end
end
