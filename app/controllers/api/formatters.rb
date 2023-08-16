module API
  module Formatters
    module SuccessFormatter
      def self.call object, _env
        {status: "success", data: object}.to_json
      end
    end

    module ErrorFormatter
      def self.call message, _backtrace, _options, _env, _original_exception
        if message.is_a?(Hash)
          {status: "fail", data: message}.to_json
        else
          {status: "error", message: message}.to_json
        end
      end
    end
  end
end
