var map;
var directionsService;

function createMap(document_map_ID) {
    map = new google.maps.Map(document_map_ID, {
        center: {lat: 51.7491 , lng: 10.29069},
        disableDefaultUI: true,
        zoomControl: true,
    });
    map.setOptions({'scrollwheel': false});

    directionsService = new google.maps.DirectionsService;
}

// todo: exend array with useful colors
var colors  = ["red", "lime", "purple", "green", "blue", "Aqua", "DeepPink", "SteelBlue", "LightPink"];
function getColor() {
    if (colors.length == 0)
        return "blue"; // default

    var color = colors[0];
    colors.shift();

    return color;
}

function setRoute(origin, destination) {
    request = {
        origin: origin,
        destination: destination,
        travelMode: google.maps.DirectionsTravelMode.DRIVING
    };

    directionsService.route(request, function(response, status) {
        if (status == 'OK') {
            var directionsRenderer = new google.maps.DirectionsRenderer({
                polylineOptions: {
                    strokeColor: getColor(),
                    strokeOpacity: 0.6
                },
                suppressMarkers : true,
            });
            directionsRenderer.setMap(map);
            directionsRenderer.setDirections(response);
        }
    });
}

// todo: markers with the same position should be displayed, too
function setMarker(latitude, longitude, order_place) {
    new google.maps.Marker({
        position: {lat: latitude, lng: longitude},
        map: map,
        icon: "https://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=" + order_place + "|F55850|000000"
    });
}