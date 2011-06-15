module OrderedTree
  module InstanceMethods
    module List
      ## List Read Methods

      # returns an array of the object's siblings, including itself
      #
      #   return is cached
      #   use self_and_siblings(true) to force a reload
      def self_and_siblings(reload = false)
        parent(reload) ? parent.children(reload) : self.class.roots(scope_condition)
      end

      # returns an array of the object's siblings, excluding itself
      #
      #   return is cached
      #   use siblings(true) to force a reload
      def siblings(reload = false)
        self_and_siblings(reload) - [self]
      end

      # returns object's position in the list
      #   the list will either be parent.children,
      #   or self.class.roots
      #
      #   i.e. self.position
      def position_in_list
        self[order_column]
      end

      ## List Update Methods

      # moves the item above sibling in the list
      #   defaults to the top of the list
      def move_above(sibling = nil)
        if sibling
          return if (!self_and_siblings(true).include?(sibling) || (sibling == self))
          if sibling.position_in_list > position_in_list
            move_to(sibling.position_in_list - 1)
          else
            move_to(sibling.position_in_list)
          end
        else
          move_to_top
        end
      end

      # move to the top of the list
      def move_to_top
        return if position_in_list == 1
        move_to(1)
      end

      # swap with the node above self
      def move_higher
        return if position_in_list == 1
        move_to(position_in_list - 1)
      end

      # swap with the node below self
      def move_lower
        return if self == self_and_siblings(true).last
        move_to(position_in_list + 1)
      end

      # move to the bottom of the list
      def move_to_bottom
        return if self == self_and_siblings(true).last
        move_to(self_and_siblings.last.position_in_list)
      end

      protected

      def check_list_changes #:nodoc:
        # before_update callback
        #
        # Note: to shift to another parent AND specify a position, use shift_to()
        # i.e. don't assign the object a new position, then new_parent << obj
        # this will end up at the bottom of the list.
        #
        if !self_and_siblings(true).include?(self)
          add_to_list_bottom
          @old_parent = self.class.find(self).parent || 'root'
        end
      end

      def reorder_old_list #:nodoc:
        # after_update and after_destroy callback
        # re-order the old parent's list
        if @old_parent == 'root'
          reorder_roots
        elsif @old_parent
          @old_parent.reorder_children
        end
      end

      private

      def add_to_list
        new_position = position_in_list if (1..self_and_siblings(true).size).include?(position_in_list.to_i)
        add_to_list_bottom
        move_to(new_position, true) if new_position
      end

      def add_to_list_bottom
        self[order_column] = self_and_siblings.size + 1
      end

      def move_to(new_position, on_create = false)
        if parent(true)
          scope = "#{foreign_key_column} = #{parent.id}"
        else
          scope = "#{foreign_key_column} = 0"
        end
        if new_position < position_in_list
          # moving from lower to higher, increment all in between
          # #{order_column} >= #{new_position} AND #{order_column} < #{position_in_list}
          self.class.transaction do
            self.class.update_all(
              "#{order_column} = (#{order_column} + 1)", "#{scope} AND (#{order_column} BETWEEN #{new_position} AND #{position_in_list - 1})"
            )
            if on_create
              self[order_column] = new_position
            else
              update_attribute(order_column, new_position)
            end
          end
        else
          # moving from higher to lower, decrement all in between
          # #{order_column} > #{position_in_list} AND #{order_column} <= #{new_position}
          self.class.transaction do
            self.class.update_all(
              "#{order_column} = (#{order_column} - 1)", "#{scope} AND (#{order_column} BETWEEN #{position_in_list + 1} AND #{new_position})"
            )
            update_attribute(order_column, new_position)
          end
        end
      end

      def reorder_roots
        self.class.transaction do
          self.class.roots(scope_condition).each do |root|
            new_position = self.class.roots(scope_condition).index(root) + 1
            root.update_attribute(order_column, new_position) if (root.position_in_list != new_position)
          end
        end
      end

    end
  end
end
