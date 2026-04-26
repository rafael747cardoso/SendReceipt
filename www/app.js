var activeSelectId = null;

// ── Selectize blur overlay ──
$(document).on('focus', '.selectize-input input', function() {
  $('.selectize-control').removeClass('focus-blur-active');
  var ctrl = $(this).closest('.selectize-control');
  ctrl.addClass('focus-blur-active');
  activeSelectId = ctrl.closest('.form-group').find('select, input[id]').attr('id');
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

$(document).on('mousedown touchstart', function(e) {
  if ($('body').hasClass('datepicker-blur') &&
      !$(e.target).closest('#purchase_date, .datepicker, .datepicker--container, .air-datepicker, .air-datepicker-global-container').length) {
    $('body').removeClass('datepicker-blur');
  }
});

// ── Single shiny:inputchanged handler for everything ──
$(document).on('shiny:inputchanged', function(e) {
  // Handle datepicker
  if (e.name === 'purchase_date') {
    $('body').removeClass('datepicker-blur');
    return;
  }
  // Handle selectize dropdowns
  if (!activeSelectId) return;
  if (e.name !== activeSelectId) return;
  if (!e.value || e.value === '') return;
  $('.selectize-control').removeClass('focus-blur-active');
  document.activeElement.blur();
  activeSelectId = null;
});

// ── Scroll dropdown/calendar into visible area above keyboard ──
function scrollAboveKeyboard(targetEl) {
  var vh = (window.visualViewport && window.visualViewport.height) || window.innerHeight;
  var vTop = (window.visualViewport && window.visualViewport.offsetTop) || 0;
  var rect = targetEl.getBoundingClientRect();
  var elHeight = rect.height;
  var elTop = rect.top;
  var elBottom = rect.bottom;

  if (elTop >= vTop && elBottom <= vh) return;

  if (elHeight > (vh - vTop)) {
    window.scrollBy({ top: elTop - vTop - 10, behavior: 'smooth' });
    return;
  }

  if (elBottom > vh) {
    window.scrollBy({ top: elBottom - vh + 20, behavior: 'smooth' });
  } else if (elTop < vTop) {
    window.scrollBy({ top: elTop - vTop - 10, behavior: 'smooth' });
  }
}

$(document).on('focus click', '.selectize-input input', function() {
  var ctrl = $(this).closest('.selectize-control');
  setTimeout(function() {
    var dropdown = ctrl.find('.selectize-dropdown');
    var target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
    scrollAboveKeyboard(target);
  }, 600);
});

if (window.visualViewport) {
  window.visualViewport.addEventListener('resize', function() {
    var active = document.activeElement;
    if (!active) return;
    if (!active.matches('.selectize-input input')) return;

    var ctrl = $(active).closest('.selectize-control');
    var dropdown = ctrl.find('.selectize-dropdown');
    var target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
    setTimeout(function() { scrollAboveKeyboard(target); }, 100);
  });
}

// ── Watch for calendar popup and scroll into view ──
var calendarObserver = new MutationObserver(function(mutations) {
  mutations.forEach(function(m) {
    if (m.addedNodes.length) {
      var cal = $('.datepickers-container .datepicker, .air-datepicker-global-container .datepicker').filter(':visible').first();
      if (cal.length) {
        setTimeout(function() { scrollAboveKeyboard(cal[0]); }, 200);
      }
    }
  });
});
$(document).on('shiny:connected', function() {
  setTimeout(function() {
    var containers = document.querySelectorAll('.datepickers-container, .air-datepicker-global-container');
    containers.forEach(function(c) {
      calendarObserver.observe(c, { childList: true, subtree: true });
    });
    // Also observe body for dynamically created containers
    calendarObserver.observe(document.body, { childList: true, subtree: false });
  }, 500);
});

// ── Prevent soft keyboard on datepicker ──
function makeDateReadonly() {
  var el = document.getElementById('purchase_date');
  if (el) {
    el.setAttribute('readonly', 'readonly');
    el.setAttribute('inputmode', 'none');
  } else {
    setTimeout(makeDateReadonly, 200);
  }
}
$(document).on('shiny:connected'