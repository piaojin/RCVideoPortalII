(function (exports) {
  'use strict';

  /**
   * Object.keys {@link https://ponyfoo.com/articles/polyfills-or-ponyfills | ponyfill}
   * @external
   */
  var keys = function (collection) {
      var keys = [];
      for (var key in collection)
          keys.push(key);
      return keys;
  };
  /** High level object API over low level {@link Api.setRecognizerFeatures | Recognizer} API */
  var Recognizer = /*@__PURE__*/ (function () {
      function Recognizer() {
          /** Hash map of enabled features */
          this._enabled = {};
      }
      /** Enables Recognizer feature */
      Recognizer.prototype.enable = function (feature) {
          if (feature in this._enabled)
              return this;
          this._enabled[feature] = true;
          Api.setRecognizerFeatures(keys(this._enabled));
          return this;
      };
      /** Disables Recognizer feature */
      Recognizer.prototype.disable = function (feature) {
          if (!(feature in this._enabled))
              return this;
          Api.setRecognizerFeatures(keys(this._enabled));
          delete this._enabled[feature];
          return this;
      };
      return Recognizer;
  }());
  /** Global Recognizer instance */
  var recognizer = /*@__PURE__*/ new Recognizer();

  /*! *****************************************************************************
  Copyright (c) Microsoft Corporation.

  Permission to use, copy, modify, and/or distribute this software for any
  purpose with or without fee is hereby granted.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
  AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
  INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
  LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
  OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
  PERFORMANCE OF THIS SOFTWARE.
  ***************************************************************************** */
  /* global Reflect, Promise */

  var extendStatics = function(d, b) {
      extendStatics = Object.setPrototypeOf ||
          ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
          function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
      return extendStatics(d, b);
  };

  function __extends(d, b) {
      if (typeof b !== "function" && b !== null)
          throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
      extendStatics(d, b);
      function __() { this.constructor = d; }
      d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
  }

  function __decorate(decorators, target, key, desc) {
      var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
      if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
      else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
      return c > 3 && r && Object.defineProperty(target, key, r), r;
  }

  /**
   * Classic Nodejs {@link https://medium.com/developers-arena/nodejs-event-emitters-for-beginners-and-for-experts-591e3368fdd2 | Event emitter}
   * @external
   */
  var EventEmitter = /*@__PURE__*/ (function () {
      function EventEmitter() {
          this.__listeners = {};
      }
      /** Adds the listener to the event */
      EventEmitter.prototype.on = function (event, listener) {
          var _a;
          var _b;
          ((_a = (_b = this.__listeners)[event]) !== null && _a !== void 0 ? _a : (_b[event] = [])).push(listener);
          return this;
      };
      /** Removes the listener from the event */
      EventEmitter.prototype.off = function (event, listener) {
          var _a, _b, _c;
          var idx = (_b = (_a = this.__listeners[event]) === null || _a === void 0 ? void 0 : _a.indexOf(listener)) !== null && _b !== void 0 ? _b : -1;
          if (idx !== -1)
              (_c = this.__listeners[event]) === null || _c === void 0 ? void 0 : _c.splice(idx, 1);
          return this;
      };
      /** Invokes the event listeners */
      EventEmitter.prototype.emit = function (event) {
          var _a;
          (_a = this.__listeners[event]) === null || _a === void 0 ? void 0 : _a.forEach(function (listener) { return listener(); });
          return this;
      };
      return EventEmitter;
  }());

  /** Object API for face presence detection */
  var FaceTracker = /*@__PURE__*/ (function (_super) {
      __extends(FaceTracker, _super);
      function FaceTracker() {
          // Backward compatibility
          // will be removed when `scene` is released
          var _this = _super !== null && _super.apply(this, arguments) || this;
          /**
           * Emits "face" event
           *
           * Designed to be used in conjunction with {@link Effect.faceActions} (see example)
           * @deprecated
           * This is a backward-compatibility and is considered for removal in favor of Recognizer from Scene API
           * @example
           * ```ts
           * // config.ts
           *
           * configure({
           *  // ...
           *  faceActions: [FaceTracker.emitFaceDetected],
           *  // ...
           * })
           * ```
           */
          _this.emitFaceDetected = function () { return _this.emit("face"); };
          /**
           * Emits "no-face" event
           *
           * Designed to be used in conjunction with {@link Effect.noFaceActions} (see example)
           * @deprecated
           * This is a backward-compatibility and is considered for removal in favor of Recognizer from Scene API
           * @example
           * ```ts
           * // config.ts
           *
           * configure({
           *  // ...
           *  noFaceActions: [FaceTracker.emitNoFaceDetected],
           *  // ...
           * })
           * ```
           */
          _this.emitNoFaceDetected = function () { return _this.emit("no-face"); };
          return _this;
      }
      return FaceTracker;
  }(EventEmitter));
  /** Global FaceTracker instance */
  var faceTracker = /*@__PURE__*/ new FaceTracker();

  /**
   * Auto-increment {@link Mesh._id} generator
   * @private
   */
  var id = (function () {
      var i = 0;
      return function () { return i++; };
  })();
  /** High level object API over low level {@link Api.meshfxMsg | Api.meshfxMsg("spawn")} */
  var Mesh = /*@__PURE__*/ (function (_super) {
      __extends(Mesh, _super);
      /**
       * @param file - filepath of .bsm2 model to be used of special `"!glfx_FACE"` keyword (see {@link https://docs.banuba.com/docs/effect_constructor/reference/config_js#spawn | the link} for details)
       */
      function Mesh(file) {
          var _this = _super.call(this) || this;
          _this._id = id();
          _this._isEnabled = false;
          _this._file = file;
          return _this;
      }
      /** Shows the mesh and allocates resources */
      Mesh.prototype.enable = function () {
          if (this._isEnabled)
              return this;
          this._isEnabled = true;
          Api.meshfxMsg("spawn", this._id, 0, this._file);
          this.emit("enabled");
          return this;
      };
      /** Hides the mesh and frees resources */
      Mesh.prototype.disable = function () {
          if (!this._isEnabled)
              return this;
          this._isEnabled = false;
          Api.meshfxMsg("del", this._id);
          this.emit("disabled");
          return this;
      };
      return Mesh;
  }(EventEmitter));

  /** High level object API over {@link Api.meshfxMsg | Api.meshfxMsg("tex")} */
  var Texture = /*@__PURE__*/ (function () {
      /**
       * @param index - the index of texture sampler defined in cfg.toml (see {@link https://docs.banuba.com/docs/effect_constructor/reference/cfg_toml#materials | the link } for details)
       * @param file - filepath of texture file to use
       * @example
       * ```ts
       * new Texture(mesh, 2, "softlight.ktx")
       * ```
       */
      function Texture(mesh, index, file) {
          var _this = this;
          /** Used to auto-reload the texture on mesh enable */
          this._reload = function () {
              if (!_this._file)
                  return;
              Api.meshfxMsg("tex", _this._mesh["_id"], _this._index, _this._file);
          };
          this._mesh = mesh;
          this._index = index;
          this._file = file;
          if (this._mesh["_isEnabled"])
              this._reload();
          this._mesh.on("enabled", this._reload);
      }
      /** Sets the file as texture file */
      Texture.prototype.set = function (file) {
          this._file = file;
          if (this._mesh["_isEnabled"]) {
              Api.meshfxMsg("tex", this._mesh["_id"], this._index, this._file);
          }
          return this;
      };
      return Texture;
  }());

  /**
   * Internally used by Vec4 to provide the same Vec4 instance for the same GLSL `vec4` index
   * @private
   * @example
   * ```ts
   * new Vec4(42) === new Vec4(42) // true
   * new Vec4(1) === new Vec4(2) // false
   * ```
   */
  var cache = {};
  /**
   * High level object API over {@link Api.meshfxMsg | Api.meshfxMsg("shaderVec4") }
   *
   * Generally it's an object representation of {@link https://thebookofshaders.com/glossary/?search=vec4 | GLSL vec4}
   */
  var Vec4 = /*@__PURE__*/ (function () {
      /**
       * @param index - index of shader `vec4` variable (see {@link https://docs.banuba.com/docs/effect_constructor/reference/config_js#shadervec4 | link} for details)
       *
       * @example
       * ```ts
       * const vec4 = new Vec4(42)
       * ```
       */
      function Vec4(index) {
          this.x = new Component(this);
          this.y = new Component(this);
          this.z = new Component(this);
          this.w = new Component(this);
          this._index = index;
          if (!(index in cache))
              cache[index] = this;
          return cache[index];
      }
      /**
       * Sets `vec4` components at once
       * @example
       * ```ts
       * const vec4 = new Vec4(42).set("1 2 3 4") // "1 2 3 4"
       *
       * vec4.x.get() // 1
       * vec4.y.get() // 2
       * vec4.z.get() // 3
       * vec4.w.get() // 4
       *
       * vec4.set("5 6") // "5 6 0 0"
       *
       * vec4.x.get() // 5
       * vec4.y.get() // 6
       * vec4.z.get() // but `undefined`
       * vec4.w.get() // but `undefined`
       * ```
       */
      Vec4.prototype.set = function (xyzw) {
          var _a = xyzw.split(" ").map(parseFloat), x = _a[0], y = _a[1], z = _a[2], w = _a[3];
          this.x["_value"] = x;
          this.y["_value"] = y;
          this.z["_value"] = z;
          this.w["_value"] = w;
          Api.meshfxMsg("shaderVec4", 0, this._index, this.toString());
          return this;
      };
      /**
       * Returns string representation of {@link Vec4}
       * @example
       * ```ts
       * new Vec4(42).set("1 2 3 4").toString() // "1 2 3 4"
       * ```
       */
      Vec4.prototype.toString = function () {
          return [
              this.x.toString(),
              this.y.toString(),
              this.z.toString(),
              this.w.toString(),
          ].join(" ");
      };
      return Vec4;
  }());
  /**
   * Object representation of {@link https://thebookofshaders.com/glossary/?search=vec4 | GLSL vec4} component (coordinate)
   *
   * Simplifies sync & manipulation of `vec4` components (coordinates)
   *
   * @private
   * @typeParam T - Type of component value.
   *
   * It may be useful to force the component to be treated as `Component<number>` to avoid type warnings, e.g:
   * ```ts
   * const x = new Vec4(1).x
   * x.set(x => x + 1) // Warning: Operator '+' cannot be applied to types 'number | boolean' and 'number'.
   *
   * const y = new Vec4(2).y
   * y.set(y => <number>y + 1) // it's ok but verbose

   * const z = new Vec4(3).z as Coordinate<number>
   * z.set(z => z + 1) // it's just fine
   * ```
   * @example
   * ```ts
   * const vec4 = new Vec4(42) // "0 0 0 0"
   *
   * vec4.y.set(2) // same as vec4.set("0 2 0 0")
   * vec4.z.set(3) // same as vec4.set("0 2 3 0")
   *
   * vec4.w.set(w => <number>w + 4) // same as vec4.set("0 2 3 4")
   * ```
   */
  var Component = /*@__PURE__*/ (function () {
      function Component(parent) {
          this._parent = parent;
      }
      /** Returns the component value */
      Component.prototype.get = function () { return this._value; };
      Component.prototype.set = function (value) {
          if (typeof value === "function")
              value = value(this._value);
          this._value = value;
          Api.meshfxMsg("shaderVec4", 0, this._parent["_index"], this._parent.toString());
          return this;
      };
      /**
       * Returns string representation of the {@link Component} according to the following rules:
       *
       * - for {@link https://developer.mozilla.org/en-US/docs/Glossary/Falsy | falsy} values returns `"0"`
       * - for {@link https://developer.mozilla.org/en-US/docs/Glossary/Truthy | truthy } values returns string representation of the value number representation
       * @example
       * ```ts
       * new vec4 = new Vex4(42)
       * vec4.x.get() // `undefined`
       * vec4.x.toString() // "0"
       *
       * vec4.x.set(false).get() // false
       * vec.x.toString() // "0"
       *
       * vec4.x.set(true).get() // true
       * vec4.x.toString() // "1"
       *
       * vec4.x.set(42).get() // 42
       * vec4.x.toString() // "42"
       * ```
       */
      Component.prototype.toString = function () {
          var value = this._value;
          if (!value)
              value = Boolean(value);
          if (typeof value === "boolean")
              value = Number(value);
          if (typeof value === "number")
              value = String(value);
          return value;
      };
      return Component;
  }());

  /** High level object API over low level {@link Api.setVideoFile | Api.setVideoFile("layer","filepath")} */
  var Video = /*@__PURE__*/ (function () {
      /**
       * @example
       * ```ts
       * const video = new Video("video.mp4", true, 1))
       *  .set("video.mp4")
       *  .setSpeedFactor(0.5)
       *  .play(true)
       * ```
       */
      function Video(filepath, isLooped, speedFactor) {
          this._isLooped = true;
          this._speedFactor = 1;
          this._file = filepath;
          this._isLooped = isLooped;
          this._speedFactor = speedFactor;
      }
      /** Sets video/gif file as background and plays it in a loop */
      Video.prototype.set = function (filepath) {
          this._file = filepath;
          Api.setVideoFile("frx", this._file);
          Api.playVideo("frx", this._isLooped, this._speedFactor);
          return this;
      };
      /** Plays video/gif file after pause/stop */
      Video.prototype.play = function (isLooped) {
          this._isLooped = isLooped;
          Api.playVideo("frx", this._isLooped, this._speedFactor);
          return this;
      };
      /** Sets speedFactor for video/gif and plays it from the start */
      Video.prototype.speed = function (speedFactor) {
          this._speedFactor = speedFactor;
          return this;
      };
      /** Puts video/gif on a pause, next playVideo resumes from last position.*/
      Video.prototype.pause = function () {
          Api.pauseVideo("frx");
          return this;
      };
      /** Stops video/gif on a pause, next playVideo resumes from the very beginning.*/
      Video.prototype.stop = function () {
          Api.stopVideo("frx");
          return this;
      };
      return Video;
  }());

  function json(target, key, desc) {
      if (arguments.length === 3) {
          var method_1 = target[key];
          if (typeof method_1 !== "function")
              return;
          desc.value = function (maybeJson) {
              if (typeof maybeJson === "string") {
                  try {
                      maybeJson = JSON.parse(maybeJson);
                  }
                  catch (_a) { }
              }
              return method_1.call(this, maybeJson);
          };
      }
      for (var method in target.prototype) {
          json(target.prototype, method, Object.getOwnPropertyDescriptor(target.prototype, method));
      }
  }

  var mesh$4 = "triBG2.bsm2";

  var js_bg_rotation$1 = 14;
  var js_bg_scale$1 = 15;
  var js_bg_content_mode$1 = 17;
  var js_is_screen_Mirrored = 35;

  /**
   * Sets background behind a body to a texture
   * @example
   * ```ts
   * const bg = new BackgroundTexture()
   *  .set("bg_colors_tile.png")
   *  .scale(1.2)
   *  .rotate(90)
   * ```
   */
  var BackgroundTexture = /*@__PURE__*/ (function () {
      function BackgroundTexture() {
        var _this = this;
        this._isMirrored = new Vec4(js_is_screen_Mirrored).x;
        this._mesh = new Mesh(mesh$4)
            .on("enabled", function () {
                recognizer.enable("background");
                faceTracker
                    .on("face", _this._trackMirroring)
                    .on("no-face", _this._trackMirroring);
                })
            .on("disabled", function () { 
                recognizer.disable("background"); 
                faceTracker
                    .off("face", _this._trackMirroring)
                    .off("no-face", _this._trackMirroring);
            });
          this._texture = new Texture(this._mesh, 0);
          this._rotation_angle = new Vec4(js_bg_rotation$1).x.set(0);
          this._rotation_mode = new Vec4(js_bg_rotation$1).y.set(0);
          this._scaling = new Vec4(js_bg_scale$1).x.set(1);
          this._contentMode = new Vec4(js_bg_content_mode$1).x.set(1);
          this._trackMirroring = function () { return _this._isMirrored.set(isMirrored());};

      }
      /** Sets the file as background texture*/
      BackgroundTexture.prototype.set = function (texture) {
          this._mesh.enable();
          this._texture.set(texture);
          return this;
      };
      /** Sets initial the background texture angle in degrees (used for photos with angle !=0 in metadata) */
      BackgroundTexture.prototype.setInitialRotation = function (angle) {
          if (angle % 90 == 0) {
              this._rotation_angle.set(function (x) { return x + angle; });
              this._rotation_mode.set(0);
          }
          else {
              Api.print("You have passed wrong angle - " + angle + ". Rotation is available with angle value divisible by 90.");
          }
          return this;
      };
      /** Rotates the background texture clockwise in degrees */
      BackgroundTexture.prototype.rotate = function (angle) {
          if (angle % 90 == 0) {
              this._rotation_angle.set(function (x) { return x + angle; });
              this._rotation_mode.set(1);
          }
          else {
              Api.print("You have passed wrong angle - " + angle + ". Rotation is available with angle value divisible by 90.");
          }
          return this;
      };
      /** Sets BG texture content (scaling) mode */
      BackgroundTexture.prototype.setBGContentMode = function (mode) {
          switch (mode) {
              case "aspect_fill":
                  this._contentMode.set(1);
                  break;
              case "aspect_fit":
                  this._contentMode.set(2);
                  break;
              case "scale_to_fill":
                  this._contentMode.set(3);
                  break;
              default:
                  Api.print("You've set wrong BG Content mode: " + mode);
          }
          return this;
      };
      /** Scales the background texture */
      BackgroundTexture.prototype.scale = function (factor) {
          this._scaling.set(function (x) { return x * factor; });
          return this;
      };
      /** Removes the background texture, resets background rotation and scaling */
      BackgroundTexture.prototype.clear = function () {
          this._mesh.disable();
          this._rotation_angle.set(0);
          this._rotation_mode.set(0);
          this._scaling.set(1);
          return this;
      };
      __decorate([
          json
      ], BackgroundTexture.prototype, "set", null);
      __decorate([
          json
      ], BackgroundTexture.prototype, "setInitialRotation", null);
      __decorate([
          json
      ], BackgroundTexture.prototype, "rotate", null);
      __decorate([
          json
      ], BackgroundTexture.prototype, "setBGContentMode", null);
      __decorate([
          json
      ], BackgroundTexture.prototype, "scale", null);
      return BackgroundTexture;
  }());
  /** Global BackgroundTexture instance */
  var backgroundTexture = /*@__PURE__*/ new BackgroundTexture();

  var mesh$3 = "triBG_video.bsm2";

  var js_bg_rotation = 14;
  var js_bg_scale = 15;
  var js_bg_content_mode = 17;
  /**
   * Sets background behind a body to a video/GIF
   * @example
   * ```ts
   * const bg = new BackgroundVideo()
   *  .set("video.mp4") or .set("image.gif")
   *  .scale(1.2)
   *  .rotate(90) , only [0,90,-90,180,270] angle values are available
   * ```
   */
  var BackgroundVideo = /*@__PURE__*/ (function () {
      function BackgroundVideo() {
          var _this = this;
          this._isMirrored = new Vec4(js_is_screen_Mirrored).x;
          this._mesh = new Mesh(mesh$3)
            .on("enabled", function () {
                recognizer.enable("background");
                faceTracker
                    .on("face", _this._trackMirroring)
                    .on("no-face", _this._trackMirroring);
                })
            .on("disabled", function () { 
                recognizer.disable("background"); 
                faceTracker
                    .off("face", _this._trackMirroring)
                    .off("no-face", _this._trackMirroring);
            });
          this._video = new Video("video.mp4", true, 1);
          this._rotation_angle = new Vec4(js_bg_rotation).x.set(0);
          this._rotation_mode = new Vec4(js_bg_rotation).y.set(0);
          this._scaling = new Vec4(js_bg_scale).x.set(1);
          this._contentMode = new Vec4(js_bg_content_mode).x.set(1);
          this._trackMirroring = function () { return _this._isMirrored.set(isMirrored());};
      }
      /** Sets the file as background texture*/
      BackgroundVideo.prototype.set = function (video) {
          this._mesh.enable();
          this._video.set(video);
          this._video.play(true);
          return this;
      };
      /** Sets initial the background video/gif angle in degrees (used for videos with angle !=0 in metadata) */
      BackgroundVideo.prototype.setInitialRotation = function (angle) {
          if (angle % 90 == 0) {
              this._rotation_angle.set(function (x) { return x + angle; });
              this._rotation_mode.set(0);
          }
          else {
              Api.print("You have passed wrong angle - " + angle + ". Rotation is available with angle value divisible by 90.");
          }
          return this;
      };
      /** Rotates the background texture clockwise in degrees */
      BackgroundVideo.prototype.rotate = function (angle) {
          if (angle % 90 == 0) {
              this._rotation_angle.set(function (x) { return x + angle; });
              this._rotation_mode.set(1);
          }
          else {
              Api.print("You have passed wrong angle - " + angle + ". Rotation is available with angle value divisible by 90.");
          }
          return this;
      };
      /** Sets BG texture content (scaling) mode */
      BackgroundVideo.prototype.setBGContentMode = function (mode) {
          switch (mode) {
              case "aspect_fill":
                  this._contentMode.set(1);
                  break;
              case "aspect_fit":
                  this._contentMode.set(2);
                  break;
              case "scale_to_fill":
                  this._contentMode.set(3);
                  break;
              default:
                  Api.print("You've set wrong BG Content mode: " + mode);
          }
          return this;
      };
      /** Scales the background texture */
      BackgroundVideo.prototype.scale = function (factor) {
          this._scaling.set(function (x) { return x * factor; });
          return this;
      };
      /** Removes the background texture, resets background rotation and scaling */
      BackgroundVideo.prototype.clear = function () {
          this._mesh.disable();
          this._video.stop();
          this._rotation_angle.set(0);
          this._rotation_mode.set(0);
          this._scaling.set(1);
          return this;
      };
      __decorate([
          json
      ], BackgroundVideo.prototype, "set", null);
      __decorate([
          json
      ], BackgroundVideo.prototype, "setInitialRotation", null);
      __decorate([
          json
      ], BackgroundVideo.prototype, "rotate", null);
      __decorate([
          json
      ], BackgroundVideo.prototype, "setBGContentMode", null);
      __decorate([
          json
      ], BackgroundVideo.prototype, "scale", null);
      return BackgroundVideo;
  }());
  /** Global BackgroundTexture instance */
  var backgroundVideo = /*@__PURE__*/ new BackgroundVideo();

  var mesh$2 = "tri_transparent.bsm2";

  var js_bg_alpha = 16;

  /**
   * Makes background behind a body transparent
   * @example
   * ```ts
   * const bg = new BackgroundTransparent()
   *  .enable()
   * ```
   */
  var BackgroundTranparent = /*@__PURE__*/ (function () {
      function BackgroundTranparent() {
          this._mesh = new Mesh(mesh$2)
              .on("enabled", function () { return recognizer.enable("background"); })
              .on("disabled", function () { return recognizer.disable("background"); });
          this._transparency = new Vec4(js_bg_alpha).x.set(1);
      }
      /** Sets opacity value for background behind a body in [0.,1.] range */
      BackgroundTranparent.prototype.opacity = function (value) {
          if (value >= 1) {
              this._mesh.disable();
          }
          else {
              this._mesh.enable();
              this._transparency.set(1. - value);
          }
          return this;
      };
      __decorate([
          json
      ], BackgroundTranparent.prototype, "opacity", null);
      return BackgroundTranparent;
  }());
  /** Global BackgroundTransparency instance */
  var backgroundTransparent = /*@__PURE__*/ new BackgroundTranparent();

  var mesh$1 = "tri_Blur.bsm2";

  var js_bg_blur_radius = 18;

  /** Blurs background behind a body */
  var BackgroundBlur = /*@__PURE__*/ (function () {
      function BackgroundBlur() {
          this._mesh = new Mesh(mesh$1)
              .on("enabled", function () { return recognizer.enable("background"); })
              .on("disabled", function () { return recognizer.disable("background"); });
          this._radius = new Vec4(js_bg_blur_radius).x.set(2.);
      }
      /** Enables background blur */
      BackgroundBlur.prototype.enable = function () {
          this._mesh.enable();
          return this;
      };
      /** Sets background blur radius */
      BackgroundBlur.prototype.setRadius = function (value) {
          this._radius.set(value * 10);
          return this;
      };
      /** Disables background blur */
      BackgroundBlur.prototype.disable = function () {
          this._mesh.disable();
          return this;
      };
      return BackgroundBlur;
  }());
  /** Global BackgroundBlur instance */
  var backgroundBlur = /*@__PURE__*/ new BackgroundBlur();

  var version = "0.35.0";

  /**
   * Effect for virtual Beautification try on
   * @packageDocumentation
   * @module Makup
   * @external
   */
  configure({
      faceActions: [faceTracker.emitFaceDetected],
      noFaceActions: [faceTracker.emitNoFaceDetected],
      videoRecordStartActions: [],
      videoRecordFinishActions: [],
      videoRecordDiscardActions: [],
      init: function () {
      },
      restart: function () {
          Api.meshfxReset();
          this.init();
      },
  });
  var printVersion = function () { return Api.print("Makeup effect v" + version); };
  /**
   * The effect test function
   * @hidden
   * @example
   * Web:
   * ```js
   * player.callJsMethod("test")
   * ```
   **/
  //@ts-ignore
  function test() {
      backgroundBlur.enable();
  }

  exports.BackgroundBlur = backgroundBlur;
  exports.BackgroundTexture = backgroundTexture;
  exports.BackgroundTranparent = backgroundTransparent;
  exports.BackgroundVideo = backgroundVideo;
  exports.Recognizer = recognizer;
  exports.VERSION = version;
  exports.printVersion = printVersion;
  exports.test = test;

  Object.defineProperty(exports, '__esModule', { value: true });


      var globalThis = new Function("return this;")();
      
      for (var key in exports) { globalThis[key] = exports[key]; }
      
      // bugfix: SDK's `callJsMethod` can not call nested (e.b. `foo.bar()`) methods
      for (var key in exports) {
        var value = exports[key];
      
        if (value === null) continue;
        if (typeof value !== "object") continue;
      
        for (var method in Object.getPrototypeOf(value)) {
            var fn = value[method];
            globalThis[key + "." + method] = fn.bind(value);
        }
      }
      

  return exports;

}({}));

function setBackgroundMedia(args_json) {
    args = JSON.parse(args_json)

    if (args.type == "video") {
        BackgroundVideo.set(args.path).setInitialRotation(args.orientation)
    } else if (args.type == "image") {
        BackgroundTexture.set(args.path).setInitialRotation(args.orientation)
    } else {
        Api.print("unknown background media type - " + args.type)
    }
}

function enableFRX() {
    Recognizer.disable("frx_disabled")
}

function disableFRX(){
    Recognizer.enable("frx_disabled")
}

function setBackgroundTexture(file){
    BackgroundTexture.set(file);
}

function setBackgroundVideo(file) {
    BackgroundVideo.set(file);
}

function initBackground() {
}

function deleteBackground(params) {
    BackgroundTexture.clear();
    BackgroundVideo.clear();
}

function initBlurBackground() {
    BackgroundBlur.enable();
}

function setBlurRadius(radius) {
    var processedRadius = (radius - 3) / 5;
    BackgroundBlur.setRadius(processedRadius);
}

function deleteBlurBackground(params) {
    BackgroundBlur.disable();
}

function initTransparentBG(params) {
    BackgroundTranparent.opacity(0)
}

function deleteTransparentBG(params) {
    BackgroundTranparent.opacity(1)
}

function isMirrored(){
    switch(Api.isMirrored()){
        case true: 
            return 1;
            break;
        case false:
            return -1;
            break;
        default:
            break;
    }
}

disableFRX(); // frx is disabled by default

/* Feel free to add your custom code below */