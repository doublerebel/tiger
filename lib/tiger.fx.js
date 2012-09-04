(function() {
  var FX, Tiger;

  Tiger = require('/lib/tiger');

  FX = {
    fadeIn: function(duration, callback) {
      this.element.visible = true;
      return this.fadeTo(1, duration, callback);
    },
    fadeOut: function(duration, callback) {
      this.element.visible = false;
      return this.fadeTo(0, duration, callback);
    },
    fadeTo: function(opacity, duration, callback) {
      return this.animate({
        opacity: opacity,
        duration: duration
      }, callback);
    },
    slideUp: function(duration, callback) {
      this.element.visible = false;
      return this.animate({
        top: '-' + this.get('height'),
        duration: duration
      }, callback);
    },
    slideDown: function(duration, callback) {
      this.element.visible = true;
      return this.animate({
        top: this.defaults.top,
        duration: duration
      }, callback);
    }
  };

  Tiger.Element.include(FX);

  Tiger.FX = FX;

  if (typeof module !== "undefined" && module !== null) module.exports = FX;

}).call(this);
