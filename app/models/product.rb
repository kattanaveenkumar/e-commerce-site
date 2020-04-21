class Product < ApplicationRecord
	has_many :product_categories, dependent: :destroy
	has_many :categories, through: :product_categories

	validates :name, :image, :description, presence: true

	has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

end
