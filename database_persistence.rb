require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "budget")
          end
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_categories
    sql = <<~SQL
      SELECT *
      FROM categories
      ORDER BY name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_categories_hash(tuple)
    end
  end

  def all_current_categories
    sql = <<~SQL
      SELECT DISTINCT c.*
      FROM categories c
      INNER JOIN expenses e
      on c.id = e.category_id
      ORDER BY name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_categories_hash(tuple)
    end
  end
  
  def find_expenses(category_id)
    sql = <<~SQL
      SELECT *
      FROM expenses
      WHERE category_id = $1
      ORDER BY name;
    SQL
    result = query(sql, category_id)
    result.map do |tuple|
      tuple_to_expenses_hash(tuple)
    end
  end
  
  def all_expenses
    sql = <<~SQL
      SELECT *
      FROM expenses
      ORDER BY name;
    SQL
    result = query(sql)
    result.map do |tuple|
      tuple_to_expenses_hash(tuple)
    end
  end

  def create_new_expense(expense_name, expense_amount, category_name)
    category_id = find_category_id(category_name)
    sql = "INSERT INTO expenses (name, monthly_amt, category_id) VALUES ($1, $2, $3)"
    query(sql, expense_name, expense_amount, category_id)
  end

  def update_expense(expense_name, expense_amount, category_name, expense_id)
    category_id = find_category_id(category_name)
    sql = "UPDATE expenses SET name = $1, monthly_amt = $2, category_id = $3 WHERE id = $4"
    query(sql, expense_name, expense_amount, category_id, expense_id)
  end

  def delete_expense(expense_id)
    sql = "DELETE FROM expenses WHERE id = $1"
    query(sql, expense_id)
  end

  def disconnect
    @db.close
  end

  private

  def tuple_to_categories_hash(tuple)
    { category_id: tuple["id"].to_i,
      category_name: tuple["name"] }
  end
  
  def tuple_to_expenses_hash(tuple)
    { expense_id: tuple["id"].to_i,
      expense_name: tuple["name"],
      monthly_amt: tuple["monthly_amt"],
      category_id: tuple["category_id"].to_i }
  end

  def find_category_id(category_name)
    sql = "SELECT id FROM categories WHERE name = $1"
    result = query(sql, category_name)
    result.field_values(:id).first.to_i
  end
end