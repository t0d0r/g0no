// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function showSaveButton(obj) {
  $(obj).css("border-color", "red");
  $("input#note_submit").show();
};

$(function() {
  $("input#note_submit").hide();
  $("input#note_title").keyup(function () {
    var value = $(this).val();
    $("title").text(value);
    showSaveButton(this)
  });
  $("textarea#note_description").autoGrow();
  $("textarea#note_description").keyup(function() {
    showSaveButton(this)
  });
  $("#finance_date").attr("readonly", true);
  $("#dinance_date").datepicker({ dateFormat: 'dd.mm.yy' });
  $("#add_finance_amount").numeric({ buttons: false, format: { format: '0.##'}} );
  
  $("#upload_file_switch").click(function() {
    var value = $(this).val();
    $("#upload_file_div").toggle("slow");
    return false;
  });
  $("#add_finance_switch").click(function() {
    $("#add_finance").toggle("slow");
    return false;
  });
  $("#selector_for_element").change(function() {
    $.ajax({url: "<%= url_for :action => 'action_name', :id => @model.id %>",
      data: 'selected=' + this.value,
      dataType: 'script'})
  });
  $("#alert").click(function() {
    alert(this.getAttribute("data-message"));
    return false;
  });
});

$(function() {
  $("#upl0ad_file_switch").click(function () {
    var c = $("#upload_file_div");
    var o = (c.css('opacity') == 0) ? 1 : 0;
    var t = (o==1) ? 'Show Background' : 'Show Text';
    c.toggle("slow")
    $(this).text(t);
    return false;
  });
});
