// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//Event.addBehavior({
//  "#note_title:keyup": function(e) {
//    if ($F(this).blank()) {
//      $('title').innerHTML = "Note";
//    } else {
//      $('title').innerHTML = $F(this);
//    }
//  },
////  "#date": DateSelector,
//});

$(function() {
    $("#new_finance_date").attr("readonly", true);
    $("#new_finance_date").datepicker({ dateFormat: 'dd.mm.yy' });
});

$(function() {
    $("#upload_file_switch").click(function() {
      $("#upload_file_div").toggle("slow");
      return false;
    });
});

$(function() {
    $("#new_finance_switch").click(function() {
      $("#new_finance_div").toggle("slow");
      return false;
    });
});
