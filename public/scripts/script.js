$(document).ready(function () {
  set_past_reminders_checkbox();
  hide_reminders_if_checked();
});

function hide_reminders_if_checked() {
  if($('.show_past_reminders').is(":checked")) {
    localStorage.setItem('show_past_reminders', 'true');
    $(".past_date").show();
  } else {
    localStorage.setItem('show_past_reminders', 'false');
    $(".past_date").hide();
  }
}

function set_past_reminders_checkbox() {
  if(localStorage.getItem('show_past_reminders') == 'true') {
    $(".show_past_reminders").prop("checked", true);
  }
}

function add_to_notes(note) {
  $('#notes').val($('#notes').val() + note + ' ')
}

function confirm_action(message) {
  return confirm(message);
}

// $(function () {

//   $("form.delete").submit(function(event) {
//     event.preventDefault();
//     event.stopPropagation();

//     var ok = confirm("Are you sure? This cannot be undone!");
//     if (ok) {
//       this.submit();
//     }
//   });

// });