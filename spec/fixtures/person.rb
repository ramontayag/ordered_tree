class Person < ActiveRecord::Base
  has_many :pages
  ordered_tree
end
