# Per-request state; ApplicationController sets the signed-in user so model
# callbacks can name who made a change.
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
