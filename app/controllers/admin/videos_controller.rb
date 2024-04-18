class Admin::UsersController < Admin::BaseController
    before_action :set_user, only: %i[edit update show destroy]
    
end