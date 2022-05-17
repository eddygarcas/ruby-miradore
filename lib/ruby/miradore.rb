# frozen_string_literal: true

require_relative 'miradore/version'
require 'active_support/isolated_execution_state'
require 'active_support/core_ext/hash/conversions'
require 'httparty'
require 'json'
require 'crack/xml'
require 'finest/builder'

module Ruby
  module Miradore

    def self.url
      {
        v1: 'https://%<subdomain>s.online.miradore.com/API/%<item>s/%<id>s?auth=%<auth>s&select=*,%<attribute>s&filters=%<filter>s&options=%<options>s',
        v2: 'https://%<subdomain>s.online.miradore.com/API/v2/Device/%<id>s/%<method>s'
      }
    end

    class Request
      include Finest::Builder
      include HTTParty
      format :json

      attr_writer :subdomain, :auth, :json

      def initialize(json = {})
        super json
        @subdomain ||= json[:subdomain]
        @auth ||= json[:auth]
        @json ||= json.to_json
        remove_instance_variable(:@subdomain) if @subdomain.nil?
        remove_instance_variable(:@auth) if @auth.nil?
      end

      #
      # This call will perform all GET calls regardless the API version that it's calling.
      # The version would be determined based on the superclass name.
      # If the superclass is Request the GET will call simple_v1 which will require the item which is class name.
      # otherwise will call to retrieve devices based on filters.
      #
      def all(**args)
        transform(
          Crack::XML.parse(
            http_method_v1(**args).body
          ).dig('Content', 'Items'), args
        )
      end

      def call(**args)
        transform(
          Crack::XML.parse(
            http_method_v1(**args.merge(attribute: 'ID')).body
          )['Content'], args
        )
      end

      def as_json(_options = nil)
        @json
      end


      def http_method_v1(**args)
        url = Miradore.url[:v1] % args.merge(
          subdomain: @subdomain || args[:subdomain],
          auth: args.fetch(:auth, @auth),
          id: args.fetch(:id, nil),
          item: self.class.to_s.split('::').last,
          attribute: args.fetch(:attribute, '*'),
          filter: args.fetch(:filter, nil),
          options: args.fetch(:options, nil)&.to_query&.sub('&', ',')
        )
        self.class.method(args.fetch(:method, :get)).call(url, body: args.fetch(:body, nil)&.to_xml(root: 'Content', skip_types: true))
      end

      def transform(res, args = {})
        return res if args.fetch(:skip_transform, false)

        args.merge!({ subdomain: args.fetch(:subdomain, @subdomain), auth: args.fetch(:auth, @auth) })
        if res.values.first.is_a?(Array)
          return res.values.first.map! do |e|
            self.class.new(args.merge(e.transform_keys(&:downcase)))
          end
        end
        self.class.new(args.merge(res.values.first&.transform_keys(&:downcase)))
      rescue StandardError
        { error: "#{self.class.to_s.split("::").last}(s) not found", status: :not_found }
      end

    end

    class Device < Request
      include HTTParty
      format :json
      headers "Content-Type": 'application/json'
      headers "Accept": 'application/json'

      def initialize(json = {})
        super json
      end

      def lock(**args)
        http_method(**args.merge(method: :post, id: id, action: __method__))
      end

      def lostmode(**args)
        if args[0]
          http_method(**args.merge(method: :post, id: id, action: __method__))
        else
          http_method(**args.merge(method: :delete, id: id, action: __method__))
        end
      end

      def reboot(**args)
        http_method(**args.merge(method: :post, id: id, action: __method__))
      end

      def wipe(**args)
        http_method(**args.merge(method: :post, id: id, action: __method__))
      end

      def location(**args)
        http_method(**args.merge(method: :get, action: __method__))
      end

      def family(**args)
        http_method(**args.merge(method: :put, action: :category))
      end

      def model(**args)
        http_method(**args.merge(method: :put, action: __method__))
      end

      def activate(**args)
        http_method(**args.merge(method: :post, action: __method__))
      end

      def retire(**args)
        http_method(**args.merge(method: :delete, id: id, action: nil))
      end

      def device_serial_number
        invdevice.serial_number || invdevice.hardware_serial_number
      end

      def device_model
        invdevice.marketing_name || invdevice.product_name
      end

      def online?
        onlinestatus.downcase.to_sym == :active
      end

      def phone?
        %w[Android iOS WindowsPhone].include?(platform)
      end

      def call(**args)
        http_method(**args)
      end

      private

      def http_method(**args)
        self.class.headers 'X-API-Key' => @auth || args[:auth]
        url = Miradore.url[:v2] % {
          subdomain: @subdomain || args[:subdomain],
          id: args.fetch(:id, id),
          method: args.fetch(:action, nil)
        }
        self.class.method(args.fetch(:method, nil)).call(url, body: args.fetch(:body, {}).to_json)
      rescue StandardError => e
        { error: e&.message || 'Error connecting to manager service provider', status: :not_found }
      end

    end

    class User < Request; end

    class Organization < Request; end

  end
end
