// Call the dataTables jQuery plugin
$(document).ready(function() {
  $('#log_messages_table').DataTable({
    order: [[1, "desc"]],
    pageLength: 25
  });
});
