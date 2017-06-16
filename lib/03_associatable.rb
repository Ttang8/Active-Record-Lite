require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    if @class_name == 'Human'
      return 'humans'
    end
      @class_name.downcase.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = (name.to_s + "_id").to_sym
    @class_name = name.to_s.camelcase
    @primary_key = :id
    options.each do |key, value|
      case key
      when :foreign_key
        @foreign_key = value
      when :class_name
        @class_name = value
      when :primary_key
        @primary_key = value

      end
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = (self_class_name.downcase + "_id").to_sym
    @class_name = name.singularize.capitalize
    @primary_key = :id
    options.each do |key, value|
      case key
      when :foreign_key
        @foreign_key = value
      when :class_name
        @class_name = value
      when :primary_key
        @primary_key = value
      end
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    option = BelongsToOptions(name, options)
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end
