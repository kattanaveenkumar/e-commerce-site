class Product < ApplicationRecord
	has_many :product_categories, dependent: :destroy
	has_many :categories, through: :product_categories

	validates :name, :image, :description

	has_attached_file :image,
										:url => "/attachments/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/products/attachments/:id/:style/:basename.:extension"
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

end
