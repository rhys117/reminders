$(document).ready(function () {
  set_checkbox_from_storage('show_past_reminders');
  set_checkbox_from_storage('show_future_reminders');
  hide_reminders_if_checked('show_past_reminders', 'past_date');
  hide_reminders_if_checked('show_future_reminders', 'future_date');
  set_select_from_storage('show_above_priority');
  hide_reminders_below_priority();
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

function deselect(element) {
  $(element).prop('checked', false)
}

function hide_reminders_below_priority() {
  var priority_level = $('.show_above_priority').find(':selected').text();
  localStorage.setItem('show_above_priority', priority_level);

  for (var i = 5; i > 0; i--) {
    $('.priority_' + i).show();
  }

  for (var i = priority_level; i >= 0; i--) {
    $('.priority_' + (i - 1)).hide();
  }
}

function add_to_notes(note) {
  $('#notes').val($('#notes').val() + note + ' ')
}

function set_select_from_storage(value) {
  $('.' + value).val(localStorage.getItem(value));
}
