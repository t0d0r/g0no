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
    $("#finance_date").attr("readonly", true);
    $("#dinance_date").datepicker({ dateFormat: 'dd.mm.yy' });
});

$(function() {
    $("#add_finance_amount").numeric({ buttons: false, format: { format: '0.##'}} );
});

$(function() {
    $("#upload_file_switch").click(function() {
      $("#upload_file_div").toggle("slow");
      return false;
    });
});

$(function() {
    $("#add_finance_switch").click(function() {
      $("#add_finance").toggle("slow");
      return false;
    });
});
