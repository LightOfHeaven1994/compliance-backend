# frozen_string_literal: true

require 'base64'

module Insights
  module Api
    module Common
      # Helpers to handle the b64 identity header.
      class IdentityHeader
        CERT_AUTH = 'cert-auth'

        def self.from_request(request)
          new(request.headers['X-RH-IDENTITY']) if request.headers['X-RH-IDENTITY']
        end

        def initialize(b64_identity)
          @b64_identity = b64_identity
        end

        delegate :present?, :blank?, to: :@b64_identity

        def valid?
          present? && entitled?
        end

        def content
          @content ||=
            begin
              JSON.parse(Base64.decode64(@b64_identity))
            rescue JSON::ParserError
              {}
            end
        end

        def identity
          content['identity']
        end

        def owner_id
          identity['system']['cn']
        end

        def raw
          @b64_identity
        end

        def org_id
          identity&.dig('org_id')
        end

        def entitlements
          content['entitlements']
        end

        def entitled?
          entitlements&.dig('insights', 'is_entitled')
        end

        def auth_type
          identity&.dig('auth_type')
        end

        def cert_based?
          auth_type == CERT_AUTH
        end
      end
    end
  end
end
