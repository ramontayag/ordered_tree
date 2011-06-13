class Page < ActiveRecord::Base
  belongs_to :person
  ordered_tree
end
