module DomainsHelper
  def http_code_badge(code)
    return content_tag(:span, "N/A", class: "px-2 py-0.5 text-xs font-medium rounded-full bg-gray-100 text-gray-700") if code.blank?

    color_classes = case code
                    when 200..299 then "bg-emerald-100 text-emerald-800 border border-emerald-200"
                    when 300..399 then "bg-blue-100 text-blue-800 border border-blue-200"
                    when 400..499 then "bg-amber-100 text-amber-800 border border-amber-200"
                    else "bg-rose-100 text-rose-800 border border-rose-200"
                    end

    content_tag(:span, "HTTP #{code}", class: "inline-flex items-center px-2.5 py-0.5 text-xs font-semibold rounded-full #{color_classes}")
  end
end
