class Criterion < ApplicationRecord
  has_many :evidences, dependent: :destroy
end
