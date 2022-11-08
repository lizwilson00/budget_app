# budget_test.rb
ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../budget'

class BudgetTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def groceries_expense
    post "/expense", {expense_name: "groceries", category: "food", expense_amount: "50"}
  end

  def test_index 
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<p>Welcome to the Budget App!"
  end

  def test_add_expense_page
    get "/add"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h2>Add a new expense:"
    assert_includes last_response.body, %q(<option value="">--Please choose an option--</option>)
  end

  def test_add_new_expense_valid
    groceries_expense
    assert_equal 302, last_response.status
    assert_equal "The expense has been created.", session[:message]

    get "/"
    assert_includes last_response.body, "groceries"
  end

  def test_add_new_expense_empty_name
    post "/expense", {expense_name: "", category: "food", expense_amount: "50"}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Expense name must be between 1 and 100 characters."
  end

  def test_add_new_expense_same_name
    groceries_expense
    groceries_expense
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Expense name must be unique."
  end

  def test_add_two_new_expenses
    groceries_expense
    post "/expense", {expense_name: "eating out", category: "food", expense_amount: "100"}
    assert_equal 302, last_response.status
    assert_equal "The expense has been created.", session[:message]

    get "/"
    assert_includes last_response.body, "groceries"
    assert_includes last_response.body, "eating out"
    assert_includes last_response.body, "Dining Total"
  end

  def test_edit_expense
    groceries_expense
    get "/edit/1"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "groceries"
  end

  def test_edit_expense_invalid
    groceries_expense

    get "/edit/2"
    assert_equal 302, last_response.status
  end

  def test_edit_expense_new_name
    groceries_expense

    post "/edit/1", {expense_name: "Groceries", category: "food", expense_amount: "50"}
    assert_equal 302, last_response.status
    assert_equal "The expense has been updated.", session[:message]

    get "/"
    assert_includes last_response.body, "Groceries"
  end

  def test_delete_expense
    groceries_expense

    post "/delete/1"
    
    assert_equal 302, last_response.status

    get "/"
    assert_empty session[:expenses]
    refute_includes last_response.body, "Groceries"
  end

  def test_yearly_view
    groceries_expense
    
    get "/yearly"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "600"
  end
end