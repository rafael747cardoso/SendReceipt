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

// ── Scroll dropdown into visible area above keyboard ──
function scrollAboveKeyboard(targetEl) {
  // Estimate keyboard height as ~45% of viewport on mobile
  var vh = window.innerHeight;
  var keyboardEstimate = vh * 0.45;
  var visibleArea = vh - keyboardEstimate;

  var rect = targetEl.getBoundingClientRect();
  var targetBottom = rect.bottom;

  // If element extends below the keyboard line, scroll up by the overflow
  if (targetBottom > visibleArea) {
    var scrollBy = targetBottom - visibleArea + 20; // 20px padding
    window.scrollBy({ top: scrollBy, behavior: 'smooth' });
  }
}

$(document).on('focus', '.selectize-input input, #purchase_date', function() {
  var ctrl = $(this).closest('.selectize-control');
  setTimeout(function() {
    var dropdown = ctrl.find('.selectize-dropdown');
    var target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0] || document.activeElement;
    scrollAboveKeyboard(target);
  }, 400);
});
