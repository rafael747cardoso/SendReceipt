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
  // Use VisualViewport API for accurate visible height with keyboard open
  var vh = (window.visualViewport && window.visualViewport.height) || window.innerHeight;

  var rect = targetEl.getBoundingClientRect();
  var targetBottom = rect.bottom;

  if (targetBottom > vh) {
    var scrollBy = targetBottom - vh + 30; // 30px padding
    window.scrollBy({ top: scrollBy, behavior: 'smooth' });
  }
}

$(document).on('focus', '.selectize-input input, #purchase_date', function() {
  var ctrl = $(this).closest('.selectize-control');
  // Wait longer so keyboard is fully open AND visualViewport has updated
  setTimeout(function() {
    var dropdown = ctrl.find('.selectize-dropdown');
    var target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
    scrollAboveKeyboard(target);
  }, 600);
});

// Also re-scroll if viewport changes (e.g., keyboard finishes animating)
if (window.visualViewport) {
  window.visualViewport.addEventListener('resize', function() {
    var active = document.activeElement;
    if (active && (active.matches('.selectize-input input') || active.id === 'purchase_date')) {
      var ctrl = $(active).closest('.selectize-control');
      var dropdown = ctrl.find('.selectize-dropdown');
      var target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
      setTimeout(function() { scrollAboveKeyboard(target); }, 100);
    }
  });
}
