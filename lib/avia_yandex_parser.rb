class AviaYandexParser
  URL = 'https://avia.yandex.ru'.freeze
  def initialize(params={})
    @params = params
    @headless = Headless.new
    @headless.start
    @browser = Watir::Browser.start(URL)
  end

  def perform
    results = []
    @browser.text_field(name: 'fromName').set('Львів')
    @browser.text_field(name: 'toName').set('Київ')
    @browser.execute_script("document.getElementById('when').value='19 янв'")
    @browser.execute_script("document.getElementById('return_date').value='21 янв'")
    @browser.execute_script("document.getElementsByName('adult_seats')[0].value='1'")
    @browser.execute_script("document.getElementsByName('infant_seats')[0].value='0'")
    @browser.execute_script("document.getElementsByName('children_seats')[0].value='0'")
    @browser.execute_script("document.getElementsByName('lang')[0].value='ru'")
    @browser.execute_script("document.getElementsByName('oneway')[0].checked=true") #Туда-обратно
    @browser.execute_script("document.getElementsByName('oneway')[1].checked=true") #Туда
    # @browser.execute_script("document.getElementsByName('klass')[0].checked=true") #economy
    @browser.execute_script("document.getElementsByName('klass')[1].checked=true") #buisness
    # window.scrollTo(0,document.body.scrollHeight);
    #".tabs-container_kb__count" - number of results
    #pages = (number of results - count(attractive deals)) / 20 + 1
    @browser.button(type: 'submit').click
    @browser.div(class: 'serp-layout_kb__content').wait_until_present
    @browser.close
    @headless.destroy
    results
  end
end
