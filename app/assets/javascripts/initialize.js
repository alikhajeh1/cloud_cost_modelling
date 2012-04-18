// Only JS that is needed to initialize other plugins should be put here, otherwise put it in its own file
$(function(){
  // Activate the dropdown menus
  $('#topbar').dropdown();

  // Show form errors if there are any
  $('#form_error_modal').modal({
    keyboard: true,
    backdrop: true,
    show: true
  });

  // Activate twitter bootstrap tooltips for buttons
  $('a span.ui-button-text').parent().twipsy({
    delayIn: 350,
    placement: 'below'
  });

  // Activate twitter bootstrap tooltips for links
  $('a[rel=link_twipsy], img[rel=link_twipsy]').twipsy({
    placement: 'below'
  });

  // Activate twitter bootstrap popovers for form inputs and selects
  $('input[rel=popover], select[rel=popover], a[rel=popover]').popover({
    placement: 'below', html: true
  });

  // Activating Best In Place
  jQuery(".best_in_place").best_in_place();
  $('span.best_in_place').attr('title', 'Click to edit');
  $('h2 span.best_in_place').first().change(function() {
    var new_title = $.trim($('h2 span.best_in_place form input').val());
    if (new_title)
      document.title = new_title + ' - Cloud Cost Modelling';
  });

  // Active the multiselect jquery plugin for pattern attachment
  $('select.multiselect').multiselect();
  $('select.multiselect').closest('tr').prev().find('td span.pattern_button').click(function() {
    $(this).toggleClass('notice');
    // Find the right patternable_attribute and show its row
    var patternable_attribute = $(this).prev('span').attr('data-attribute');
    $(this).closest('tr').nextAll('tr:has(input[type="hidden"][value="' + patternable_attribute + '"])').first().toggle();
  });

  // Activate help button
  $("#help_button").click(function() {
    if ($("#help").is(":hidden")) {
      $("#help_button").text("Hide Help");
    } else {
      $("#help_button").text("Help");
    }
    $("#help").toggle('blind', {}, 500);
    return false;
  });

  // Activate the support button
  var uvOptions = {};
  (function() {
    var uv = document.createElement('script'); uv.type = 'text/javascript'; uv.async = true;
    uv.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'widget.uservoice.com/N7nKj2hvA3OlKfyx3mVejA.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(uv, s);
  })();

  // Activate sortable table headers
  $("table.sortable").tablesorter({ sortList: [[0,0]] });
});

