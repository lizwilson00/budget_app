require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret123456789012345678901234567890123456789012345678901234567890'
  set :erb, :escape_html => true
end

before do
  session[:expenses] ||= []
  @categories = { "bills": "Bills & Utilities",
                  "entertainment": "Entertainment",
                  "food": "Food & Dining",
                  "gifts": "Gifts & Donations",
                  "health": "Health & Fitness",
                  "home": "Home",
                  "shopping": "Shopping",
                  "travel": "Travel",
                  "transportation": "Transportation" 
                }
end

helpers do
  def categories_hash
    cat_hash = {}
    @categories.each do |cat, category_name|
      sort_expenses(session[:expenses]).each do |expense|
        if expense[:category] == cat.to_s
          cat_hash.key?(category_name) ? cat_hash[category_name] << expense : cat_hash[category_name] = [expense]
        end
      end
    end
    cat_hash
  end

  def display_currency(number)
    "$#{sprintf('%.2f', number)}"
  end

  def monthly_total(expenses)
    expenses.map { |expense| expense[:amount] }.sum
  end

  def yearly_total(expenses)
    expenses.map { |expense| expense[:amount] * 12 }.sum
  end

  def sort_expenses(expenses)
    expenses.sort_by { |expense| expense[:name] }
  end

  def subtotal(category_name)
    short_cat_name = @categories.key(category_name).to_s
    session[:expenses].map do |expense|
      expense[:category] == short_cat_name ? expense[:amount] : 0
    end.sum
  end
end

get "/" do
  @yearly_flg = false
  erb :index
end

get "/add" do
  erb :add
end

def error_for_expense_name(expense_name)
  if !(1..100).cover? expense_name.size
    "Expense name must be between 1 and 100 characters."
  elsif session[:expenses].any? { |expense| expense[:name] == expense_name }
    "Expense name must be unique."
  end
end

def next_expense_id(expenses)
  max = expenses.map { |expense| expense[:expense_id] }.max || 0
  max + 1
end

# create a new expense
post "/expense" do
  expense_name = params[:expense_name].strip

  error = error_for_expense_name(expense_name)
  if error
    session[:message] = error
    status 422
    erb :add
  else
    expense_id = next_expense_id(session[:expenses])
    expense_amount = params[:expense_amount].to_f
    session[:expenses] << { expense_id: expense_id, name: expense_name, category: params[:category], amount: expense_amount }
    session[:message] = 'The expense has been created.'
    redirect "/"
  end
end

get "/yearly" do
  @yearly_flg = true
  erb :index
end

def load_expense(id)
  expense = session[:expenses].find { |exp| exp[:expense_id] == id }
  return expense if expense

  session[:error] = "The specified expense was not found."
  redirect "/"
end

get "/edit/:expense_id" do
  @expense_id = params[:expense_id].to_i
  @expense = load_expense(@expense_id)
  
  erb :edit
end

post "/edit/:expense_id" do
  expense_id = params[:expense_id].to_i
  @expense = load_expense(expense_id)

  @expense[:name] = params[:expense_name]
  @expense[:category] = params[:category]
  @expense[:amount] = params[:expense_amount].to_f
  session[:message] = 'The expense has been updated.'
  redirect "/"
end

# delete an expense
post "/delete/:expense_id" do
  expense_id = params[:expense_id].to_i

  session[:expenses].reject! { |expense| expense[:expense_id] == expense_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/"
  else
    session[:success] = 'The expense has been deleted.'
    redirect "/"
  end
end