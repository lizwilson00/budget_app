class SessionPersistence
  def initialize(session)
    @session = session
    @session[:expenses] ||= []
  end
end