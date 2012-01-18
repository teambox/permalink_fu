class ClassModel < ActiveRecord::Base
  has_permalink :title
end

class SubClassHasPermalinkModel < ClassModel
  has_permalink [:title, :extra]
end

class SubClassNoPermalinkModel < ClassModel
end

class MockModel < ClassModel
  def self.exists?(conditions)
    if conditions[1] == 'foo'   || conditions[1] == 'bar' ||
      (conditions[1] == 'bar-2' && conditions[2] != 2)
      true
    else
      false
    end
  end

  has_permalink :title
end

class PermalinkChangeableMockModel < ClassModel
  def self.exists?(conditions)
    if conditions[1] == 'foo'
      true
    else
      false
    end
  end

  has_permalink :title

  def permalink_changed?
    @permalink_changed
  end

  def permalink_will_change!
    @permalink_changed = true
  end
end

class CommonMockModel < ClassModel
  def self.exists?(conditions)
    false # oh noes
  end

  has_permalink :title, :unique => false
end

class ScopedModel < ClassModel
  def self.exists?(conditions)
    if conditions[1] == 'foo' && conditions[2] != 5
      true
    else
      false
    end
  end

  has_permalink :title, :scope => :foo
end

class ScopedModelForNilScope < ClassModel
  def self.exists?(conditions)
    (conditions[0] == 'permalink = ? and foo IS NULL') ? (conditions[1] == 'ack') : false
  end

  has_permalink :title, :scope => :foo
end

class OverrideModel < ClassModel
  has_permalink :title

  def permalink
    'not the permalink'
  end
end

class ChangedWithoutUpdateModel < ClassModel
  has_permalink :title
  def title_changed?; true; end
end

class ChangedWithUpdateModel < ClassModel
  has_permalink :title, :update => true
  def title_changed?; true; end
end

class NoChangeModel < ClassModel
  has_permalink :title, :update => true
  def title_changed?; false; end
end

class IfProcConditionModel < ClassModel
  has_permalink :title, :if => Proc.new { |obj| false }
end

class IfMethodConditionModel < ClassModel
  has_permalink :title, :if => :false_method

  def false_method; false; end
end

class IfStringConditionModel < ClassModel
  has_permalink :title, :if => 'false'
end

class UnlessProcConditionModel < ClassModel
  has_permalink :title, :unless => Proc.new { |obj| false }
end

class UnlessMethodConditionModel < ClassModel
  has_permalink :title, :unless => :false_method

  def false_method; false; end
end

class UnlessStringConditionModel < ClassModel
  has_permalink :title, :unless => 'false'
end

class MockModelExtra < ClassModel
  has_permalink [:title, :extra]
end

class MinLength < ClassModel
  has_permalink :title, :min_length => 5
end
