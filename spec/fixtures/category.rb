class Category < ActiveRecord::Base
  ordered_tree :primary_key => :alt_id
end
