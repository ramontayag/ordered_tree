class Category < ActiveRecord::Base
  ordered_tree :primary_key => :alt_id, :scope => :person_id
end
