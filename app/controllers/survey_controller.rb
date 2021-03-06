class SurveyController < ApplicationController
  before_action :find_survey, only: [:edit, :update, :destroy, :show, :question, :answer, :result]
  before_action :check_result_secret, only: [:edit, :update, :result]

  def index
  end

  def show
    session[:uuid] ||= SecureRandom.uuid
    @survey.collaborators.where(uuid: session[:uuid]).first_or_create
    redirect_to survey_question_path(@survey, @survey.questions.where(no: 1).first)
  end

  def finish
  end

  def create
    @survey = @group.surveys.build survey_params
    if @survey.save
      flash[:success] = 'アンケート作成しました。'
      respond_to do |fmt|
        fmt.json { render json: {is_success: 1, results: @survey} }
      end
    else
      respond_to do |fmt|
        fmt.json { render json: {is_success: 0} }
      end
    end
  end

  def edit
    set_questions
  end

  def update
    begin
      Surveys.transaction do
        params[:surveys].delete :hash_key
        params[:surveys][:questions_attributes].each.with_index(1) {|q, i| q[:no] = i}
        @survey.update! survey_params
      end
      redirect_to ({action: 'edit', hash_key: @survey.hash_key}), notice: '更新に成功しました。'
    rescue
      set_questions
      flash.now[:alert] = '更新に失敗しました。'
      render :edit
    end
  end

  def result
  end

  def destroy
    begin
      Surveys.transaction do
        @survey.destroy!
      end
      redirect_to ({controller: 'welcome', action: 'index'}), :notice => 'アンケートの削除に成功しました。'
    rescue
      set_questions
      flash.now[:alert] = '削除に失敗しました。'
      render :edit
    end
  end

  private
  def find_survey
    @survey = Surveys.current_group(request.subdomain).eager_load(:questions).find params[:id]
  end

  def check_result_secret
    head 404 if @survey.is_result_secret && @survey.hash_key != params[:hash_key]
  end

  def survey_params
    params.require(:surveys).permit(:name, :is_result_secret, :is_secret, :image, :remove_image,
      questions_attributes: [
        :id, :text, :type, :value, :no, :_destroy, :image, :image_cache, :remove_image
      ])
  end

  def set_questions
    gon.questions = @survey.questions.as_json({
      methods: [
        :error_class, :text_error_class, :value_error_class, :value_data,
        :resize_image_url, :type
      ],
    })
  end
end
