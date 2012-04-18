module AppExceptions
  class InvalidParameter < StandardError
  end

  class InitialisationError < StandardError
  end

  class UnexpectedError < StandardError
    def initialize()
      message = "Unexpected error occurred. Please contact the administrator or issue a ticket through Feedback & Support button at the bottom right corner."
      super(message)
    end
  end

  class ScraperError < StandardError
  end

end