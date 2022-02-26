require "decoder_service"

class DecoderController < ApplicationController
  def show
    decoder = ::DecoderService.new
    @encoded_string = decoder.encode(params.permit(message: [:name]).dig(:message, :name) || "")
  end
end
