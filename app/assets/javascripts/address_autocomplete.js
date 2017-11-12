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


/*Address autocompletion for imported Orders address fields*/

$( document ).ready(function() {

  $('[id$=location]').each(function() {

    var addressPicker = new AddressPicker({
            language: 'de'
        }
    );

    $(this).typeahead(
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
    addressPicker.bindDefaultTypeaheadEvent($(this));
   $(addressPicker).on('addresspicker:selected', function (event, result) {
        address = result.placeResult.formatted_address;
        $(this).val(address);
    });

    $(this).on('blur', function (event, result) {
       $(this).val(address);
       if($(this).val() != ""){
       var elementname = $(this).attr('name')
       var statusname = elementname.replace("location","status");
       jQuery('select[name="'+statusname+'"]').prop("disabled", false);
       $('input[name="'+elementname+'"]').val($(this).val());
       }
    });
   });
});