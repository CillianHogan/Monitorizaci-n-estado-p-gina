module DomainsHelper
  def status_badge_class(status)
    base_classes = 'py-1 px-3 rounded-full text-xs font-medium'
    
    status_classes = {
      'pending' => 'bg-yellow-100 text-yellow-800',
      'up' => 'bg-green-100 text-green-800',
      'down' => 'bg-red-100 text-red-800',
      'error' => 'bg-gray-100 text-gray-800'
    }

    "#{base_classes} #{status_classes[status]}"
  end
end