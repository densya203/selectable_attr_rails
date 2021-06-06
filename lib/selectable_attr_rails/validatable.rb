require 'selectable_attr_rails'

module SelectableAttrRails
  module Validatable
    autoload :Base, 'selectable_attr_rails/validatable/base'
    autoload :AkmEnum, 'selectable_attr_rails/validatable/akm_enum'
  end
end
