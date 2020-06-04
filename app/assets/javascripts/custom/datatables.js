// Call the dataTables jQuery plugin
$(document).ready(function() {
  var log_messages_table = $('#log_messages_table').DataTable({
    ordering: false,
    pageLength: 25
  });
  log_messages_table.page('last').draw('page');
});
