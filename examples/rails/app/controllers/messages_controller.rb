class MessagesController < ApplicationController
  include Rack::Stream::DSL

  def index
    render :nothing => true
  end

  def create
    render :json => {
      :text             => params[:text],
      :stream_transport => stream_transport
    }
  end
end