# frozen_string_literal: true

require "json"
require "net/http"

class DeepseekClient
  API_URL = URI("https://api.deepseek.com/v1/chat/completions")
  MODEL = "deepseek-chat"

  def self.chat(prompt:)
    api_key = require_api_key!

    request = Net::HTTP::Post.new(API_URL)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: MODEL,
      messages: [
        { role: "system", content: "Ты помощник Y-Core. Отвечай кратко и понятно на русском языке." },
        { role: "user", content: prompt }
      ],
      temperature: 0.7
    }.to_json

    response = Net::HTTP.start(API_URL.host, API_URL.port, use_ssl: true, read_timeout: 60) do |http|
      http.request(request)
    end
    data = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = data.dig("error", "message").presence || "Ошибка запроса к DeepSeek"
      raise error_message
    end

    data.dig("choices", 0, "message", "content").to_s.strip
  end

  def self.deepseek_api_key
    env_file = Rails.root.join(".env")
    return "" unless File.exist?(env_file)

    File.foreach(env_file) do |line|
      next if line.strip.empty? || line.strip.start_with?("#")

      name, value = line.split("=", 2)
      normalized_name = name.to_s.delete_prefix("\uFEFF").strip
      next unless normalized_name == "DEEPSEEK_API_KEY"

      return value.to_s.strip.gsub(/\A['"]|['"]\z/, "")
    end

    ""
  end

  def self.require_api_key!
    key = deepseek_api_key
    raise "Не задан DEEPSEEK_API_KEY" if key.blank?

    key
  end
end
