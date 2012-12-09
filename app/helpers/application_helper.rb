module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def format_date(email)
    if email.sent_time == Date.today
      (email.created_at - 4.hours).strftime("%l:%M %P")
    else
      email.sent_time.strftime("%b %e")
    end
  end

  def format_ballot_date(date)
    date.strftime("%b %e")
  end
end

