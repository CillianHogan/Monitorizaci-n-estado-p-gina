# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@21ninjas.es'
  layout 'mailer'
end
