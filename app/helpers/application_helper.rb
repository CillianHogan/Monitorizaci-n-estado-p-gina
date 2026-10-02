# frozen_string_literal: true

module ApplicationHelper

  def http_code_badge(code)
    return content_tag(:span, "N/A", class: "px-2 py-0.5 text-xs font-medium rounded-full bg-gray-100 text-gray-700") if code.blank?

    color_classes = case code.to_i
                    when 200..299 then "bg-emerald-100 text-emerald-800 border border-emerald-200"
                    when 300..399 then "bg-blue-100 text-blue-800 border border-blue-200"
                    when 400..499 then "bg-amber-100 text-amber-800 border border-amber-200"
                    else "bg-rose-100 text-rose-800 border border-rose-200"
                    end

    content_tag(:span, "HTTP #{code}", class: "inline-flex items-center px-2 py-0.5 text-xs font-semibold rounded-full #{color_classes}")
  end


  def status_badge_class(status)
    case status.to_s
    when "up"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200"
    when "error", "down"
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200"
    else
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800 border border-amber-200"
    end
  end

end
