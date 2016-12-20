$(document).ready(function() {
    $('#oneway_true').click(function() {
        $('#return_date_input').hide();
    });
    $('#oneway_false').click(function() {
        $('#return_date_input').show();
    });
});
