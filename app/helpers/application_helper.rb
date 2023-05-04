module ApplicationHelper
  def get_formatted_ai_response(suggestion_array)
    suggestion_array&.join(" ||||| ").gsub(',', ' ').gsub("\"", "\'").gsub("\n", '')
  end
end
