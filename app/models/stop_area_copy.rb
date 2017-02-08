# -*- coding: utf-8 -*-

class StopAreaCopy
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :source_id, :hierarchy, :area_type, :source, :copy

  validates_presence_of :source_id, :hierarchy, :area_type

  validates :hierarchy, inclusion: { in: %w(child parent) }


  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) } if attributes
    if self.area_type.blank? && self.source.present?
      self.source_id = self.source.id
      self.area_type = if self.hierarchy == "child"
                         Chouette::AreaType.list_children(self.referential_format, self.source.area_type)&.first&.underscore
                       else
                         Chouette::AreaType.list_parents(self.referential_format, self.source.area_type)&.first&.underscore
                       end
    end
  end

  def persisted?
    false
  end

  def source
    @source ||= Chouette::StopArea.find self.source_id
  end

  def copy
    @copy ||= self.source.duplicate
  end

  def copy_is_source_parent?
    self.hierarchy == "parent"
  end

  def copy_is_source_child?
    self.hierarchy == "child"
  end

  def copy_modfied_attributes
    { :name => self.source.name, # TODO: change ninoxe to avoid that !!!
      :area_type => self.area_type.camelcase,
      :registration_number => nil,
      :parent_id => copy_is_source_child? ? self.source_id : nil
    }
  end

  def source_modified_attributes
    return {} unless copy_is_source_parent?
    { :parent_id => self.copy.id
    }
  end

  def save
    begin
      if self.valid?
        Chouette::StopArea.transaction do
          copy.update_attributes copy_modfied_attributes
          if copy.valid?
            unless source_modified_attributes.empty?
              source.update_attributes source_modified_attributes
            end
            true
          else
            copy.errors.full_messages.each do |m|
              errors.add :base, m
            end
            false
          end
        end
      else
        false
      end
    rescue Exception => exception
      Rails.logger.error(exception.message)
      Rails.logger.error(exception.backtrace.join("\n"))
      errors.add :base, I18n.t("stop_area_copies.errors.exception")
      false
    end
  end

end
