module DomainsHelper
  def status_badge_classes(status)
    base_classes = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
    status_classes = {
      "up" => "bg-green-100 text-green-800",
      "down" => "bg-red-100 text-red-800",
      "pending" => "bg-yellow-100 text-yellow-800"
    }

    "#{base_classes} #{status_classes[status]}"
  end
end
