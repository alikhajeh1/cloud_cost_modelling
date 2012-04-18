function create_chosen(cloud_resource_types) {
  // Populate the dropdown lists and set the selected option
  $('select.chosen').each(function() {
    // The selected item is always the first non-blank option in the list
    var selected = $(this).find('option[value!=""]').remove().val();
    var list = this;
    $.each(cloud_resource_types, function(k, v) {
      if (k == selected)
        $(list).append( $("<option selected='selected'></option>").val(k).html(v) );
      else
        $(list).append( $('<option></option>').val(k).html(v) );
    });
  });

  // Activate the chosen jquery plugin and its best_in_place hack for updates
  var field_updated = "<span class='flash-success'>Field updated</span>";
  $("select.chosen").chosen();
  $("select.editable_chosen").change(function () {
    var f_name = '#best_in_place_' + $(this).attr('id');
    $(f_name).click();
    $(f_name + ' input').val($(this).find(":selected").val());
    $(f_name + ' input').blur();
    setTimeout(function(){ $(field_updated).purr(); }, 500);
  });
}