class UsersController < ApplicationController
  before_action :load_user, only: %i[show edit update destroy]
  before_action :authorize_user, except: %i[index new create show]

  def index
    @users = User.all
    @tags_with_counts = TagQuestion.with_counts
  end

  def new
    redirect_to root_url, alert: 'Вы уже залогинены' if current_user.present?
    @user = User.new
  end

  def create
    redirect_to root_url, alert: 'Вы уже залогинены' if current_user.present?
    @user = User.new(user_params)
    if @user.save
      # authenticate user after registration
      session[:user_id] = @user.id
      redirect_to root_url, notice: 'Пользователь успешно зарегистрирован!'
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'Данные обновлены'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to root_path, notice: 'Профиль удален, приходите к нам еще.'
  end

  def show
    @questions = @user.questions.order(created_at: :desc)
    @new_question = Question.new(user_id: @user.id)
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation,
                                 :name, :username, :avatar_url, :color)
  end

  def authorize_user
    reject_user unless @user == current_user
  end

  def load_user
    @user = User.find(params[:id])
  end
end
