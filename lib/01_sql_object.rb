require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @data if @data
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    data = data.first.map! {|el| el.to_sym}
    @data = data
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.all
    data = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    self.parse_all(data)
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash)}
  end

  def self.find(id)
    data = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        "#{table_name}".id = ?
    SQL

    self.parse_all(data).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      sym = attr_name.to_sym
      unless self.class.columns.include?(sym)
        raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|attribute| self.send("#{attribute}")}
  end

  def insert
    col_names = self.class.columns.join(",")
    question_marks = (["?"] * (self.class.columns).length ).join(",")
    data = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        "#{self.class.table_name}" (#{col_names})
        VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map {|attr_name| "#{attr_name} = ?"}.join(",")
    data = DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        "#{self.class.table_name}"
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
