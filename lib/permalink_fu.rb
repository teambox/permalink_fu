require 'yaml'

module PermalinkFu
  def has_permalink(attr_names = [], permalink_field = nil, options = {})
    if permalink_field.is_a?(Hash)
      options = permalink_field
      permalink_field = nil
    end
    ClassMethods.setup_permalink_fu_on self do
      self.permalink_attributes = Array(attr_names)
      self.permalink_field      = (permalink_field || 'permalink').to_s
      self.permalink_options    = {:unique => true, :min_length => 1}.update(options)
    end

    include InstanceMethods
  end

  class << self
    # This method does the actual permalink escaping.
    def escape(str, klass = nil)
      if Gem::Version.new("#{RUBY_VERSION}") < Gem::Version.new("1.9")
        require 'iconv'
        s = ClassMethods.decode(str)#.force_encoding("UTF-8")
        s = Iconv.iconv('ascii//ignore//translit', 'utf-8', s).to_s
      else
        s = ClassMethods.decode(str).encode("ascii")
      end
      s.gsub!(/[^\w_ \-]+/i,   '') # Remove unwanted chars.
      s.gsub!(/[ \-]+/i,      '-') # No more than one of the separator in a row.
      s.gsub!(/^\-|\-$/i,      '') # Remove leading/trailing separator.
      s.downcase!
      s = "#{klass}-#{s}" if klass && Integer(s) rescue s
      s = s.size < klass.classify.constantize.permalink_options[:min_length] ? ClassMethods.random_permalink : s
    end
  end

  # Contains class methods for ActiveRecord models that have permalinks
  module ClassMethods
    # Contains Unicode codepoints, loading as needed from YAML files
    CODEPOINTS = Hash.new { |h, k|
      h[k] = YAML::load_file(File.join(File.dirname(__FILE__), "data", "#{k}.yml"))
    }

    class << self
      def decode(string)
        string.gsub(/[^\x00-\x7f]/u) do |codepoint|
          begin
            CODEPOINTS["x%02x" % (codepoint.unpack("U")[0] >> 8)][codepoint.unpack("U")[0] & 255]
          rescue
            "_"
          end
        end
      end

      def random_permalink
        rand(Time.now.to_i**2).to_s(36)
      end
    end

    def self.setup_permalink_fu_on(base)
      base.extend self
      class << base
        attr_accessor :permalink_options
        attr_accessor :permalink_attributes
        attr_accessor :permalink_field
      end

      yield

      if base.permalink_options[:unique]
        base.before_validation :create_unique_permalink
      else
        base.before_validation :create_common_permalink
      end
      class << base
        alias_method :define_attribute_methods_without_permalinks, :define_attribute_methods
        alias_method :define_attribute_methods, :define_attribute_methods_with_permalinks
      end unless base.respond_to?(:define_attribute_methods_without_permalinks)
    end

    def define_attribute_methods_with_permalinks
      if (value = define_attribute_methods_without_permalinks) && self.permalink_field
        class_eval <<-EOV
          def #{self.permalink_field}=(new_value);
            write_attribute(:#{self.permalink_field}, new_value.blank? ? '' : PermalinkFu.escape(new_value.to_s, self.class.to_s));
          end
        EOV
      end
      value
    end
  end

  # This contains instance methods for ActiveRecord models that have permalinks.
  module InstanceMethods
  protected
    def create_common_permalink
      return unless should_create_permalink?
      if read_attribute(self.class.permalink_field).blank? || permalink_fields_changed?
        send("#{self.class.permalink_field}=", create_permalink_for(self.class.permalink_attributes))
      end

      # Quit now if we have the changed method available and nothing has changed
      permalink_changed = "#{self.class.permalink_field}_changed?"
      return if respond_to?(permalink_changed) && !send(permalink_changed)

      # Otherwise find the limit and crop the permalink
      limit   = self.class.columns_hash[self.class.permalink_field].limit
      base    = send("#{self.class.permalink_field}=", read_attribute(self.class.permalink_field)[0..limit - 1])
      [limit, base]
    end

    def create_unique_permalink
      limit, base = create_common_permalink
      return if limit.nil? # nil if the permalink has not changed or :if/:unless fail
      counter = 1
      # oh how i wish i could use a hash for conditions
      conditions = ["#{self.class.permalink_field} = ?", base]
      unless new_record?
        conditions.first << " and id != ?"
        conditions       << id
      end
      if self.class.permalink_options[:scope]
        [self.class.permalink_options[:scope]].flatten.each do |scope|
          value = send(scope)
          if value
            conditions.first << " and #{scope} = ?"
            conditions       << send(scope)
          else
            conditions.first << " and #{scope} IS NULL"
          end
        end
      end
      while self.class.exists?(conditions)
        length = 5
        random_string = rand(36**length - 36**(length-1)).to_s(36)
        suffix = "-#{random_string}"
        conditions[1] = "#{base[0..limit-suffix.size-1]}#{suffix}"
        send("#{self.class.permalink_field}=", conditions[1])
      end
    end

    def create_permalink_for(attr_names)
      str = attr_names.collect { |attr_name| send(attr_name).to_s } * " "
      (str.blank? || str.length < self.class.permalink_options[:min_length]) ? PermalinkFu::ClassMethods.random_permalink : str
    end

  private
    def should_create_permalink?
      if self.class.permalink_field.blank?
        false
      elsif self.class.permalink_options[:if]
        evaluate_method(self.class.permalink_options[:if])
      elsif self.class.permalink_options[:unless]
        !evaluate_method(self.class.permalink_options[:unless])
      else
        true
      end
    end

    # Don't even check _changed? methods unless :update is set
    def permalink_fields_changed?
      return false unless self.class.permalink_options[:update]
      self.class.permalink_attributes.any? do |attribute|
        changed_method = "#{attribute}_changed?"
        respond_to?(changed_method) ? send(changed_method) : true
      end
    end

    def evaluate_method(method)
      case method
      when Symbol
        send(method)
      when String
        eval(method, instance_eval { binding })
      when Proc, Method
        method.call(self)
      end
    end
  end
end

# Extend ActiveRecord functionality
ActiveRecord::Base.extend PermalinkFu
