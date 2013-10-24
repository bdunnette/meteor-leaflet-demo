# create marker collection
Meteor.subscribe('markers')
Markers = new Meteor.Collection('markers')

# resize the layout
window.resize = (t) ->
  w = window.innerWidth
  h = window.innerHeight
  top = t.find('#map').offsetTop
  c = w - 40
  m = (h-top) - 65 
  t.find('#container').style.width = "#{c}px"
  t.find('#map').style.height = "#{m}px" 

Template.map.rendered = ->
  # resize on load
  window.resize(@)

  # resize on resize of window
  $(window).resize =>
    window.resize(@)

  # create default image path
  L.Icon.Default.imagePath = 'packages/leaflet/images'

  # create a map in the map div, set the view to a given place and zoom
  window.map = L.map 'map', 
    doubleClickZoom: false
  .setView([0, 0], 5)

  L.tileLayer "http://160.94.51.184/slides/2340/tile_{z}_{x}_{y}.jpg", 
    attribution: 'Images &copy; University of Minnesota 2013'
  .addTo(window.map)
  
  # click on the map and will insert the latlng into the markers collection 
  window.map.on 'dblclick', (e) ->
    if Meteor.userId()
      Markers.insert
        latlng: e.latlng
        zoom: window.map.getZoom()
        created:
          by: Meteor.user()._id
          on: new Date().toISOString()
        

  # watch the markers collection
  query = Markers.find({})
  query.observe
    # when new marker - then add to map and when on click then remove
    added: (mark) ->
      console.log(mark)
      console.log(Meteor.users.find({_id: mark.created.by}).fetch())
      marker = L.marker(mark.latlng)
      .addTo(window.map)
      .bindPopup(Date(mark.created.on))
      .on 'dblclick', (e) ->
        if Meteor.userId()
          m = Markers.findOne({latlng: @._latlng})
          console.log(m)
          Markers.remove(m._id)
    # when removing marker - loop through all layers on the map and remove the matching layer (marker)
    # matching based on matching lat/lon
    removed: (mark) ->
      console.log(mark)
      layers = window.map._layers
      for key, val of layers
        if !val._latlng
        else
          if val._latlng.lat is mark.latlng.lat and val._latlng.lng is mark.latlng.lng
            window.map.removeLayer(val)
