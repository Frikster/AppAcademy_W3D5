require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
require 'byebug'
class SQLObject
  def self.columns
    return @columns if @columns
    res = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      LIMIT 0
    SQL
    @columns = res[0].map{|col_name| col_name.to_sym}
  end

  def self.finalize!
    #TA Q: Why is the class type "Class" and not Cat in here?
    self.columns.each do |col|

      define_method(col){
        attributes[col]
      }

      define_method("#{col}="){ |new_val|
        attributes[col] = new_val
      }

    end
  end

  def self.table_name=(table_name)
    self.instance_variable_set("@table_name", table_name)
  end

  def self.table_name
    return @table_name if @table_name
    @table_name = self.instance_variable_get("@table_name")
    @table_name ||= "cats"
  end

  def self.all
    return @all if @all
    res = DBConnection.execute(<<-SQL)
    SELECT
      #{@table_name}.*
    FROM
      #{@table_name}
    SQL

    @all = self.parse_all(res)
  end

  def self.parse_all(results)
    results.map{|row| self.new(row)}
  end

  def self.find(id)
    res = DBConnection.execute(<<-SQL, id)
    SELECT
      #{@table_name}.*
    FROM
      #{@table_name}
    WHERE
      #{@table_name}.id = ?
    SQL
    self.parse_all(res).first
  end

  def initialize(params = {})
    params.each do |k,v|
      begin
        self.send("#{k}=", v)
      rescue
        raise "unknown attribute '#{k}'"
      end
    end
    @table_name = self.class.table_name
  end

  def attributes
    return @attributes if @attributes
    res = Hash.new
    self.class.columns.each do |col|
      res[col] = instance_variable_get("@#{col}")
    end
    res = {} if res.values.all?{|v| v.nil?}
    @attributes = res
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    p self.class
    atts = attributes.select{|k,v| !v.nil?}
    attribute_vals = atts.values
    attribute_keys = atts.keys.map{|att| att.to_s}.to_s
    .gsub('[', '(')
    .gsub(']', ')')
    .gsub('"', '')
    # attribute_vals = atts.values.to_s
    # .gsub('[', '(')
    # .gsub(']', ')')
    # .gsub('"', "'")

    DBConnection.execute(<<-SQL, *attribute_vals)
    INSERT INTO
      #{@table_name} #{attribute_keys}
    VALUES
      (#{(['?'] * atts.length).join(", ")})
    SQL
    self.attributes[:id] = self.class.all[-1].id
  end

  def update
    p self.class
    atts = attributes.select{|k,v| !v.nil?}
    attribute_vals = atts.values

    # .to_s
    # .gsub('[', '(')
    # .gsub(']', ')')
    # .gsub('"', '')

    input = atts.keys.zip(['?'] * atts.length)
    input = input.to_s.gsub("],","|").to_s.gsub("[","").gsub(":","").gsub("]]","").gsub("\"","").gsub(","," =").gsub("|",",")

    DBConnection.execute(<<-SQL, *attribute_vals)
    UPDATE
      #{@table_name}
    SET
      #{input}
    WHERE
      #{@table_name}.id = #{self.id}
    SQL
  end

  def save
    # ...
  end
end
