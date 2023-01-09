-- database budget

-- categories table
CREATE TABLE categories (
  id serial PRIMARY KEY,
  name text UNIQUE NOT NULL
);

INSERT INTO categories (name)
  VALUES ('Bills & Utilities'),
         ('Entertainment'),
         ('Food & Dining'),
         ('Gifts & Donations'),
         ('Health & Fitness'),
         ('Home'),
         ('Shopping'),
         ('Travel'),
         ('Transportation');

-- expenses table
CREATE TABLE expenses (
  id serial PRIMARY KEY,
  name text NOT NULL,
  monthly_amt decimal(10,2) NOT NULL,
  category_id integer NOT NULL REFERENCES categories (id)
);

INSERT INTO expenses (name, monthly_amt, category_id)
  VALUES ('Internet', 24, 1),
         ('Hulu', 83, 2),
         ('Groceries', 250, 3),
         ('SunStreet', 50, 1),
         ('Travel back to the US', 200, 8),
         ('Summer Travel', 200, 8),
         ('Christmas Travel', 150, 8);

