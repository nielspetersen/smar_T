$( document ).ready(function() {
    search_term = getUrlParameter('search_query');
    if (search_term) {
        $('input[type=search]#search_ressources')[0].value= search_term;
    }
});

function getUrlParameter(name) {
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
    regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
    results = regex.exec(location.search);
    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
}
