require 'cora'
require 'siri_objects'
require 'pp'
require 'open-uri'
require 'json'

class SiriProxy::Plugin::WhereAmI < SiriProxy::Plugin
  @@do_reverse_geocode = true
  @@debug = true
  def initialize(config)
    if config["debug"] then @@debug = config["debug"] end
    if config["do_reverse_geocode"] then @@do_reverse_geocode = config["do_reverse_geocode"] end
    #if you have custom configuration options, process them here!
  end

  def send_response(lat, lon, acc)
    if lat == nil || lon == nil
      if @@debug then  "[WhereAmI - Debug - Unknown Location] Saying \"I'm sorry, I don't know where you are.\"" end
      say "I'm sorry, I don't know where you are."
    else
      map = SiriMapItem.new
      map.label = ""
      map.detailType = "ADDRESS_ITEM"
      map.location = SiriLocation.new
      map.location.street = ""
      map.location.countryCode = ""
      map.location.city = ""
      map.location.stateCode = ""
      map.location.latitude = lat 
      map.location.longitude = lon
      map.location.postalCode = ""

      if @@do_reverse_geocode

        loc_data = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?sensor=true&latlng=" + lat.to_s + "," + lon.to_s).read)
        
        if (loc_data["status"] == "OK" && loc_data["results"].count >= 1)
          loc_data["results"][0]["address_components"].each do |component|
            if @@debug then puts "[WhereAmI - Debug - Reverse Geocode Data] #{component["types"][0]}: #{component["long_name"]}" end
            if component["types"].include? "street_address" or component["types"].include? "route"
              map.location.street = component["long_name"]
            elsif component["types"].include? "country"
              map.location.countryCode = component["short_name"]
            elsif component["types"].include? "locality"
              map.location.city = component["long_name"]
            elsif component["types"].include? "administrative_area_level_1"
              map.location.stateCode = component["short_name"]
            elsif component["types"].include? "postal_code"
              map.location.postalCode = component["long_name"]
            end
          end
        end

      end

      add_views = SiriAddViews.new
      add_views.make_root(last_ref_id)
      add_views.scrollToTop = true
      add_views.dialogPhase = "Summary"
      map_snippet = SiriMapItemSnippet.new
      map_snippet.userCurrentLocation = true
      map_snippet.items << map
      utterance = SiriAssistantUtteranceView.new("You were here:","Here's a map")
      add_views.views << utterance
      add_views.views << map_snippet

      if @@debug then puts "[WhereAmI - Debug - To iPhone] " + add_views.to_hash.to_s end
      
      send_object add_views
    end
  end 

  last_latitude = nil
  last_longitude = nil
  last_accuracy = nil
  last_update = nil
  request_pending = false

  #get the user's location and display it in the logs
  #filters are still in their early stages. Their interface may be modified
  filter "SetRequestOrigin", direction: :from_iphone do |object|
    if @@debug then puts "[WhereAmI - Debug - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}, acc: #{object["properties"]["horizontalAccuracy"]}, req. pending: #{request_pending.to_s}" end
    last_latitude = object["properties"]["latitude"]
    last_longitude = object["properties"]["longitude"]
    last_accuracy = object["properties"]["horizontalAccuracy"]
    last_update = DateTime.now

    if request_pending == true
      if object["properties"]["status"] == "Denied"
        puts "[WhereAmI - Info - User Location] User Location Denied"
        say "I can't find you without Location Services turned on for me"
      else
        send_response(last_latitude, last_longitude, last_accuracy)
      end
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
      request_pending = false
    end
  end 

  listen_for /where am i/i do
    
    add_views = SiriAddViews.new
    add_views.temporary = true
    add_views.dialogPhase = "Reflection"
    add_views.make_root(last_ref_id)
    getloc_view = SiriAssistantUtteranceView.new("Getting your current location\u2026")
    getloc_view.dialogIdentifier = "Common#gettingLocation"
    add_views.views << getloc_view

    send_object add_views

    send_object SiriGetRequestOrigin.new

    request_pending = true
    
  end
end
