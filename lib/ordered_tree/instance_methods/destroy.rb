module OrderedTree
  module InstanceMethods
    module Destroy
      ## Destroy Methods

      # sends immediate children to the 'roots' list, then destroy's self
      def destroy_and_orphan_children
        self.class.transaction do
          orphan_children
          self.destroy
        end
      end

      # hands immediate children of to it's parent, then destroy's self
      def destroy_and_parent_adopts_children
        self.class.transaction do
          parent_adopts_children
          self.destroy
        end
      end

      def reorder_children
        self.class.transaction do
          children(true).each do |child|
            new_position = children.index(child) + 1
            child.update_attribute(order_column, new_position) if (child.position_in_list != new_position)
          end
        end
      end

      protected

      def destroy_descendants #:nodoc:
        # before_destroy callback (recursive)
        @old_parent = self.class.find(self).parent || 'root'
        self.children(true).each{|child| child.destroy}
      end
    end
  end
end
