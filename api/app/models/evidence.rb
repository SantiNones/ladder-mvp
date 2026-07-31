class Evidence < ApplicationRecord
  belongs_to :person
  belongs_to :criterion
  belongs_to :author, class_name: "Person"
end
