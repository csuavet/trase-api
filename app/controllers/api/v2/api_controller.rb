module Api
  module V2
    class ApiController < ApplicationController
      before_action :load_context, except: [:contexts, :place_data, :actor_data, :posts, :site_dive, :tweets]
      before_action :set_caching_headers
    end
  end
end
