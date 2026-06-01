module ApplicationHelper
  def auto_link_text(text)
    text.gsub(%r{(https?://[^\s<]+)}) { |url| link_to(url, url, target: "_blank", rel: "noopener", class: "text-indigo-400 hover:text-indigo-300 underline") }
  end
end
