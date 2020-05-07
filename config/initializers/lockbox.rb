# frozen_string_literal: true

#
# Load Lockbox master key for encryption
#
Lockbox.master_key = Rails.application.credentials.lockbox_master_key
