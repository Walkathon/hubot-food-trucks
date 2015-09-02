# Description:
#   Find food trucks near the office
#
# Dependencies:
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot food trucks - shows lunchtime food trucks in the area
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   <walkathon>

module.exports = (robot) ->
 robot.respond /food trucks/i, (res) ->
  res.http("http://www.chicagofoodtruckfinder.com")
     .get() (err, reponse, body) ->

      # remove line breaks ...
      bodyStripped = body.replace /\r\n|\n|\r/gm, ""
 
      # screen scrape here to get the JSON between ...
      # trucks, locations, stops
      # "trucks": ...
      # "date":"20
      [dontcare, splitText]  = bodyStripped.split "\"trucks\"\:"
      [splitText2, dontcare] = splitText.split ",\"date\":\"20"
      trucksJSON             = "{\"trucks\":" + splitText2 + "}"

      jsonData      = JSON.parse trucksJSON
      trucksJSON    = jsonData.trucks
      locationsJSON = jsonData.locations
      stopsJSON     = jsonData.stops
     
      filteredTrucks    = new Array
      filteredLocations = new Array
      localStops        = new Array

      # A. find locations.X.name where 
      #    Lake and Michigan, Chicago, IL 
      #    Randolph and Columbus, Chicago, IL
      for location in locationsJSON
        if location.name == 'Lake and Michigan, Chicago, IL' || location.name == 'Randolph and Columbus, Chicago, IL'
          filteredLocations.push(location)

      # B. find stops w/ locations from a)
      #    with startTimes before noon and endTimes after noon
      for stop in stopsJSON
        for location in filteredLocations
          if (stop.location == location.id)
            startDate = new Date(stop.startMillis)
            stopDate  = new Date(stop.endMillis)

            if ((startDate.getHours() < 12) && (stopDate.getHours() > 12))
              localStop = new Array
              localStop.locationName = location.name.replace /, Chicago, IL/g, ""
              minutes = if stopDate.getMinutes() < 10 then "0" + stopDate.getMinutes() else stopDate.getMinutes()
              localStop.departureTime = stopDate.getHours() + ":" + minutes
              console.log stopDate.getMinutes()
              for truck in trucksJSON
                if (truck.id == stop.truckId) 
                  localStop.url = truck.url
                  localStop.truckName = truck.name
                  localStops.push(localStop)

      # print this stuff out ... 
      message = ""
      if localStops.length == 0
        message = "No nearby food trucks today :( "
      else
        message  =  "Today's Food Truck Choices (courtesy chicagofoodtruckfinder.com)\n"
        message  += "--------------------------\n"
        for localStop in localStops
          message += localStop.truckName
          message += "\n"
          message += localStop.locationName
          message += "\n"
          message += "Departure time: " + localStop.departureTime
          message += "\n"
          message += localStop.url
          message += "\n"
          message += "\n"

      res.send(message);
