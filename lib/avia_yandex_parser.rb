class AviaYandexParser
  attr_reader :results
  URL = 'https://avia.yandex.ru'.freeze
  def initialize(params)
    @results = []
    @params = params
    @headless = Headless.new
    @headless.start
    @browser = Watir::Browser.start(URL)
    @nokogiri_page = nil
  end

  def perform
    set_form_inputs
    submit_search_and_wait_for_results
    set_nokgiri_page
    pages = number_of_pages
    load_all_pages(pages)
    set_nokgiri_page
    scrape_data
    close_browser_and_destroy_headless_session
  end

  private

  def set_form_inputs
    set_departure_and_arrival_locations
    set_departure_and_arrival_dates
    set_the_number_of_seats
    set_the_oneway_value
    set_the_flight_class
    @browser.execute_script("document.getElementsByName('lang')[0].value='#{@params[:lang]}'")
  end

  def submit_search_and_wait_for_results
    @browser.button(type: 'submit').click
    @browser.div(class: 'serp-layout_kb__content').wait_until_present
  end

  def load_all_pages(number_of_pages)
    unless number_of_pages == 1
      number_of_pages.times do
        @browser.execute_script('window.scrollTo(0,document.body.scrollHeight)')
        @browser.div(class: 'flights-list_kb__page-separator').wait_until_present
      end
    end
  end

  def close_browser_and_destroy_headless_session
    @browser.close
    @headless.destroy
  end

  def set_nokgiri_page
    @nokogiri_page = Nokogiri::HTML(@browser.html)
  end

  def scrape_data
    deals = @nokogiri_page.css('.flight_list')
    deals.each do |deal|
      @results << get_data_from_deal(deal)
    end
  end

  def parse_deals(deals)
  end

  def get_data_from_deal(deal)
    departure_time = deal.at_css('.flight_list__departure-time').text.strip
    arrival_time = deal.at_css('.flight_list__arrival-time').text
    flight_duration = deal.at_css('.flight_list__flight-duration').text.strip
    price = deal.at_css('.price_kb').text.strip
    tags = []
    companies_list = []
    deal.css('.type-of-ticket_kb__type').each { |type| tags << type.text }
    deal.css('.flight_list__company-names').each { |company| companies_list << company.text }
    flight_details = { transfers: [] }
    flight_details[:airports] = deal.css('.flight_list__airports').text
    list_transfer = deal.css('.flight_list__transfer')
    if list_transfer.empty?
      flight_details[:transfers] = [{ transfer: deal.at_css('.flight_list__direct-flight').text }]
    else
      list_transfer.each do |el|
        dayly_transfer = el.at('.flight_list__daily-transfer')
        transfer_place = if dayly_transfer
                           dayly_transfer.text
                         else
                           'night'
                         end
        flight_details[:transfers] << { place: transfer_place, transfer_duration: el.at('.flight_list__transfer-duration').text }
      end
    end
    Deal.new(companies_list, tags, departure_time, flight_duration,
             arrival_time, flight_details, price)
  end

  def set_departure_and_arrival_locations
    @browser.text_field(name: 'fromName').set(@params[:from_name])
    @browser.text_field(name: 'toName').set(@params[:to_name])
  end

  def set_departure_and_arrival_dates
    @browser.execute_script("document.getElementById('when').value='#{@params[:when]}'")
    @browser.execute_script("document.getElementById('return_date').value='#{@params[:return_date]}'")
  end

  def set_the_number_of_seats
    @browser.execute_script("document.getElementsByName('adult_seats')[0].value='#{@params[:adult_seats]}'")
    @browser.execute_script("document.getElementsByName('infant_seats')[0].value='#{@params[:infant_seats]}'")
    @browser.execute_script("document.getElementsByName('children_seats')[0].value='#{@params[:children_seats]}'")
  end

  def set_the_oneway_value
    if @params[:oneway] == '1'
      @browser.execute_script("document.getElementsByName('oneway')[1].checked=true") # oneway
    else
      @browser.execute_script("document.getElementsByName('oneway')[0].checked=true") # return
    end
  end

  def set_the_flight_class
    if @params[:klass] == 'economy'
      @browser.execute_script("document.getElementsByName('klass')[0].checked=true") # economy
    else
      @browser.execute_script("document.getElementsByName('klass')[1].checked=true") # buisness
    end
  end

  def number_of_pages
    all = @nokogiri_page.at('.tabs-container_kb__count').text.strip.to_i
    return 1 if all <= 20
    attractive_deals = @nokogiri_page.at_css('.serp-layout_kb__top').css('.flight_list').length # attractive deals
    pages = (all - attractive_deals) / 20 + 1 # pages = (number of results - count(attractive deals)) / deals on one page + 1
    pages
  end
end
