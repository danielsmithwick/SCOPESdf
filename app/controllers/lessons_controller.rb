class LessonsController < ApplicationController

  before_action :authenticate_user!, except: [:index, :show]

  def index
    # Using lessons#index for now as the public view of all lesson
    # No authentication here
    @page = params[:page] || 1

    #@lessons = Lesson.page(@page).includes(:steps).to_array
    #TODO - pass page value along for pagination
    @lessons = Lesson.includes(:steps).to_a

  end

  def show

    # Using lessons#show for now as the public view
    # No authentication here
    @lesson = Lesson.includes(:steps).find(params[:id])

    # Fetch any specified section and turn it into a sym, otherwise :overview
    @secton = params[:section].to_sym || :overview

  end

  def new

    # We only need to create a new empty lesson with an id here
    # before handing it off to edit. An id might have been provided already.
    # TODO: look up a lesson that in the middle of being created, by session id
    lesson = LessonService.find_or_create_and_update(params[:id], nil, current_user)
    lesson.steps << Step.new(summary: "")

    if lesson.present?
      redirect_to edit_lesson_path(lesson)
    else
      raise lesson.errors
    end
  end

  def edit

    @current_user = current_user

    # Assign the @form_step var, casting as integer instead of a string
    @form_step = params[:form_step].present? ? params[:form_step].to_i : 1

    # Fetch the lesson by the provided id
    @lesson_obj = Lesson.find(params[:id])

    #pundit --
    authorize @lesson_obj, :update?

    # If the form step is 4, i.e. steps, we redirect to edit the first step created
    # when the lesson itself was created
    redirect_to edit_lesson_step_path(lesson_id: @lesson_obj.id, id: @lesson_obj.steps.first.id, form_step: @form_step) if @form_step == 4

    if params[:lesson].present?
      @lesson_obj = LessonService.find_or_create_and_update(params[:id], lesson_params, @current_user)
    end
    files_hash = {}
    files_hash.merge!({assessment_criteria_files: params[:assessment_criteria_files]}) if params[:assessment_criteria_files].present?
    files_hash.merge!({outcome_files: params[:outcome_files]}) if params[:outcome_files].present?

    LessonService.add_file_by_type_to_id(@lesson_obj.id, files_hash, @current_user) # should not be user first
    @lesson_obj.reload


    if @form_step == 4
      @steps = @lesson_obj.steps.order(:created_at).to_a
      unless @steps.present?
        @lesson_obj.steps << Step.new(summary: "")
        @lesson_obj.save!
        puts @lesson_obj.steps
        @steps = @lesson_obj.steps.to_a
      end
      @steps_array = @steps.map{|s| s.id}
    end


    # elsif params[:id].present? && params[:step].present? # making a step
    #   Step.find_or_create_and_update(nil, params[:id], step_param, User.first).set_files(params)


    @collections = CollectionTag.all.to_a.map{|x| x.name.titleize}
    @subjects = Subject.all.to_a.map{|x| x.name.titleize}
    @subjects = Subject.all
    @context = Context.all.to_a.map{|x| x.name.titleize}
    @contexts = Context.all
    @standards = Standard.name_array
    @standards_array = @lesson_obj.standards_array
    @difficulty_helper = DifficultyLevel.form_helper
    @teaching_range_helper = TeachingRange.inputRange

  end


  def update

    # Update the lesson
    @lesson_obj = LessonService.find_or_create_and_update(params[:id], lesson_params, User.first)

    # Redirect to the next step
    redirect_to edit_lesson_path(id: @lesson_obj.id, form_step: params[:form_step])

  end

  def publish
    # check to make sure current user is owner and make inactive
    # make sure passes validation
    render :json => {success: Lesson.find(params[:id]).publish!}, :status => 200
  end

  def delete
    # check to make sure current user is owner and make inactive
    render :json => {success: Lesson.find(params[:id]).hidden!}, :status => 200
  end

  def add_step
    @lesson = Lesson.first
    id = nil
    id = step_param[:id] if step_param[:id].present? # updates
    @step = Step.find_or_create_and_update(id, params[:id], step_param, User.first).set_files(params) # should not be user first
    render :json => {success: "OKEY", lesson: @step.id}, :status => 200
  end

  def delete_step
    r = Step.delete_and_update_sibilings(params[:step_id], params[:id], User.first) # should not be user first
    render :json => {success: r}, :status => 200
  end

  # ~~~~~~~~~~~~~~~
  # STEPS HERE
  # ~~~~~~~~~~~~~~~
  def set_steps
    step_params[:steps].map{|s|
      id = nil
      puts s.inspect
      id = s[:id] if s[:id].present?
      Step.find_or_create_and_update(id, params[:id], s, User.first).id # should not be user first
    }
    ids = Lesson.find(params[:id]).steps.order(:created_at).map{|x| x.id}
    render :json => {ids: ids}, :status => 200
  end
  def remove_step
    Step.delete_and_update_sibilings(step_param[:id], params[:id], User.first) # should not be user first
    ids = Lesson.find(params[:id]).steps.order(:created_at).map{|x| x.id}
    render :json => {ids: ids}, :status => 200
  end

  def draft

  end

  def file_upload
    @lesson = Lesson.find(params[:id])

    files_hash = {}
    files_hash.merge!({assessment_criteria_files: file_params[:files]}) if file_params[:attr] == "assessment_criteria_files"
    files_hash.merge!({outcome_files: file_params[:files]}) if file_params[:attr] == "outcome_files"
    puts "uploading files"
    puts files_hash.inspect

    LessonService.add_file_by_type_to_id(@lesson.id, files_hash, User.first) ## THIS NEEDS TO FUCKING CHANGE!! TODO --
    @lesson.reload

    returning = []


    if files_hash[:assessment_criteria_files].present?
      uploaded_acf = file_params[:files].each{|x|
        @lesson.find_carrier_wave_with_original_name(x.original_filename, :assessment_criteria)
      }
      for i in 0..uploaded_acf.count-1
        x = @lesson.assessment_criteria_files[i]
        @lesson.reload
        returning.push( JqUploaderService.convert_to_jq_upload(x, @lesson.id, "assessment_criteria") )
      end
    elsif files_hash[:outcome_files].present?
      uploaded_of = file_params[:files].each{|x|
        @lesson.find_carrier_wave_with_original_name(x.original_filename, :outcome_files)
      }
      puts uploaded_of.count
      for i in 0..uploaded_of.count-1
        @lesson.reload
        x = @lesson.outcome_files[i]
        returning.append (JqUploaderService.convert_to_jq_upload(x, @lesson.id, "outcome") )
      end
    end


    respond_to do |format|
      format.html {
        render :json => returning.to_json,
               :content_type => 'text/html',
               :layout => false
      }
      format.json {
        render :json => { :files => returning }
      }
    end
  end

  def file_upload_load
    @lesson = Lesson.find(params[:id])
    returning = []
    if file_params[:attr] == "assessment_criteria_files"
        @lesson.assessment_criteria_files.map{|x|
          returning.push( JqUploaderService.convert_to_jq_upload(x, @lesson.id, "assessment_criteria") )
        }
    elsif
      file_params[:attr] == "outcome_files"
        @lesson.outcome_files.map{|x|
          returning.push( JqUploaderService.convert_to_jq_upload(x, @lesson.id, "outcome") )
        }
    end

    respond_to do |format|
      format.html {
        render :json => returning.to_json,
               :content_type => 'text/html',
               :layout => false
      }
      format.json {
        render :json => { files: returning }, status: :created, location: @Uploaded
      }
    end
  end

  def remove_file_upload
    puts "prepping for delete"
    puts params.inspect
    @lesson = Lesson.find(params[:id])
    status = @lesson.removeFileWithName(remove_file_params[:attr].to_sym, remove_file_params[:name])
    puts "finished for delete"
    render :json => {status: status}, location: @Uploaded
  end



  # STEP FILES HERE
  def step_file_upload_load
    @lesson = Lesson.find(params[:id])
    @step = @lesson.steps.find(params[:step])

    returning = []

    if file_params[:attr] == "supporting_files"
      @step.supporting_files.map{|x|
        returning.push( JqUploaderService.convert_to_jq_upload_step(x, @lesson.id, @step.id, "supporting_files") )
      }
    elsif
    file_params[:attr] == "supporting_materials"
      @step.supporting_materials.map{|x|
        returning.push( JqUploaderService.convert_to_jq_upload_step(x, @lesson.id, @step.id, "supporting_materials") )
      }
    end

    puts "getting"
    puts returning.inspect

    respond_to do |format|
      format.html {
        render :json => returning.to_json,
               :content_type => 'text/html',
               :layout => false
      }
      format.json {
        render :json => { files: returning }, status: :created, location: @Uploaded
      }
    end
  end
  def step_file_upload
    @lesson = Lesson.find(params[:id])
    # return false unless @lesson.isAuthor?(calling_user.id)
    @step = @lesson.steps.find(params[:step])

    puts file_params.inspect

    files_hash = {}
    files_hash.merge!({supporting_files: file_params[:files]}) if file_params[:attr] == "supporting_files"
    files_hash.merge!({supporting_materials: file_params[:files]}) if file_params[:attr] == "supporting_materials"

    puts files_hash.inspect

    @step.add_file_through_hash(files_hash) # CHECK TO MAKE SURE CALLING USER IS AUTHOR OF
    @step.reload

    returning = []


    if files_hash[:supporting_files].present?
      uploaded_sF = file_params[:files].each{|x|
        @step.find_carrier_wave_with_original_name(x.original_filename, :supporting_files)
      }
      for i in 0..uploaded_sF.count-1
        @step.reload
        x = @step.supporting_files[i]
        returning.push( JqUploaderService.convert_to_jq_upload_step(x, @lesson.id, @step.id, "supporting_files") )
      end
    elsif files_hash[:supporting_materials].present?
      uploaded_of = file_params[:files].each{|x|
        @step.find_carrier_wave_with_original_name(x.original_filename, :supporting_materials)
      }
      puts uploaded_of.count
      for i in 0..uploaded_of.count-1
        @step.reload
        x = @step.supporting_materials[i]
        returning.push( JqUploaderService.convert_to_jq_upload_step(x, @lesson.id, @step.id, "supporting_materials") )
      end
    end

    respond_to do |format|
      format.html {
        render :json => returning.to_json,
               :content_type => 'text/html',
               :layout => false
      }
      format.json {
        render :json => { :files => returning }
      }
    end
  end

  def step_remove_file_upload
    puts "prepping for delete"
    puts params.inspect
    @lesson = Lesson.find(params[:id])
    # return false unless @lesson.isAuthor?(calling_user.id)
    @step = @lesson.steps.find(params[:step])
    status = @step.removeFileWithName(remove_file_params[:attr].to_sym, remove_file_params[:name])
    puts "finished for delete"
    render :json => {status: status}, location: @Uploaded
  end

  private

    def lesson_params
      params.require(:lesson).permit(:name, :topline, :summary, :description, :assessment_criteria, :state, :collection_tag, other_users_emails: [], learning_objectives: [], further_readings: [], outcome_links: [], associated_places_ids: [], standards: [:name, descriptions: []], grade_range: [:start, :end], subjects: [], difficulty_level: [:student, :educator], skills: [:name, :level], context: [], tags: [])
    end

    def step_params
      params.permit(steps: [:id, :name, :summary, :duration, :description, :supporting_images => [], :materials => [:number, :name], :tools => [], :supporting_material => [], :external_links => []]) #TODO - supporting materials vs materials... add materials
    end

    def step_param
      params.require(:step).permit(:id, :summary, :duration, materials: [:number, :name], tools: [], external_links:[])
    end

    def file_params # both lessons and steps
      params.permit(:id, :attr, :step, :assessment_criteria_files => [], :outcome_files => [], :supporting_materials => [], :supporting_files => [], files: [])
    end

    def remove_file_params
      params.permit(:name, :attr)
    end

end
