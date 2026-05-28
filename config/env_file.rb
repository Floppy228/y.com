module EnvFile
  module_function

  def fetch(key)
    values[key.to_s] || ""
  end

  def values
    @values ||= load_values
  end

  def load_values
    env_file = Rails.root.join(".env")
    return {} unless File.exist?(env_file)

    File.foreach(env_file).each_with_object({}) do |line, result|
      next if line.strip.empty? || line.strip.start_with?("#")

      name, value = line.split("=", 2)
      next if name.blank?

      result[normalize(name)] = clean(value)
    end
  end

  def normalize(name)
    name.to_s.delete_prefix("\uFEFF").strip
  end

  def clean(value)
    value.to_s.strip.gsub(/\A['"]|['"]\z/, "")
  end
end
