class Person < ApplicationRecord
  belongs_to :manager, class_name: "Person", optional: true
  has_many :reports, class_name: "Person", foreign_key: :manager_id, inverse_of: :manager
  has_many :evidences, dependent: :destroy
  has_many :criteria, through: :evidences
  has_many :snapshots, dependent: :destroy
end
