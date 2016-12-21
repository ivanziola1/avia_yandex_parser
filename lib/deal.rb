class Deal < Struct.new(:companies_list, :tags, :departure_time,
                        :flight_duration, :arrival_time, :flight_details, :price, :href)
end
