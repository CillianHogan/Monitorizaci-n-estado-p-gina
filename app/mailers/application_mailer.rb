# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@domain-monitor-ea281e1f44d9.herokuapp.com'
  layout 'mailer'
end
