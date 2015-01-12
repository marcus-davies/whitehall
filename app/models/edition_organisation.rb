class EditionOrganisation < ActiveRecord::Base
  belongs_to :edition
  belongs_to :organisation, inverse_of: :edition_organisations

  validates :edition, :organisation, presence: true
end
