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