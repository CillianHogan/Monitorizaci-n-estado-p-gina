# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'dan@21ninjas.es'
  layout 'mailer'
end
