var activeSelectId = null;

$(document).on('focus', '.selectize-input input', function() {
  $('.selectize-control').removeClass('focus-blur-active');
  var ctrl = $(this).closest('.selectize-control');
  ctrl.addClass('focus-blur-active');
  activeSelectId = ctrl.closest('.form-group').find('select, input[id]').attr('id');
});
$(document).on('shiny:inputchanged', function(e) {
  if (!activeSelectId) return;
  if (e.name !== activeSelectId) return;
  if (!e.value || e.value === '') return;
  $('.selectize-control').removeClass('focus-blur-active');
  document.activeElement.blur();
  activeSelectId = null;
});
$(document).on('mousedown touchstart', function(e) {
  if (!$(e.target).closest('.selectize-control').length) {
    $('.selectize-control').removeClass('focus-blur-active');
    document.activeElement.blur();
    activeSelectId = null;
  }
});

// ── Calendar blur ──
$(document).on('focus', '#purchase_date', function() {
  $('body').addClass('datepicker-blur');
});
$(document).on('shiny:inputchanged', function(e) {
  if (e.name === 'purchase_date') {
    $('body').removeClass('datepicker-blur');
    document.activeElement.blur();
  }
});
$(document).on('mousedown touchstart', function(e) {
  if ($('body').hasClass('datepicker-blur') &&
      !$(e.target).closest('#purchase_date, .datepicker, .datepicker--container, .air-datepicker, .air-datepicker-global-container').length) {
    $('body').removeClass('datepicker-blur');
    document.activeElement.blur();
  }
});