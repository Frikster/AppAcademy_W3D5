class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|

      define_method(name.to_sym){
        self.instance_variable_get("@#{name.to_s}")
      }

      define_method("#{name}="){ |new_name|
        self.instance_variable_set("@#{name.to_s}", new_name)
      }

    end
  end
end
