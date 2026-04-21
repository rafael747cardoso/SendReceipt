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

// ── Scroll dropdown/calendar into visible area above keyboard ──
function scrollAboveKeyboard(targetEl) {
  var vh = (window.visualViewport && window.visualViewport.height) || window.innerHeight;
  var vTop = (window.visualViewport && window.visualViewport.offsetTop) || 0;
  var rect = targetEl.getBoundingClientRect();
  var elHeight = rect.height;
  var elTop = rect.top;
  var elBottom = rect.bottom;

  // If element fits entirely in viewport, do nothing
  if (elTop >= vTop && elBottom <= vh) return;

  // If element is taller than viewport, align its top with viewport top
  if (elHeight > (vh - vTop)) {
    window.scrollBy({ top: elTop - vTop - 10, behavior: 'smooth' });
    return;
  }

  // Otherwise, scroll just enough so bottom clears keyboard
  if (elBottom > vh) {
    window.scrollBy({ top: elBottom - vh + 20, behavior: 'smooth' });
  } else if (elTop < vTop) {
    window.scrollBy({ top: elTop - vTop - 10, behavior: 'smooth' });
  }
}

$(document).on('focus click', '.selectize-input input, #purchase_date', function() {
  var isDate = this.id === 'purchase_date';
  var ctrl = $(this).closest('.selectize-control');
  setTimeout(function() {
    var target;
    if (isDate) {
      var cal = $('.datepickers-container .datepicker, .air-datepicker-global-container .datepicker, .datepicker--container').filter(':visible').first();
      target = cal.length ? cal[0] : document.activeElement;
    } else {
      var dropdown = ctrl.find('.selectize-dropdown');
      target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
    }
    scrollAboveKeyboard(target);
  }, 600);
});

if (window.visualViewport) {
  window.visualViewport.addEventListener('resize', function() {
    var active = document.activeElement;
    if (!active) return;
    var isSelectize = active.matches('.selectize-input input');
    var isDate = active.id === 'purchase_date';
    if (!isSelectize && !isDate) return;

    var target;
    if (isDate) {
      var cal = $('.datepickers-container .datepicker, .air-datepicker-global-container .datepicker, .datepicker--container').filter(':visible').first();
      target = cal.length ? cal[0] : active;
    } else {
      var ctrl = $(active).closest('.selectize-control');
      var dropdown = ctrl.find('.selectize-dropdown');
      target = (dropdown.length && dropdown.is(':visible')) ? dropdown[0] : ctrl[0];
    }
    setTimeout(function() { scrollAboveKeyboard(target); }, 100);
  });
}

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
$(document).on('shiny:connected', makeDateReadonly);
setTimeout(makeDateReadonly, 500);

// ── Reset file input after send ──
Shiny.addCustomMessageHandler('resetFileInput', function(id) {
  // Clear the file input value
  $('#' + id).val('');
  
  // Reset the filename text
  $('#' + id).closest('.input-group').find('input.form-control').val('').attr('placeholder', 'Nothing selected');
  
  // Hide progress bar
  $('#' + id + '_progress').css('visibility', 'hidden');
  $('#' + id + '_progress .progress-bar').css('width', '0%').text('');
  
  // Clear photo preview
  $('#uploaded_photo img').attr('src', '').hide();
  
  // Tell Shiny the input is null
  Shiny.setInputValue(id, null);
});

// ── Reset datepicker to today ──
Shiny.addCustomMessageHandler('resetDatepicker', function(today) {
  var el = document.getElementById('purchase_date');
  if (el) {
    el.value = today;
    $(el).trigger('change');
    Shiny.setInputValue('purchase_date', today);
  }
});

