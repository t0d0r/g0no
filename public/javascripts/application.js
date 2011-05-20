// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var old_color = ""
var show_button_bar = false

function showButtonBar(obj) {
  var new_color = "red"
  old_color = $(obj).css("border-color");
  if (show_button_bar == false) {
    $("div#note_button_bar").show("fade");
    show_button_bar = true
  }
  if ( new_color != old_color ) {
    $(obj).css("border-color", new_color);
  }
};

function hideButtonBar() {
  $("input#note_title").css("border-color", old_color);
  $("textarea#note_description").css("border-color", old_color);
  $("div#note_button_bar").toggle("fade");
  show_button_bar = false
}

function createUploader(object){
  if ( object[0] ) {
    var uploader = new qq.FileUploader({
      element:  object[0],
        action: 'do-nothing.htm',
        debug: true
    });
  }
}

$(function() {
//  $("input#note_submit").hide();
  $("label.note_title").labelOver("over")
  $("label.note_description").labelOver("over")
  $("label.finance_date").labelOver("over")
  $("label.finance_amount").labelOver("over")
  $("label.finance_comment").labelOver("over")
  $("label.note_attachment_comment").labelOver("over")
  $("input#note_title").keyup(function () { $("title").text($(this).val()); showButtonBar(this) });
  $("textarea#note_description").autoGrow();
  $("textarea#note_description").keyup(function() { showButtonBar(this) });
  $("#note_reset_button").click(function() { hideButtonBar() });
  $("#finance_date").attr("readonly", true);
//  $("#finance_date").datepicker({ dateFormat: 'dd.mm.yy', regional: 'bg' });
  $("#finance_switch").click(function() { $("#add_finance").toggle("slow"); return false; });
  $("#upload_file_switch").click(function() {
    var value = $(this).val();
    $("#upload_file_div").toggle("slow");
    return false;
  });
  $("#selector_for_element").change(function() {
    $.ajax({url: "<%= url_for :action => 'action_name', :id => @model.id %>",
      data: 'selected=' + this.value,
      dataType: 'script'})
  });
  // createUploader($("#upload_file_div"))
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
