$(function() {
  $("tbody.sortable").sortable({
    items: "tr:not(.unsortable)",
    update: function (event, ui) {
        var data = $(this).sortable('serialize');
        $.ajax({
            data: data,
            type: 'POST',
            url: '/tours/positions/update'
        });
        $("#map").hide();
        $(".map-info").removeClass("hidden");
     }
  });
});

var disableButton = function(button) {
  if(!$(button).hasClass("disabled")) {
    button.addClass("disabled");
    button.disabled = true;
  }
}


$(function() { 
$('select#problem').bind('change', function() {
  $('.type_forms').hide();
  $('.type_forms input').attr('disabled', true);
  var selection = $(this).val();
  $('#' + selection).show();
  $('#' + selection + ' input').attr('disabled', false);
  if ( this.value == 'type_3'){
  $('#type_1').show();
  $('#type_1 input').attr('disabled', false);
  $('#type_2').show();
  $('#type_2 input').attr('disabled', false);
  }
}).change();

});

$(function() { 
$('select#user_form_role').bind('change', function() {
  $('#driver').hide();
  $('#driver input').attr('disabled', true);
  var selection = $(this).val();
  $('#' + selection).show();
  $('#' + selection + ' input').attr('disabled', false);
}).change();

});

var deleteCompanyLogo = function() {
    $('input#company_logo').val('');
    $('#current_company_logo').remove();
    $('button#delete_company_logo').hide();
};

$(function () {
    $('.order_import input').change(function() {
        $('#upload-orders-btn').prop('disabled', ($('#inputfile').val() == ""));
        }
    )
});