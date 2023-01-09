require "sinatra"
require "tilt/erubis"
require "sinatra/content_for"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret123456789012345678901234567890123456789012345678901234567890'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

helpers do
  def display_currency(number)
    "$#{sprintf('%.2f', number)}"
  end

  def monthly_total(expenses)
    expenses.map { |expense| expense[:monthly_amt].to_f }.sum
  end

  def yearly_total(expenses)
    expenses.map { |expense| expense[:monthly_amt].to_f * 12 }.sum
  end

  def subtotal(category)
    category[:expenses].map do |expense|
      expense[:monthly_amt].to_f
    end.sum
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  gather_expense_data
  erb :index
end

get "/add" do
  @all_categories = @storage.all_categories
  erb :add
end

def error_for_expense_name(expense_name, expenses)
  if !(1..100).cover? expense_name.size
    "Expense name must be between 1 and 100 characters."
  elsif expenses.any? { |expense| expense[:expense_name] == expense_name }
    "Expense name must be unique."
  end
end

# create a new expense
post "/expense" do
  expense_name = params[:expense_name].strip
  @all_expenses = @storage.all_expenses
  error = error_for_expense_name(expense_name, @all_expenses)
  if error
    session[:message] = error
    status 422
    erb :add
  else
    expense_amount = params[:expense_amount].to_f
    @storage.create_new_expense(expense_name, expense_amount, params[:category])
    session[:message] = 'The expense has been created.'
    redirect "/"
  end
end

get "/yearly" do
  @yearly_flg = true
  gather_expense_data
  erb :index
end

def gather_expense_data
  @all_data = @storage.all_current_categories.each do |category|
    category[:expenses] = @storage.find_expenses(category[:category_id])
  end
  @all_expenses = @storage.all_expenses
end

def load_expense(id, all_expenses)
  expense = all_expenses.find { |exp| exp[:expense_id] == id }
  return expense if expense

  session[:error] = "The specified expense was not found."
  redirect "/"
end

get "/edit/:expense_id" do
  @expense_id = params[:expense_id].to_i
  @all_categories = @storage.all_categories
  @all_expenses = @storage.all_expenses
  @expense = load_expense(@expense_id, @all_expenses)
  erb :edit
end

post "/edit/:expense_id" do
  expense_id = params[:expense_id].to_i
  @all_expenses = @storage.all_expenses
  @expense = load_expense(expense_id, @all_expenses)

  @storage.update_expense(params[:expense_name], params[:expense_amount].to_f, params[:category], expense_id)
  session[:message] = 'The expense has been updated.'
  redirect "/"
end

# delete an expense
post "/delete/:expense_id" do
  expense_id = params[:expense_id].to_i

  @storage.delete_expense(expense_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/"
  else
    session[:success] = 'The expense has been deleted.'
    redirect "/"
  end
end