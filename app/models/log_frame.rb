# frozen_string_literal: true

#
# Models log frames linked to an active resource.
#
class LogFrame < ApplicationRecord
  #
  # Associations.
  #
  belongs_to :resource, inverse_of: :log_frames

  #
  # Lockbox encrypted attributes.
  #
  encrypts :frame_content
end
