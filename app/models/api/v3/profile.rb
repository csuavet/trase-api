module Api
  module V3
    class Profile < BaseModel
      belongs_to :context_node_type
    end
  end
end
