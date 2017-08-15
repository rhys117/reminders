$(document).ready(function () {
  set_checkbox_from_storage('show_past_reminders');
  hide_reminders_if_checked('show_past_reminders', 'past_date');
  hide_reminders_if_checked('show_future_reminders', 'future_date');
});

function hide_reminders_if_checked(button, affected_class) {
  if($('.' + button).is(":checked")) {
    localStorage.setItem(button, 'true');
    $('.'+ affected_class).show();
  } else {
    localStorage.setItem(button, 'false');
    $('.' + affected_class).hide();
  }
}

function set_checkbox_from_storage(button) {
  if(localStorage.getItem(button) == 'true') {
    $('.' + button).prop("checked", true);
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