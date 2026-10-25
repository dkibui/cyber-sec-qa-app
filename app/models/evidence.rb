class Evidence < ApplicationRecord
  ALLOWED_TYPES = %w[image/png image/jpeg image/gif image/webp application/pdf].freeze
  MAX_SIZE = 10.megabytes

  belongs_to :finding
  has_one_attached :file

  validates :caption, presence: true
  validate :acceptable_file

  private

  def acceptable_file
    return errors.add(:file, "must be attached") unless file.attached?

    errors.add(:file, "must be a PNG, JPEG, GIF, WebP or PDF") unless ALLOWED_TYPES.include?(file.blob.content_type)
    errors.add(:file, "must be smaller than 10 MB") if file.blob.byte_size > MAX_SIZE
  end
end
