//= require typeahead.bundle
//= require typeahead-addresspicker

/*Address autocompletion for all 'address' fields and 'order_pickup_location' field*/

$( document ).ready(function() {

    var addressPicker = new AddressPicker({
            language: 'de'
        }
    );

    $('#address').typeahead(
        {
            highlight: true
        },
        {
            displayKey: 'description',
            source: addressPicker.ttAdapter(),
            templates: {
                empty: [
                    '<div class="empty-message">Keine Adresse gefunden</div>'].join('\n')
            }
        }
    );

    var address = "";
    addressPicker.bindDefaultTypeaheadEvent($('#address'));
    $(addressPicker).on('addresspicker:selected', function (event, result) {
        address = result.placeResult.formatted_address;
        $('#address').val(address);
    });

    $('#address').on('blur', function (event, result) {
        $('#address').val(address);
    });
});

/*Address autocompletion for 'order_delivery_location' field*/

$( document ).ready(function() {

    var addressPicker = new AddressPicker({
            language: 'de'
        }
    );

    $('#order_delivery_location').typeahead(
        {
            highlight: true
        },
        {
            displayKey: 'description',
            source: addressPicker.ttAdapter(),
            templates: {
                empty: [
                    '<div class="empty-message">Keine Adresse gefunden</div>'].join('\n')
            }
        }
    );

    var address = "";
    addressPicker.bindDefaultTypeaheadEvent($('#order_delivery_location'));
    $(addressPicker).on('addresspicker:selected', function (event, result) {
        address = result.placeResult.formatted_address;
        $('#order_delivery_location').val(address);
    });

    $('#order_delivery_location').on('blur', function (event, result) {
        $('#order_delivery_location').val(address);
    });
});