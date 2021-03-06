require "turbolinks/redirection"

class ApplicationController < ActionController::Base

  # Include turbolinks redirection methods
	include Turbolinks::Redirection

  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end

		def set_lesson
      @lesson_obj = Lesson.find_by_id(params[:lesson_id])
    end

end
