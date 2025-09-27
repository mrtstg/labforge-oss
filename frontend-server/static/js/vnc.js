var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);
(async () => {
  (function() {
    const t = document.createElement("link").relList;
    if (t && t.supports && t.supports("modulepreload")) return;
    for (const i of document.querySelectorAll('link[rel="modulepreload"]')) r(i);
    new MutationObserver((i) => {
      for (const a of i) if (a.type === "childList") for (const o of a.addedNodes) o.tagName === "LINK" && o.rel === "modulepreload" && r(o);
    }).observe(document, {
      childList: true,
      subtree: true
    });
    function n(i) {
      const a = {};
      return i.integrity && (a.integrity = i.integrity), i.referrerPolicy && (a.referrerPolicy = i.referrerPolicy), i.crossOrigin === "use-credentials" ? a.credentials = "include" : i.crossOrigin === "anonymous" ? a.credentials = "omit" : a.credentials = "same-origin", a;
    }
    function r(i) {
      if (i.ep) return;
      i.ep = true;
      const a = n(i);
      fetch(i.href, a);
    }
  })();
  function Jt() {
  }
  function Wa(e) {
    return e();
  }
  function Di() {
    return /* @__PURE__ */ Object.create(null);
  }
  function xr(e) {
    e.forEach(Wa);
  }
  function za(e) {
    return typeof e == "function";
  }
  function vn(e, t) {
    return e != e ? t == t : e !== t || e && typeof e == "object" || typeof e == "function";
  }
  function ws(e) {
    return Object.keys(e).length === 0;
  }
  function Ge(e, t) {
    e.appendChild(t);
  }
  function Ur(e, t, n) {
    e.insertBefore(t, n || null);
  }
  function gr(e) {
    e.parentNode && e.parentNode.removeChild(e);
  }
  function _t(e) {
    return document.createElement(e);
  }
  function hr(e) {
    return document.createTextNode(e);
  }
  function Xr() {
    return hr(" ");
  }
  function ks() {
    return hr("");
  }
  function tn(e, t, n, r) {
    return e.addEventListener(t, n, r), () => e.removeEventListener(t, n, r);
  }
  function ft(e, t, n) {
    n == null ? e.removeAttribute(t) : e.getAttribute(t) !== n && e.setAttribute(t, n);
  }
  function Ss(e) {
    return Array.from(e.childNodes);
  }
  function Un(e, t) {
    t = "" + t, e.data !== t && (e.data = t);
  }
  function Oi(e, t) {
    e.value = t ?? "";
  }
  let Lr;
  function Cr(e) {
    Lr = e;
  }
  function Es() {
    if (!Lr) throw new Error("Function called outside component initialization");
    return Lr;
  }
  function Ga(e) {
    Es().$$.on_mount.push(e);
  }
  const fr = [], Nn = [];
  let dr = [];
  const Bi = [], Ks = Promise.resolve();
  let jn = false;
  function Xs() {
    jn || (jn = true, Ks.then(Va));
  }
  function Hn(e) {
    dr.push(e);
  }
  const Fn = /* @__PURE__ */ new Set();
  let ur = 0;
  function Va() {
    if (ur !== 0) return;
    const e = Lr;
    do {
      try {
        for (; ur < fr.length; ) {
          const t = fr[ur];
          ur++, Cr(t), Fs(t.$$);
        }
      } catch (t) {
        throw fr.length = 0, ur = 0, t;
      }
      for (Cr(null), fr.length = 0, ur = 0; Nn.length; ) Nn.pop()();
      for (let t = 0; t < dr.length; t += 1) {
        const n = dr[t];
        Fn.has(n) || (Fn.add(n), n());
      }
      dr.length = 0;
    } while (fr.length);
    for (; Bi.length; ) Bi.pop()();
    jn = false, Fn.clear(), Cr(e);
  }
  function Fs(e) {
    if (e.fragment !== null) {
      e.update(), xr(e.before_update);
      const t = e.dirty;
      e.dirty = [
        -1
      ], e.fragment && e.fragment.p(e.ctx, t), e.after_update.forEach(Hn);
    }
  }
  function Cs(e) {
    const t = [], n = [];
    dr.forEach((r) => e.indexOf(r) === -1 ? t.push(r) : n.push(r)), n.forEach((r) => r()), dr = t;
  }
  const sn = /* @__PURE__ */ new Set();
  let qt;
  function Za() {
    qt = {
      r: 0,
      c: [],
      p: qt
    };
  }
  function qa() {
    qt.r || xr(qt.c), qt = qt.p;
  }
  function Nt(e, t) {
    e && e.i && (sn.delete(e), e.i(t));
  }
  function pr(e, t, n, r) {
    if (e && e.o) {
      if (sn.has(e)) return;
      sn.add(e), qt.c.push(() => {
        sn.delete(e), r && (n && e.d(1), r());
      }), e.o(t);
    } else r && r();
  }
  function Ya(e) {
    e && e.c();
  }
  function ai(e, t, n) {
    const { fragment: r, after_update: i } = e.$$;
    r && r.m(t, n), Hn(() => {
      const a = e.$$.on_mount.map(Wa).filter(za);
      e.$$.on_destroy ? e.$$.on_destroy.push(...a) : xr(a), e.$$.on_mount = [];
    }), i.forEach(Hn);
  }
  function oi(e, t) {
    const n = e.$$;
    n.fragment !== null && (Cs(n.after_update), xr(n.on_destroy), n.fragment && n.fragment.d(t), n.on_destroy = n.fragment = null, n.ctx = []);
  }
  function As(e, t) {
    e.$$.dirty[0] === -1 && (fr.push(e), Xs(), e.$$.dirty.fill(0)), e.$$.dirty[t / 31 | 0] |= 1 << t % 31;
  }
  function si(e, t, n, r, i, a, o = null, s = [
    -1
  ]) {
    const y = Lr;
    Cr(e);
    const u = e.$$ = {
      fragment: null,
      ctx: [],
      props: a,
      update: Jt,
      not_equal: i,
      bound: Di(),
      on_mount: [],
      on_destroy: [],
      on_disconnect: [],
      before_update: [],
      after_update: [],
      context: new Map(t.context || (y ? y.$$.context : [])),
      callbacks: Di(),
      dirty: s,
      skip_bound: false,
      root: t.target || y.$$.root
    };
    o && o(u.root);
    let l = false;
    if (u.ctx = n ? n(e, t.props || {}, (k, X, ...g) => {
      const b = g.length ? g[0] : X;
      return u.ctx && i(u.ctx[k], u.ctx[k] = b) && (!u.skip_bound && u.bound[k] && u.bound[k](b), l && As(e, k)), X;
    }) : [], u.update(), l = true, xr(u.before_update), u.fragment = r ? r(u.ctx) : false, t.target) {
      if (t.hydrate) {
        const k = Ss(t.target);
        u.fragment && u.fragment.l(k), k.forEach(gr);
      } else u.fragment && u.fragment.c();
      t.intro && Nt(e.$$.fragment), ai(e, t.target, t.anchor), Va();
    }
    Cr(y);
  }
  class ui {
    constructor() {
      __publicField(this, "$$");
      __publicField(this, "$$set");
    }
    $destroy() {
      oi(this, 1), this.$destroy = Jt;
    }
    $on(t, n) {
      if (!za(n)) return Jt;
      const r = this.$$.callbacks[t] || (this.$$.callbacks[t] = []);
      return r.push(n), () => {
        const i = r.indexOf(n);
        i !== -1 && r.splice(i, 1);
      };
    }
    $set(t) {
      this.$$set && !ws(t) && (this.$$.skip_bound = true, this.$$set(t), this.$$.skip_bound = false);
    }
  }
  const Ps = "4";
  typeof window < "u" && (window.__svelte || (window.__svelte = {
    v: /* @__PURE__ */ new Set()
  })).v.add(Ps);
  function Ts(e) {
    return e && e.__esModule && Object.prototype.hasOwnProperty.call(e, "default") ? e.default : e;
  }
  var $a = {}, Nr = {};
  Object.defineProperty(Nr, "__esModule", {
    value: true
  });
  Nr.toSigned32bit = Rs;
  Nr.toUnsigned32bit = Ls;
  function Ls(e) {
    return e >>> 0;
  }
  function Rs(e) {
    return e | 0;
  }
  var Re = {};
  Object.defineProperty(Re, "__esModule", {
    value: true
  });
  Re.Warn = Re.Info = Re.Error = Re.Debug = void 0;
  Re.getLogging = Ms;
  Re.initLogging = Ja;
  var Wn = "warn";
  Re.Debug = function() {
  };
  Re.Info = function() {
  };
  Re.Warn = function() {
  };
  Re.Error = function() {
  };
  function Ja(e) {
    if (typeof e > "u" ? e = Wn : Wn = e, Re.Debug = Re.Info = Re.Warn = Re.Error = function() {
    }, typeof window.console < "u") switch (e) {
      case "debug":
        Re.Debug = console.debug.bind(window.console);
      case "info":
        Re.Info = console.info.bind(window.console);
      case "warn":
        Re.Warn = console.warn.bind(window.console);
      case "error":
        Re.Error = console.error.bind(window.console);
      case "none":
        break;
      default:
        throw new window.Error("invalid logging type '" + e + "'");
    }
  }
  function Ms() {
    return Wn;
  }
  Ja();
  var jr = {};
  Object.defineProperty(jr, "__esModule", {
    value: true
  });
  jr.decodeUTF8 = Ds;
  jr.encodeUTF8 = Os;
  function Ds(e) {
    var t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : false;
    try {
      return decodeURIComponent(escape(e));
    } catch (n) {
      if (n instanceof URIError && t) return e;
      throw n;
    }
  }
  function Os(e) {
    return unescape(encodeURIComponent(e));
  }
  var Ae = {}, yn = {};
  (function(e) {
    function t(a) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(o) {
        return typeof o;
      } : function(o) {
        return o && typeof Symbol == "function" && o.constructor === Symbol && o !== Symbol.prototype ? "symbol" : typeof o;
      }, t(a);
    }
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var n = i(Re);
    function r(a) {
      if (typeof WeakMap != "function") return null;
      var o = /* @__PURE__ */ new WeakMap(), s = /* @__PURE__ */ new WeakMap();
      return (r = function(u) {
        return u ? s : o;
      })(a);
    }
    function i(a, o) {
      if (a && a.__esModule) return a;
      if (a === null || t(a) != "object" && typeof a != "function") return {
        default: a
      };
      var s = r(o);
      if (s && s.has(a)) return s.get(a);
      var y = {
        __proto__: null
      }, u = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var l in a) if (l !== "default" && {}.hasOwnProperty.call(a, l)) {
        var k = u ? Object.getOwnPropertyDescriptor(a, l) : null;
        k && (k.get || k.set) ? Object.defineProperty(y, l, k) : y[l] = a[l];
      }
      return y.default = a, s && s.set(a, y), y;
    }
    e.default = {
      toBase64Table: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".split(""),
      base64Pad: "=",
      encode: function(o) {
        for (var s = "", y = o.length, u = y % 3, l = 0; l < y - 2; l += 3) s += this.toBase64Table[o[l] >> 2], s += this.toBase64Table[((o[l] & 3) << 4) + (o[l + 1] >> 4)], s += this.toBase64Table[((o[l + 1] & 15) << 2) + (o[l + 2] >> 6)], s += this.toBase64Table[o[l + 2] & 63];
        var k = y - u;
        return u === 2 ? (s += this.toBase64Table[o[k] >> 2], s += this.toBase64Table[((o[k] & 3) << 4) + (o[k + 1] >> 4)], s += this.toBase64Table[(o[k + 1] & 15) << 2], s += this.toBase64Table[64]) : u === 1 && (s += this.toBase64Table[o[k] >> 2], s += this.toBase64Table[(o[k] & 3) << 4], s += this.toBase64Table[64], s += this.toBase64Table[64]), s;
      },
      toBinaryTable: [
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        62,
        -1,
        -1,
        -1,
        63,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        -1,
        -1,
        -1,
        0,
        -1,
        -1,
        -1,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        -1,
        -1,
        -1,
        -1,
        -1
      ],
      decode: function(o) {
        var s = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : 0, y = o.indexOf("=") - s;
        y < 0 && (y = o.length - s);
        for (var u = (y >> 2) * 3 + Math.floor(y % 4 / 1.5), l = new Array(u), k = 0, X = 0, g = 0, b = s; b < o.length; b++) {
          var d = this.toBinaryTable[o.charCodeAt(b) & 127], f = o.charAt(b) === this.base64Pad;
          if (d === -1) {
            n.Error("Illegal character code " + o.charCodeAt(b) + " at position " + b);
            continue;
          }
          X = X << 6 | d, k += 6, k >= 8 && (k -= 8, f || (l[g++] = X >> k & 255), X &= (1 << k) - 1);
        }
        if (k) {
          var c = new Error("Corrupted base64 string");
          throw c.name = "Base64-Error", c;
        }
        return l;
      }
    };
  })(yn);
  Object.defineProperty(Ae, "__esModule", {
    value: true
  });
  Ae.hasScrollbarGutter = Ae.dragThreshold = void 0;
  Ae.isAndroid = Gs;
  Ae.isBlink = nu;
  Ae.isChrome = Ys;
  Ae.isChromeOS = Vs;
  Ae.isChromium = $s;
  Ae.isEdge = eu;
  Ae.isFirefox = qs;
  Ae.isGecko = tu;
  Ae.isIOS = zs;
  Ae.isMac = Hs;
  Ae.isOpera = Js;
  Ae.isSafari = Zs;
  Ae.isTouchDevice = void 0;
  Ae.isWebKit = ru;
  Ae.isWindows = Ws;
  Ae.supportsWebCodecsH264Decode = Ae.supportsCursorURIs = void 0;
  var un = Qs(Re), Bs = Is(yn);
  function Is(e) {
    return e && e.__esModule ? e : {
      default: e
    };
  }
  function eo(e) {
    if (typeof WeakMap != "function") return null;
    var t = /* @__PURE__ */ new WeakMap(), n = /* @__PURE__ */ new WeakMap();
    return (eo = function(i) {
      return i ? n : t;
    })(e);
  }
  function Qs(e, t) {
    if (e && e.__esModule) return e;
    if (e === null || Rr(e) != "object" && typeof e != "function") return {
      default: e
    };
    var n = eo(t);
    if (n && n.has(e)) return n.get(e);
    var r = {
      __proto__: null
    }, i = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for (var a in e) if (a !== "default" && {}.hasOwnProperty.call(e, a)) {
      var o = i ? Object.getOwnPropertyDescriptor(e, a) : null;
      o && (o.get || o.set) ? Object.defineProperty(r, a, o) : r[a] = e[a];
    }
    return r.default = e, n && n.set(e, r), r;
  }
  function Rr(e) {
    "@babel/helpers - typeof";
    return Rr = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, Rr(e);
  }
  function zn() {
    zn = function() {
      return t;
    };
    var e, t = {}, n = Object.prototype, r = n.hasOwnProperty, i = Object.defineProperty || function(E, p, m) {
      E[p] = m.value;
    }, a = typeof Symbol == "function" ? Symbol : {}, o = a.iterator || "@@iterator", s = a.asyncIterator || "@@asyncIterator", y = a.toStringTag || "@@toStringTag";
    function u(E, p, m) {
      return Object.defineProperty(E, p, {
        value: m,
        enumerable: true,
        configurable: true,
        writable: true
      }), E[p];
    }
    try {
      u({}, "");
    } catch {
      u = function(m, L, B) {
        return m[L] = B;
      };
    }
    function l(E, p, m, L) {
      var B = p && p.prototype instanceof c ? p : c, M = Object.create(B.prototype), V = new $(L || []);
      return i(M, "_invoke", {
        value: O(E, m, V)
      }), M;
    }
    function k(E, p, m) {
      try {
        return {
          type: "normal",
          arg: E.call(p, m)
        };
      } catch (L) {
        return {
          type: "throw",
          arg: L
        };
      }
    }
    t.wrap = l;
    var X = "suspendedStart", g = "suspendedYield", b = "executing", d = "completed", f = {};
    function c() {
    }
    function h() {
    }
    function K() {
    }
    var x = {};
    u(x, o, function() {
      return this;
    });
    var F = Object.getPrototypeOf, S = F && F(F(ne([])));
    S && S !== n && r.call(S, o) && (x = S);
    var w = K.prototype = c.prototype = Object.create(x);
    function C(E) {
      [
        "next",
        "throw",
        "return"
      ].forEach(function(p) {
        u(E, p, function(m) {
          return this._invoke(p, m);
        });
      });
    }
    function A(E, p) {
      function m(B, M, V, re) {
        var oe = k(E[B], E, M);
        if (oe.type !== "throw") {
          var ce = oe.arg, pe = ce.value;
          return pe && Rr(pe) == "object" && r.call(pe, "__await") ? p.resolve(pe.__await).then(function(ye) {
            m("next", ye, V, re);
          }, function(ye) {
            m("throw", ye, V, re);
          }) : p.resolve(pe).then(function(ye) {
            ce.value = ye, V(ce);
          }, function(ye) {
            return m("throw", ye, V, re);
          });
        }
        re(oe.arg);
      }
      var L;
      i(this, "_invoke", {
        value: function(M, V) {
          function re() {
            return new p(function(oe, ce) {
              m(M, V, oe, ce);
            });
          }
          return L = L ? L.then(re, re) : re();
        }
      });
    }
    function O(E, p, m) {
      var L = X;
      return function(B, M) {
        if (L === b) throw Error("Generator is already running");
        if (L === d) {
          if (B === "throw") throw M;
          return {
            value: e,
            done: true
          };
        }
        for (m.method = B, m.arg = M; ; ) {
          var V = m.delegate;
          if (V) {
            var re = I(V, m);
            if (re) {
              if (re === f) continue;
              return re;
            }
          }
          if (m.method === "next") m.sent = m._sent = m.arg;
          else if (m.method === "throw") {
            if (L === X) throw L = d, m.arg;
            m.dispatchException(m.arg);
          } else m.method === "return" && m.abrupt("return", m.arg);
          L = b;
          var oe = k(E, p, m);
          if (oe.type === "normal") {
            if (L = m.done ? d : g, oe.arg === f) continue;
            return {
              value: oe.arg,
              done: m.done
            };
          }
          oe.type === "throw" && (L = d, m.method = "throw", m.arg = oe.arg);
        }
      };
    }
    function I(E, p) {
      var m = p.method, L = E.iterator[m];
      if (L === e) return p.delegate = null, m === "throw" && E.iterator.return && (p.method = "return", p.arg = e, I(E, p), p.method === "throw") || m !== "return" && (p.method = "throw", p.arg = new TypeError("The iterator does not provide a '" + m + "' method")), f;
      var B = k(L, E.iterator, p.arg);
      if (B.type === "throw") return p.method = "throw", p.arg = B.arg, p.delegate = null, f;
      var M = B.arg;
      return M ? M.done ? (p[E.resultName] = M.value, p.next = E.nextLoc, p.method !== "return" && (p.method = "next", p.arg = e), p.delegate = null, f) : M : (p.method = "throw", p.arg = new TypeError("iterator result is not an object"), p.delegate = null, f);
    }
    function Z(E) {
      var p = {
        tryLoc: E[0]
      };
      1 in E && (p.catchLoc = E[1]), 2 in E && (p.finallyLoc = E[2], p.afterLoc = E[3]), this.tryEntries.push(p);
    }
    function q(E) {
      var p = E.completion || {};
      p.type = "normal", delete p.arg, E.completion = p;
    }
    function $(E) {
      this.tryEntries = [
        {
          tryLoc: "root"
        }
      ], E.forEach(Z, this), this.reset(true);
    }
    function ne(E) {
      if (E || E === "") {
        var p = E[o];
        if (p) return p.call(E);
        if (typeof E.next == "function") return E;
        if (!isNaN(E.length)) {
          var m = -1, L = function B() {
            for (; ++m < E.length; ) if (r.call(E, m)) return B.value = E[m], B.done = false, B;
            return B.value = e, B.done = true, B;
          };
          return L.next = L;
        }
      }
      throw new TypeError(Rr(E) + " is not iterable");
    }
    return h.prototype = K, i(w, "constructor", {
      value: K,
      configurable: true
    }), i(K, "constructor", {
      value: h,
      configurable: true
    }), h.displayName = u(K, y, "GeneratorFunction"), t.isGeneratorFunction = function(E) {
      var p = typeof E == "function" && E.constructor;
      return !!p && (p === h || (p.displayName || p.name) === "GeneratorFunction");
    }, t.mark = function(E) {
      return Object.setPrototypeOf ? Object.setPrototypeOf(E, K) : (E.__proto__ = K, u(E, y, "GeneratorFunction")), E.prototype = Object.create(w), E;
    }, t.awrap = function(E) {
      return {
        __await: E
      };
    }, C(A.prototype), u(A.prototype, s, function() {
      return this;
    }), t.AsyncIterator = A, t.async = function(E, p, m, L, B) {
      B === void 0 && (B = Promise);
      var M = new A(l(E, p, m, L), B);
      return t.isGeneratorFunction(p) ? M : M.next().then(function(V) {
        return V.done ? V.value : M.next();
      });
    }, C(w), u(w, y, "Generator"), u(w, o, function() {
      return this;
    }), u(w, "toString", function() {
      return "[object Generator]";
    }), t.keys = function(E) {
      var p = Object(E), m = [];
      for (var L in p) m.push(L);
      return m.reverse(), function B() {
        for (; m.length; ) {
          var M = m.pop();
          if (M in p) return B.value = M, B.done = false, B;
        }
        return B.done = true, B;
      };
    }, t.values = ne, $.prototype = {
      constructor: $,
      reset: function(p) {
        if (this.prev = 0, this.next = 0, this.sent = this._sent = e, this.done = false, this.delegate = null, this.method = "next", this.arg = e, this.tryEntries.forEach(q), !p) for (var m in this) m.charAt(0) === "t" && r.call(this, m) && !isNaN(+m.slice(1)) && (this[m] = e);
      },
      stop: function() {
        this.done = true;
        var p = this.tryEntries[0].completion;
        if (p.type === "throw") throw p.arg;
        return this.rval;
      },
      dispatchException: function(p) {
        if (this.done) throw p;
        var m = this;
        function L(ce, pe) {
          return V.type = "throw", V.arg = p, m.next = ce, pe && (m.method = "next", m.arg = e), !!pe;
        }
        for (var B = this.tryEntries.length - 1; B >= 0; --B) {
          var M = this.tryEntries[B], V = M.completion;
          if (M.tryLoc === "root") return L("end");
          if (M.tryLoc <= this.prev) {
            var re = r.call(M, "catchLoc"), oe = r.call(M, "finallyLoc");
            if (re && oe) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            } else if (re) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
            } else {
              if (!oe) throw Error("try statement without catch or finally");
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            }
          }
        }
      },
      abrupt: function(p, m) {
        for (var L = this.tryEntries.length - 1; L >= 0; --L) {
          var B = this.tryEntries[L];
          if (B.tryLoc <= this.prev && r.call(B, "finallyLoc") && this.prev < B.finallyLoc) {
            var M = B;
            break;
          }
        }
        M && (p === "break" || p === "continue") && M.tryLoc <= m && m <= M.finallyLoc && (M = null);
        var V = M ? M.completion : {};
        return V.type = p, V.arg = m, M ? (this.method = "next", this.next = M.finallyLoc, f) : this.complete(V);
      },
      complete: function(p, m) {
        if (p.type === "throw") throw p.arg;
        return p.type === "break" || p.type === "continue" ? this.next = p.arg : p.type === "return" ? (this.rval = this.arg = p.arg, this.method = "return", this.next = "end") : p.type === "normal" && m && (this.next = m), f;
      },
      finish: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.finallyLoc === p) return this.complete(L.completion, L.afterLoc), q(L), f;
        }
      },
      catch: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.tryLoc === p) {
            var B = L.completion;
            if (B.type === "throw") {
              var M = B.arg;
              q(L);
            }
            return M;
          }
        }
        throw Error("illegal catch attempt");
      },
      delegateYield: function(p, m, L) {
        return this.delegate = {
          iterator: ne(p),
          resultName: m,
          nextLoc: L
        }, this.method === "next" && (this.arg = e), f;
      }
    }, t;
  }
  function Ii(e, t, n, r, i, a, o) {
    try {
      var s = e[a](o), y = s.value;
    } catch (u) {
      return void n(u);
    }
    s.done ? t(y) : Promise.resolve(y).then(r, i);
  }
  function Us(e) {
    return function() {
      var t = this, n = arguments;
      return new Promise(function(r, i) {
        var a = e.apply(t, n);
        function o(y) {
          Ii(a, r, i, o, s, "next", y);
        }
        function s(y) {
          Ii(a, r, i, o, s, "throw", y);
        }
        o(void 0);
      });
    };
  }
  Ae.isTouchDevice = "ontouchstart" in document.documentElement || document.ontouchstart !== void 0 || navigator.maxTouchPoints > 0 || navigator.msMaxTouchPoints > 0;
  window.addEventListener("touchstart", function e() {
    Ae.isTouchDevice = true, window.removeEventListener("touchstart", e, false);
  }, false);
  Ae.dragThreshold = 10 * (window.devicePixelRatio || 1);
  var to = false;
  try {
    var Qi = document.createElement("canvas");
    Qi.style.cursor = 'url("data:image/x-icon;base64,AAACAAEACAgAAAIAAgA4AQAAFgAAACgAAAAIAAAAEAAAAAEAIAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAD/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////AAAAAAAAAAAAAAAAAAAAAA==") 2 2, default', Qi.style.cursor.indexOf("url") === 0 ? (un.Info("Data URI scheme cursor supported"), to = true) : un.Warn("Data URI scheme cursor not supported");
  } catch (e) {
    un.Error("Data URI scheme cursor test exception: " + e);
  }
  Ae.supportsCursorURIs = to;
  var ro = true;
  try {
    var Gt = document.createElement("div");
    Gt.style.visibility = "hidden", Gt.style.overflow = "scroll", document.body.appendChild(Gt);
    var Ui = document.createElement("div");
    Gt.appendChild(Ui);
    var Ns = Gt.offsetWidth - Ui.offsetWidth;
    Gt.parentNode.removeChild(Gt), ro = Ns != 0;
  } catch (e) {
    un.Error("Scrollbar test exception: " + e);
  }
  Ae.hasScrollbarGutter = ro;
  Ae.supportsWebCodecsH264Decode = false;
  function js() {
    return Gn.apply(this, arguments);
  }
  function Gn() {
    return Gn = Us(zn().mark(function e() {
      var t, n, r, i, a, o, s;
      return zn().wrap(function(u) {
        for (; ; ) switch (u.prev = u.next) {
          case 0:
            if ("VideoDecoder" in window) {
              u.next = 2;
              break;
            }
            return u.abrupt("return", false);
          case 2:
            return t = {
              codec: "avc1.42401f",
              codedWidth: 1920,
              codedHeight: 1080,
              optimizeForLatency: true
            }, u.next = 5, VideoDecoder.isConfigSupported(t);
          case 5:
            if (n = u.sent, n.supported) {
              u.next = 8;
              break;
            }
            return u.abrupt("return", false);
          case 8:
            return r = new Uint8Array(Bs.default.decode("AAAAAWdCwBTZnpuAgICgAAADACAAAAZB4oVNAAAAAWjJYyyAAAABBgX//4HcRem95tlIt5Ys2CDZI+7veDI2NCAtIGNvcmUgMTY0IHIzMTA4IDMxZTE5ZjkgLSBILjI2NC9NUEVHLTQgQVZDIGNvZGVjIC0gQ29weWxlZnQgMjAwMy0yMDIzIC0gaHR0cDovL3d3dy52aWRlb2xhbi5vcmcveDI2NC5odG1sIC0gb3B0aW9uczogY2FiYWM9MCByZWY9NSBkZWJsb2NrPTE6MDowIGFuYWx5c2U9MHgxOjB4MTExIG1lPWhleCBzdWJtZT04IHBzeT0xIHBzeV9yZD0xLjAwOjAuMDAgbWl4ZWRfcmVmPTEgbWVfcmFuZ2U9MTYgY2hyb21hX21lPTEgdHJlbGxpcz0yIDh4OGRjdD0wIGNxbT0wIGRlYWR6b25lPTIxLDExIGZhc3RfcHNraXA9MSBjaHJvbWFfcXBfb2Zmc2V0PS0yIHRocmVhZHM9MSBsb29rYWhlYWRfdGhyZWFkcz0xIHNsaWNlZF90aHJlYWRzPTAgbnI9MCBkZWNpbWF0ZT0xIGludGVybGFjZWQ9MCBibHVyYXlfY29tcGF0PTAgY29uc3RyYWluZWRfaW50cmE9MCBiZnJhbWVzPTAgd2VpZ2h0cD0wIGtleWludD1pbmZpbml0ZSBrZXlpbnRfbWluPTI1IHNjZW5lY3V0PTQwIGludHJhX3JlZnJlc2g9MCByY19sb29rYWhlYWQ9NTAgcmM9YWJyIG1idHJlZT0xIGJpdHJhdGU9NDAwIHJhdGV0b2w9MS4wIHFjb21wPTAuNjAgcXBtaW49MCBxcG1heD02OSBxcHN0ZXA9NCBpcF9yYXRpbz0xLjQwIGFxPTE6MS4wMACAAAABZYiEBrxmKAAPVccAAS044AA5DRJMnkycJk4TPw==")), i = false, a = null, o = new VideoDecoder({
              output: function(k) {
                i = true;
              },
              error: function(k) {
                a = k;
              }
            }), s = new EncodedVideoChunk({
              timestamp: 0,
              type: "key",
              data: r
            }), o.configure(t), o.decode(s), u.prev = 15, u.next = 18, o.flush();
          case 18:
            u.next = 23;
            break;
          case 20:
            u.prev = 20, u.t0 = u.catch(15), a = u.t0;
          case 23:
            if (i) {
              u.next = 25;
              break;
            }
            return u.abrupt("return", false);
          case 25:
            if (a === null) {
              u.next = 27;
              break;
            }
            return u.abrupt("return", false);
          case 27:
            return u.abrupt("return", true);
          case 28:
          case "end":
            return u.stop();
        }
      }, e, null, [
        [
          15,
          20
        ]
      ]);
    })), Gn.apply(this, arguments);
  }
  Ae.supportsWebCodecsH264Decode = await js();
  function Hs() {
    return !!/mac/i.exec(navigator.platform);
  }
  function Ws() {
    return !!/win/i.exec(navigator.platform);
  }
  function zs() {
    return !!/ipad/i.exec(navigator.platform) || !!/iphone/i.exec(navigator.platform) || !!/ipod/i.exec(navigator.platform);
  }
  function Gs() {
    return !!navigator.userAgent.match("Android ");
  }
  function Vs() {
    return !!navigator.userAgent.match(" CrOS ");
  }
  function Zs() {
    return !!navigator.userAgent.match("Safari/...") && !navigator.userAgent.match("Chrome/...") && !navigator.userAgent.match("Chromium/...") && !navigator.userAgent.match("Epiphany/...");
  }
  function qs() {
    return !!navigator.userAgent.match("Firefox/...") && !navigator.userAgent.match("Seamonkey/...");
  }
  function Ys() {
    return !!navigator.userAgent.match("Chrome/...") && !navigator.userAgent.match("Chromium/...") && !navigator.userAgent.match("Edg/...") && !navigator.userAgent.match("OPR/...");
  }
  function $s() {
    return !!navigator.userAgent.match("Chromium/...");
  }
  function Js() {
    return !!navigator.userAgent.match("OPR/...");
  }
  function eu() {
    return !!navigator.userAgent.match("Edg/...");
  }
  function tu() {
    return !!navigator.userAgent.match("Gecko/...");
  }
  function ru() {
    return !!navigator.userAgent.match("AppleWebKit/...") && !navigator.userAgent.match("Chrome/...");
  }
  function nu() {
    return !!navigator.userAgent.match("Chrome/...");
  }
  var li = {};
  Object.defineProperty(li, "__esModule", {
    value: true
  });
  li.clientToElement = iu;
  function iu(e, t, n) {
    var r = n.getBoundingClientRect(), i = {
      x: 0,
      y: 0
    };
    return e < r.left ? i.x = 0 : e >= r.right ? i.x = r.width - 1 : i.x = e - r.left, t < r.top ? i.y = 0 : t >= r.bottom ? i.y = r.height - 1 : i.y = t - r.top, i;
  }
  var ar = {};
  Object.defineProperty(ar, "__esModule", {
    value: true
  });
  ar.getPointerEvent = au;
  ar.releaseCapture = fi;
  ar.setCapture = su;
  ar.stopEvent = ou;
  function au(e) {
    return e.changedTouches ? e.changedTouches[0] : e.touches ? e.touches[0] : e;
  }
  function ou(e) {
    e.stopPropagation(), e.preventDefault();
  }
  var Cn = false, no = null;
  document.captureElement = null;
  function Zt(e) {
    if (!Cn) {
      var t = new e.constructor(e.type, e);
      Cn = true, document.captureElement ? document.captureElement.dispatchEvent(t) : no.dispatchEvent(t), Cn = false, e.stopPropagation(), t.defaultPrevented && e.preventDefault(), e.type === "mouseup" && fi();
    }
  }
  function io() {
    var e = document.getElementById("noVNC_mouse_capture_elem");
    e.style.cursor = window.getComputedStyle(document.captureElement).cursor;
  }
  var ao = new MutationObserver(io);
  function su(e) {
    if (e.setCapture) e.setCapture(), document.captureElement = e;
    else {
      fi();
      var t = document.getElementById("noVNC_mouse_capture_elem");
      t === null && (t = document.createElement("div"), t.id = "noVNC_mouse_capture_elem", t.style.position = "fixed", t.style.top = "0px", t.style.left = "0px", t.style.width = "100%", t.style.height = "100%", t.style.zIndex = 1e4, t.style.display = "none", document.body.appendChild(t), t.addEventListener("contextmenu", Zt), t.addEventListener("mousemove", Zt), t.addEventListener("mouseup", Zt)), document.captureElement = e, ao.observe(e, {
        attributes: true
      }), io(), t.style.display = "", window.addEventListener("mousemove", Zt), window.addEventListener("mouseup", Zt);
    }
  }
  function fi() {
    if (document.releaseCapture) document.releaseCapture(), document.captureElement = null;
    else {
      if (!document.captureElement) return;
      no = document.captureElement, document.captureElement = null, ao.disconnect();
      var e = document.getElementById("noVNC_mouse_capture_elem");
      e.style.display = "none", window.removeEventListener("mousemove", Zt), window.removeEventListener("mouseup", Zt);
    }
  }
  var ci = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(s) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(y) {
        return typeof y;
      } : function(y) {
        return y && typeof Symbol == "function" && y.constructor === Symbol && y !== Symbol.prototype ? "symbol" : typeof y;
      }, t(s);
    }
    function n(s, y) {
      if (!(s instanceof y)) throw new TypeError("Cannot call a class as a function");
    }
    function r(s, y) {
      for (var u = 0; u < y.length; u++) {
        var l = y[u];
        l.enumerable = l.enumerable || false, l.configurable = true, "value" in l && (l.writable = true), Object.defineProperty(s, a(l.key), l);
      }
    }
    function i(s, y, u) {
      return y && r(s.prototype, y), Object.defineProperty(s, "prototype", {
        writable: false
      }), s;
    }
    function a(s) {
      var y = o(s, "string");
      return t(y) == "symbol" ? y : y + "";
    }
    function o(s, y) {
      if (t(s) != "object" || !s) return s;
      var u = s[Symbol.toPrimitive];
      if (u !== void 0) {
        var l = u.call(s, y);
        if (t(l) != "object") return l;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(s);
    }
    e.default = function() {
      function s() {
        n(this, s), this._listeners = /* @__PURE__ */ new Map();
      }
      return i(s, [
        {
          key: "addEventListener",
          value: function(u, l) {
            this._listeners.has(u) || this._listeners.set(u, /* @__PURE__ */ new Set()), this._listeners.get(u).add(l);
          }
        },
        {
          key: "removeEventListener",
          value: function(u, l) {
            this._listeners.has(u) && this._listeners.get(u).delete(l);
          }
        },
        {
          key: "dispatchEvent",
          value: function(u) {
            var l = this;
            return this._listeners.has(u.type) ? (this._listeners.get(u.type).forEach(function(k) {
              return k.call(l, u);
            }), !u.defaultPrevented) : true;
          }
        }
      ]);
    }();
  })(ci);
  var oo = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = o(Re), n = i(yn), r = Nr;
    function i(g) {
      return g && g.__esModule ? g : {
        default: g
      };
    }
    function a(g) {
      if (typeof WeakMap != "function") return null;
      var b = /* @__PURE__ */ new WeakMap(), d = /* @__PURE__ */ new WeakMap();
      return (a = function(c) {
        return c ? d : b;
      })(g);
    }
    function o(g, b) {
      if (g && g.__esModule) return g;
      if (g === null || s(g) != "object" && typeof g != "function") return {
        default: g
      };
      var d = a(b);
      if (d && d.has(g)) return d.get(g);
      var f = {
        __proto__: null
      }, c = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var h in g) if (h !== "default" && {}.hasOwnProperty.call(g, h)) {
        var K = c ? Object.getOwnPropertyDescriptor(g, h) : null;
        K && (K.get || K.set) ? Object.defineProperty(f, h, K) : f[h] = g[h];
      }
      return f.default = g, d && d.set(g, f), f;
    }
    function s(g) {
      "@babel/helpers - typeof";
      return s = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(b) {
        return typeof b;
      } : function(b) {
        return b && typeof Symbol == "function" && b.constructor === Symbol && b !== Symbol.prototype ? "symbol" : typeof b;
      }, s(g);
    }
    function y(g, b) {
      if (!(g instanceof b)) throw new TypeError("Cannot call a class as a function");
    }
    function u(g, b) {
      for (var d = 0; d < b.length; d++) {
        var f = b[d];
        f.enumerable = f.enumerable || false, f.configurable = true, "value" in f && (f.writable = true), Object.defineProperty(g, k(f.key), f);
      }
    }
    function l(g, b, d) {
      return b && u(g.prototype, b), Object.defineProperty(g, "prototype", {
        writable: false
      }), g;
    }
    function k(g) {
      var b = X(g, "string");
      return s(b) == "symbol" ? b : b + "";
    }
    function X(g, b) {
      if (s(g) != "object" || !g) return g;
      var d = g[Symbol.toPrimitive];
      if (d !== void 0) {
        var f = d.call(g, b);
        if (s(f) != "object") return f;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(g);
    }
    e.default = function() {
      function g(b) {
        if (y(this, g), this._drawCtx = null, this._renderQ = [], this._flushPromise = null, this._fbWidth = 0, this._fbHeight = 0, this._prevDrawStyle = "", t.Debug(">> Display.constructor"), this._target = b, !this._target) throw new Error("Target must be set");
        if (typeof this._target == "string") throw new Error("target must be a DOM element");
        if (!this._target.getContext) throw new Error("no getContext method");
        this._targetCtx = this._target.getContext("2d"), this._viewportLoc = {
          x: 0,
          y: 0,
          w: this._target.width,
          h: this._target.height
        }, this._backbuffer = document.createElement("canvas"), this._drawCtx = this._backbuffer.getContext("2d"), this._damageBounds = {
          left: 0,
          top: 0,
          right: this._backbuffer.width,
          bottom: this._backbuffer.height
        }, t.Debug("User Agent: " + navigator.userAgent), t.Debug("<< Display.constructor"), this._scale = 1, this._clipViewport = false;
      }
      return l(g, [
        {
          key: "scale",
          get: function() {
            return this._scale;
          },
          set: function(d) {
            this._rescale(d);
          }
        },
        {
          key: "clipViewport",
          get: function() {
            return this._clipViewport;
          },
          set: function(d) {
            this._clipViewport = d;
            var f = this._viewportLoc;
            this.viewportChangeSize(f.w, f.h), this.viewportChangePos(0, 0);
          }
        },
        {
          key: "width",
          get: function() {
            return this._fbWidth;
          }
        },
        {
          key: "height",
          get: function() {
            return this._fbHeight;
          }
        },
        {
          key: "viewportChangePos",
          value: function(d, f) {
            var c = this._viewportLoc;
            d = Math.floor(d), f = Math.floor(f), this._clipViewport || (d = -c.w, f = -c.h);
            var h = c.x + c.w - 1, K = c.y + c.h - 1;
            d < 0 && c.x + d < 0 && (d = -c.x), h + d >= this._fbWidth && (d -= h + d - this._fbWidth + 1), c.y + f < 0 && (f = -c.y), K + f >= this._fbHeight && (f -= K + f - this._fbHeight + 1), !(d === 0 && f === 0) && (t.Debug("viewportChange deltaX: " + d + ", deltaY: " + f), c.x += d, c.y += f, this._damage(c.x, c.y, c.w, c.h), this.flip());
          }
        },
        {
          key: "viewportChangeSize",
          value: function(d, f) {
            (!this._clipViewport || typeof d > "u" || typeof f > "u") && (t.Debug("Setting viewport to full display region"), d = this._fbWidth, f = this._fbHeight), d = Math.floor(d), f = Math.floor(f), d > this._fbWidth && (d = this._fbWidth), f > this._fbHeight && (f = this._fbHeight);
            var c = this._viewportLoc;
            if (c.w !== d || c.h !== f) {
              c.w = d, c.h = f;
              var h = this._target;
              h.width = d, h.height = f, this.viewportChangePos(0, 0), this._damage(c.x, c.y, c.w, c.h), this.flip(), this._rescale(this._scale);
            }
          }
        },
        {
          key: "absX",
          value: function(d) {
            return this._scale === 0 ? 0 : (0, r.toSigned32bit)(d / this._scale + this._viewportLoc.x);
          }
        },
        {
          key: "absY",
          value: function(d) {
            return this._scale === 0 ? 0 : (0, r.toSigned32bit)(d / this._scale + this._viewportLoc.y);
          }
        },
        {
          key: "resize",
          value: function(d, f) {
            this._prevDrawStyle = "", this._fbWidth = d, this._fbHeight = f;
            var c = this._backbuffer;
            if (c.width !== d || c.height !== f) {
              var h = null;
              c.width > 0 && c.height > 0 && (h = this._drawCtx.getImageData(0, 0, c.width, c.height)), c.width !== d && (c.width = d), c.height !== f && (c.height = f), h && this._drawCtx.putImageData(h, 0, 0);
            }
            var K = this._viewportLoc;
            this.viewportChangeSize(K.w, K.h), this.viewportChangePos(0, 0);
          }
        },
        {
          key: "getImageData",
          value: function() {
            return this._drawCtx.getImageData(0, 0, this.width, this.height);
          }
        },
        {
          key: "toDataURL",
          value: function(d, f) {
            return this._backbuffer.toDataURL(d, f);
          }
        },
        {
          key: "toBlob",
          value: function(d, f, c) {
            return this._backbuffer.toBlob(d, f, c);
          }
        },
        {
          key: "_damage",
          value: function(d, f, c, h) {
            d < this._damageBounds.left && (this._damageBounds.left = d), f < this._damageBounds.top && (this._damageBounds.top = f), d + c > this._damageBounds.right && (this._damageBounds.right = d + c), f + h > this._damageBounds.bottom && (this._damageBounds.bottom = f + h);
          }
        },
        {
          key: "flip",
          value: function(d) {
            if (this._renderQ.length !== 0 && !d) this._renderQPush({
              type: "flip"
            });
            else {
              var f = this._damageBounds.left, c = this._damageBounds.top, h = this._damageBounds.right - f, K = this._damageBounds.bottom - c, x = f - this._viewportLoc.x, F = c - this._viewportLoc.y;
              x < 0 && (h += x, f -= x, x = 0), F < 0 && (K += F, c -= F, F = 0), x + h > this._viewportLoc.w && (h = this._viewportLoc.w - x), F + K > this._viewportLoc.h && (K = this._viewportLoc.h - F), h > 0 && K > 0 && this._targetCtx.drawImage(this._backbuffer, f, c, h, K, x, F, h, K), this._damageBounds.left = this._damageBounds.top = 65535, this._damageBounds.right = this._damageBounds.bottom = 0;
            }
          }
        },
        {
          key: "pending",
          value: function() {
            return this._renderQ.length > 0;
          }
        },
        {
          key: "flush",
          value: function() {
            var d = this;
            return this._renderQ.length === 0 ? Promise.resolve() : (this._flushPromise === null && (this._flushPromise = new Promise(function(f) {
              d._flushResolve = f;
            })), this._flushPromise);
          }
        },
        {
          key: "fillRect",
          value: function(d, f, c, h, K, x) {
            this._renderQ.length !== 0 && !x ? this._renderQPush({
              type: "fill",
              x: d,
              y: f,
              width: c,
              height: h,
              color: K
            }) : (this._setFillColor(K), this._drawCtx.fillRect(d, f, c, h), this._damage(d, f, c, h));
          }
        },
        {
          key: "copyImage",
          value: function(d, f, c, h, K, x, F) {
            this._renderQ.length !== 0 && !F ? this._renderQPush({
              type: "copy",
              oldX: d,
              oldY: f,
              x: c,
              y: h,
              width: K,
              height: x
            }) : (this._drawCtx.mozImageSmoothingEnabled = false, this._drawCtx.webkitImageSmoothingEnabled = false, this._drawCtx.msImageSmoothingEnabled = false, this._drawCtx.imageSmoothingEnabled = false, this._drawCtx.drawImage(this._backbuffer, d, f, K, x, c, h, K, x), this._damage(c, h, K, x));
          }
        },
        {
          key: "imageRect",
          value: function(d, f, c, h, K, x) {
            if (!(c === 0 || h === 0)) {
              var F = new Image();
              F.src = "data: " + K + ";base64," + n.default.encode(x), this._renderQPush({
                type: "img",
                img: F,
                x: d,
                y: f,
                width: c,
                height: h
              });
            }
          }
        },
        {
          key: "videoFrame",
          value: function(d, f, c, h, K) {
            this._renderQPush({
              type: "frame",
              frame: K,
              x: d,
              y: f,
              width: c,
              height: h
            });
          }
        },
        {
          key: "blitImage",
          value: function(d, f, c, h, K, x, F) {
            if (this._renderQ.length !== 0 && !F) {
              var S = new Uint8Array(c * h * 4);
              S.set(new Uint8Array(K.buffer, 0, S.length)), this._renderQPush({
                type: "blit",
                data: S,
                x: d,
                y: f,
                width: c,
                height: h
              });
            } else {
              var w = new Uint8ClampedArray(K.buffer, K.byteOffset + x, c * h * 4), C = new ImageData(w, c, h);
              this._drawCtx.putImageData(C, d, f), this._damage(d, f, c, h);
            }
          }
        },
        {
          key: "drawImage",
          value: function(d) {
            for (var f, c = arguments.length, h = new Array(c > 1 ? c - 1 : 0), K = 1; K < c; K++) h[K - 1] = arguments[K];
            if ((f = this._drawCtx).drawImage.apply(f, [
              d
            ].concat(h)), h.length <= 4) {
              var x = h[0], F = h[1];
              this._damage(x, F, d.width, d.height);
            } else {
              var S = h[2], w = h[3], C = h[4], A = h[5];
              this._damage(C, A, S, w);
            }
          }
        },
        {
          key: "autoscale",
          value: function(d, f) {
            var c;
            if (d === 0 || f === 0) c = 0;
            else {
              var h = this._viewportLoc, K = d / f, x = h.w / h.h;
              x >= K ? c = d / h.w : c = f / h.h;
            }
            this._rescale(c);
          }
        },
        {
          key: "_rescale",
          value: function(d) {
            this._scale = d;
            var f = this._viewportLoc, c = d * f.w + "px", h = d * f.h + "px";
            (this._target.style.width !== c || this._target.style.height !== h) && (this._target.style.width = c, this._target.style.height = h);
          }
        },
        {
          key: "_setFillColor",
          value: function(d) {
            var f = "rgb(" + d[0] + "," + d[1] + "," + d[2] + ")";
            f !== this._prevDrawStyle && (this._drawCtx.fillStyle = f, this._prevDrawStyle = f);
          }
        },
        {
          key: "_renderQPush",
          value: function(d) {
            this._renderQ.push(d), this._renderQ.length === 1 && this._scanRenderQ();
          }
        },
        {
          key: "_resumeRenderQ",
          value: function() {
            this.removeEventListener("load", this._noVNCDisplay._resumeRenderQ), this._noVNCDisplay._scanRenderQ();
          }
        },
        {
          key: "_scanRenderQ",
          value: function() {
            for (var d = this, f = true, c = function() {
              var x = d._renderQ[0];
              switch (x.type) {
                case "flip":
                  d.flip(true);
                  break;
                case "copy":
                  d.copyImage(x.oldX, x.oldY, x.x, x.y, x.width, x.height, true);
                  break;
                case "fill":
                  d.fillRect(x.x, x.y, x.width, x.height, x.color, true);
                  break;
                case "blit":
                  d.blitImage(x.x, x.y, x.width, x.height, x.data, 0, true);
                  break;
                case "img":
                  if (x.img.complete) {
                    if (x.img.width !== x.width || x.img.height !== x.height) return t.Error("Decoded image has incorrect dimensions. Got " + x.img.width + "x" + x.img.height + ". Expected " + x.width + "x" + x.height + "."), {
                      v: void 0
                    };
                    d.drawImage(x.img, x.x, x.y);
                  } else x.img._noVNCDisplay = d, x.img.addEventListener("load", d._resumeRenderQ), f = false;
                  break;
                case "frame":
                  if (x.frame.ready) {
                    var F = x.frame.frame;
                    (F.codedWidth < x.width || F.codedHeight < x.height) && t.Warn("Decoded video frame does not cover its full rectangle area. Expecting at least " + x.width + "x" + x.height + " but got " + F.codedWidth + "x" + F.codedHeight);
                    var S = 0, w = 0, C = x.width, A = x.height, O = x.x, I = x.y, Z = C, q = A;
                    d.drawImage(F, S, w, C, A, O, I, Z, q), F.close();
                  } else {
                    var $ = d;
                    x.frame.promise.then(function() {
                      $._scanRenderQ();
                    }), f = false;
                  }
                  break;
              }
              f && d._renderQ.shift();
            }, h; f && this._renderQ.length > 0; ) if (h = c(), h) return h.v;
            this._renderQ.length === 0 && this._flushPromise !== null && (this._flushResolve(), this._flushPromise = null, this._flushResolve = null);
          }
        }
      ]);
    }();
  })(oo);
  var Hr = {}, Ke = {}, st = {};
  Object.defineProperty(st, "__esModule", {
    value: true
  });
  st.Buf8 = st.Buf32 = st.Buf16 = void 0;
  st.arraySet = lu;
  st.flattenChunks = fu;
  st.shrinkBuf = uu;
  function uu(e, t) {
    return e.length === t ? e : e.subarray ? e.subarray(0, t) : (e.length = t, e);
  }
  function lu(e, t, n, r, i) {
    if (t.subarray && e.subarray) {
      e.set(t.subarray(n, n + r), i);
      return;
    }
    for (var a = 0; a < r; a++) e[i + a] = t[n + a];
  }
  function fu(e) {
    var t, n, r, i, a, o;
    for (r = 0, t = 0, n = e.length; t < n; t++) r += e[t].length;
    for (o = new Uint8Array(r), i = 0, t = 0, n = e.length; t < n; t++) a = e[t], o.set(a, i), i += a.length;
    return o;
  }
  st.Buf8 = Uint8Array;
  st.Buf16 = Uint16Array;
  st.Buf32 = Int32Array;
  var hi = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = t;
    function t(n, r, i, a) {
      for (var o = n & 65535 | 0, s = n >>> 16 & 65535 | 0, y = 0; i !== 0; ) {
        y = i > 2e3 ? 2e3 : i, i -= y;
        do
          o = o + r[a++] | 0, s = s + o | 0;
        while (--y);
        o %= 65521, s %= 65521;
      }
      return o | s << 16 | 0;
    }
  })(hi);
  var di = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = t;
    function t() {
      for (var n, r = [], i = 0; i < 256; i++) {
        n = i;
        for (var a = 0; a < 8; a++) n = n & 1 ? 3988292384 ^ n >>> 1 : n >>> 1;
        r[i] = n;
      }
      return r;
    }
    t();
  })(di);
  var so = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = r;
    var t = 30, n = 12;
    function r(i, a) {
      var o, s, y, u, l, k, X, g, b, d, f, c, h, K, x, F, S, w, C, A, O, I, Z, q, $;
      o = i.state, s = i.next_in, q = i.input, y = s + (i.avail_in - 5), u = i.next_out, $ = i.output, l = u - (a - i.avail_out), k = u + (i.avail_out - 257), X = o.dmax, g = o.wsize, b = o.whave, d = o.wnext, f = o.window, c = o.hold, h = o.bits, K = o.lencode, x = o.distcode, F = (1 << o.lenbits) - 1, S = (1 << o.distbits) - 1;
      e: do {
        h < 15 && (c += q[s++] << h, h += 8, c += q[s++] << h, h += 8), w = K[c & F];
        t: for (; ; ) {
          if (C = w >>> 24, c >>>= C, h -= C, C = w >>> 16 & 255, C === 0) $[u++] = w & 65535;
          else if (C & 16) {
            A = w & 65535, C &= 15, C && (h < C && (c += q[s++] << h, h += 8), A += c & (1 << C) - 1, c >>>= C, h -= C), h < 15 && (c += q[s++] << h, h += 8, c += q[s++] << h, h += 8), w = x[c & S];
            r: for (; ; ) {
              if (C = w >>> 24, c >>>= C, h -= C, C = w >>> 16 & 255, C & 16) {
                if (O = w & 65535, C &= 15, h < C && (c += q[s++] << h, h += 8, h < C && (c += q[s++] << h, h += 8)), O += c & (1 << C) - 1, O > X) {
                  i.msg = "invalid distance too far back", o.mode = t;
                  break e;
                }
                if (c >>>= C, h -= C, C = u - l, O > C) {
                  if (C = O - C, C > b && o.sane) {
                    i.msg = "invalid distance too far back", o.mode = t;
                    break e;
                  }
                  if (I = 0, Z = f, d === 0) {
                    if (I += g - C, C < A) {
                      A -= C;
                      do
                        $[u++] = f[I++];
                      while (--C);
                      I = u - O, Z = $;
                    }
                  } else if (d < C) {
                    if (I += g + d - C, C -= d, C < A) {
                      A -= C;
                      do
                        $[u++] = f[I++];
                      while (--C);
                      if (I = 0, d < A) {
                        C = d, A -= C;
                        do
                          $[u++] = f[I++];
                        while (--C);
                        I = u - O, Z = $;
                      }
                    }
                  } else if (I += d - C, C < A) {
                    A -= C;
                    do
                      $[u++] = f[I++];
                    while (--C);
                    I = u - O, Z = $;
                  }
                  for (; A > 2; ) $[u++] = Z[I++], $[u++] = Z[I++], $[u++] = Z[I++], A -= 3;
                  A && ($[u++] = Z[I++], A > 1 && ($[u++] = Z[I++]));
                } else {
                  I = u - O;
                  do
                    $[u++] = $[I++], $[u++] = $[I++], $[u++] = $[I++], A -= 3;
                  while (A > 2);
                  A && ($[u++] = $[I++], A > 1 && ($[u++] = $[I++]));
                }
              } else if (C & 64) {
                i.msg = "invalid distance code", o.mode = t;
                break e;
              } else {
                w = x[(w & 65535) + (c & (1 << C) - 1)];
                continue r;
              }
              break;
            }
          } else if (C & 64) if (C & 32) {
            o.mode = n;
            break e;
          } else {
            i.msg = "invalid literal/length code", o.mode = t;
            break e;
          }
          else {
            w = K[(w & 65535) + (c & (1 << C) - 1)];
            continue t;
          }
          break;
        }
      } while (s < y && u < k);
      A = h >> 3, s -= A, h -= A << 3, c &= (1 << h) - 1, i.next_in = s, i.next_out = u, i.avail_in = s < y ? 5 + (y - s) : 5 - (s - y), i.avail_out = u < k ? 257 + (k - u) : 257 - (u - k), o.hold = c, o.bits = h;
    }
  })(so);
  var uo = {};
  (function(e) {
    function t(f) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(c) {
        return typeof c;
      } : function(c) {
        return c && typeof Symbol == "function" && c.constructor === Symbol && c !== Symbol.prototype ? "symbol" : typeof c;
      }, t(f);
    }
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = d;
    var n = i(st);
    function r(f) {
      if (typeof WeakMap != "function") return null;
      var c = /* @__PURE__ */ new WeakMap(), h = /* @__PURE__ */ new WeakMap();
      return (r = function(x) {
        return x ? h : c;
      })(f);
    }
    function i(f, c) {
      if (f && f.__esModule) return f;
      if (f === null || t(f) != "object" && typeof f != "function") return {
        default: f
      };
      var h = r(c);
      if (h && h.has(f)) return h.get(f);
      var K = {
        __proto__: null
      }, x = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var F in f) if (F !== "default" && {}.hasOwnProperty.call(f, F)) {
        var S = x ? Object.getOwnPropertyDescriptor(f, F) : null;
        S && (S.get || S.set) ? Object.defineProperty(K, F, S) : K[F] = f[F];
      }
      return K.default = f, h && h.set(f, K), K;
    }
    var a = 15, o = 852, s = 592, y = 0, u = 1, l = 2, k = [
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      13,
      15,
      17,
      19,
      23,
      27,
      31,
      35,
      43,
      51,
      59,
      67,
      83,
      99,
      115,
      131,
      163,
      195,
      227,
      258,
      0,
      0
    ], X = [
      16,
      16,
      16,
      16,
      16,
      16,
      16,
      16,
      17,
      17,
      17,
      17,
      18,
      18,
      18,
      18,
      19,
      19,
      19,
      19,
      20,
      20,
      20,
      20,
      21,
      21,
      21,
      21,
      16,
      72,
      78
    ], g = [
      1,
      2,
      3,
      4,
      5,
      7,
      9,
      13,
      17,
      25,
      33,
      49,
      65,
      97,
      129,
      193,
      257,
      385,
      513,
      769,
      1025,
      1537,
      2049,
      3073,
      4097,
      6145,
      8193,
      12289,
      16385,
      24577,
      0,
      0
    ], b = [
      16,
      16,
      16,
      16,
      17,
      17,
      18,
      18,
      19,
      19,
      20,
      20,
      21,
      21,
      22,
      22,
      23,
      23,
      24,
      24,
      25,
      25,
      26,
      26,
      27,
      27,
      28,
      28,
      29,
      29,
      64,
      64
    ];
    function d(f, c, h, K, x, F, S, w) {
      var C = w.bits, A = 0, O = 0, I = 0, Z = 0, q = 0, $ = 0, ne = 0, E = 0, p = 0, m = 0, L, B, M, V, re, oe = null, ce = 0, pe, ye = new n.Buf16(a + 1), Ne = new n.Buf16(a + 1), je = null, ut = 0, Ue, He, nt;
      for (A = 0; A <= a; A++) ye[A] = 0;
      for (O = 0; O < K; O++) ye[c[h + O]]++;
      for (q = C, Z = a; Z >= 1 && ye[Z] === 0; Z--) ;
      if (q > Z && (q = Z), Z === 0) return x[F++] = 1 << 24 | 64 << 16 | 0, x[F++] = 1 << 24 | 64 << 16 | 0, w.bits = 1, 0;
      for (I = 1; I < Z && ye[I] === 0; I++) ;
      for (q < I && (q = I), E = 1, A = 1; A <= a; A++) if (E <<= 1, E -= ye[A], E < 0) return -1;
      if (E > 0 && (f === y || Z !== 1)) return -1;
      for (Ne[1] = 0, A = 1; A < a; A++) Ne[A + 1] = Ne[A] + ye[A];
      for (O = 0; O < K; O++) c[h + O] !== 0 && (S[Ne[c[h + O]]++] = O);
      if (f === y ? (oe = je = S, pe = 19) : f === u ? (oe = k, ce -= 257, je = X, ut -= 257, pe = 256) : (oe = g, je = b, pe = -1), m = 0, O = 0, A = I, re = F, $ = q, ne = 0, M = -1, p = 1 << q, V = p - 1, f === u && p > o || f === l && p > s) return 1;
      for (; ; ) {
        Ue = A - ne, S[O] < pe ? (He = 0, nt = S[O]) : S[O] > pe ? (He = je[ut + S[O]], nt = oe[ce + S[O]]) : (He = 96, nt = 0), L = 1 << A - ne, B = 1 << $, I = B;
        do
          B -= L, x[re + (m >> ne) + B] = Ue << 24 | He << 16 | nt | 0;
        while (B !== 0);
        for (L = 1 << A - 1; m & L; ) L >>= 1;
        if (L !== 0 ? (m &= L - 1, m += L) : m = 0, O++, --ye[A] === 0) {
          if (A === Z) break;
          A = c[h + S[O]];
        }
        if (A > q && (m & V) !== M) {
          for (ne === 0 && (ne = q), re += I, $ = A - ne, E = 1 << $; $ + ne < Z && (E -= ye[$ + ne], !(E <= 0)); ) $++, E <<= 1;
          if (p += 1 << $, f === u && p > o || f === l && p > s) return 1;
          M = m & V, x[M] = q << 24 | $ << 16 | re - F | 0;
        }
      }
      return m !== 0 && (x[re + m] = A - ne << 24 | 64 << 16 | 0), w.bits = q, 0;
    }
  })(uo);
  function Vn(e) {
    "@babel/helpers - typeof";
    return Vn = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, Vn(e);
  }
  Object.defineProperty(Ke, "__esModule", {
    value: true
  });
  Ke.Z_TREES = Ke.Z_STREAM_ERROR = Ke.Z_STREAM_END = Ke.Z_OK = Ke.Z_NEED_DICT = Ke.Z_MEM_ERROR = Ke.Z_FINISH = Ke.Z_DEFLATED = Ke.Z_DATA_ERROR = Ke.Z_BUF_ERROR = Ke.Z_BLOCK = void 0;
  Ke.inflate = Ku;
  Ke.inflateEnd = Xu;
  Ke.inflateGetHeader = Fu;
  Ke.inflateInfo = void 0;
  Ke.inflateInit = Su;
  Ke.inflateInit2 = bo;
  Ke.inflateReset = xo;
  Ke.inflateReset2 = go;
  Ke.inflateResetKeep = yo;
  Ke.inflateSetDictionary = Cu;
  var ct = hu(st), Zn = xn(hi), Kt = xn(di), cu = xn(so), Ar = xn(uo);
  function xn(e) {
    return e && e.__esModule ? e : {
      default: e
    };
  }
  function lo(e) {
    if (typeof WeakMap != "function") return null;
    var t = /* @__PURE__ */ new WeakMap(), n = /* @__PURE__ */ new WeakMap();
    return (lo = function(i) {
      return i ? n : t;
    })(e);
  }
  function hu(e, t) {
    if (e && e.__esModule) return e;
    if (e === null || Vn(e) != "object" && typeof e != "function") return {
      default: e
    };
    var n = lo(t);
    if (n && n.has(e)) return n.get(e);
    var r = {
      __proto__: null
    }, i = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for (var a in e) if (a !== "default" && {}.hasOwnProperty.call(e, a)) {
      var o = i ? Object.getOwnPropertyDescriptor(e, a) : null;
      o && (o.get || o.set) ? Object.defineProperty(r, a, o) : r[a] = e[a];
    }
    return r.default = e, n && n.set(e, r), r;
  }
  var du = 0, fo = 1, co = 2, Ni = Ke.Z_FINISH = 4, _u = Ke.Z_BLOCK = 5, rn = Ke.Z_TREES = 6, er = Ke.Z_OK = 0, pu = Ke.Z_STREAM_END = 1, vu = Ke.Z_NEED_DICT = 2, yt = Ke.Z_STREAM_ERROR = -2, ho = Ke.Z_DATA_ERROR = -3, _o = Ke.Z_MEM_ERROR = -4, yu = Ke.Z_BUF_ERROR = -5, ji = Ke.Z_DEFLATED = 8, po = 1, Hi = 2, Wi = 3, zi = 4, Gi = 5, Vi = 6, Zi = 7, qi = 8, Yi = 9, $i = 10, dn = 11, Pt = 12, An = 13, Ji = 14, Pn = 15, ea = 16, ta = 17, ra = 18, na = 19, nn = 20, an = 21, ia = 22, aa = 23, oa = 24, sa = 25, ua = 26, Tn = 27, la = 28, fa = 29, Be = 30, vo = 31, xu = 32, gu = 852, bu = 592, mu = 15, wu = mu;
  function ca(e) {
    return (e >>> 24 & 255) + (e >>> 8 & 65280) + ((e & 65280) << 8) + ((e & 255) << 24);
  }
  function ku() {
    this.mode = 0, this.last = false, this.wrap = 0, this.havedict = false, this.flags = 0, this.dmax = 0, this.check = 0, this.total = 0, this.head = null, this.wbits = 0, this.wsize = 0, this.whave = 0, this.wnext = 0, this.window = null, this.hold = 0, this.bits = 0, this.length = 0, this.offset = 0, this.extra = 0, this.lencode = null, this.distcode = null, this.lenbits = 0, this.distbits = 0, this.ncode = 0, this.nlen = 0, this.ndist = 0, this.have = 0, this.next = null, this.lens = new ct.Buf16(320), this.work = new ct.Buf16(288), this.lendyn = null, this.distdyn = null, this.sane = 0, this.back = 0, this.was = 0;
  }
  function yo(e) {
    var t;
    return !e || !e.state ? yt : (t = e.state, e.total_in = e.total_out = t.total = 0, e.msg = "", t.wrap && (e.adler = t.wrap & 1), t.mode = po, t.last = 0, t.havedict = 0, t.dmax = 32768, t.head = null, t.hold = 0, t.bits = 0, t.lencode = t.lendyn = new ct.Buf32(gu), t.distcode = t.distdyn = new ct.Buf32(bu), t.sane = 1, t.back = -1, er);
  }
  function xo(e) {
    var t;
    return !e || !e.state ? yt : (t = e.state, t.wsize = 0, t.whave = 0, t.wnext = 0, yo(e));
  }
  function go(e, t) {
    var n, r;
    return !e || !e.state || (r = e.state, t < 0 ? (n = 0, t = -t) : (n = (t >> 4) + 1, t < 48 && (t &= 15)), t && (t < 8 || t > 15)) ? yt : (r.window !== null && r.wbits !== t && (r.window = null), r.wrap = n, r.wbits = t, xo(e));
  }
  function bo(e, t) {
    var n, r;
    return e ? (r = new ku(), e.state = r, r.window = null, n = go(e, t), n !== er && (e.state = null), n) : yt;
  }
  function Su(e) {
    return bo(e, wu);
  }
  var ha = true, Ln, Rn;
  function Eu(e) {
    if (ha) {
      var t;
      for (Ln = new ct.Buf32(512), Rn = new ct.Buf32(32), t = 0; t < 144; ) e.lens[t++] = 8;
      for (; t < 256; ) e.lens[t++] = 9;
      for (; t < 280; ) e.lens[t++] = 7;
      for (; t < 288; ) e.lens[t++] = 8;
      for ((0, Ar.default)(fo, e.lens, 0, 288, Ln, 0, e.work, {
        bits: 9
      }), t = 0; t < 32; ) e.lens[t++] = 5;
      (0, Ar.default)(co, e.lens, 0, 32, Rn, 0, e.work, {
        bits: 5
      }), ha = false;
    }
    e.lencode = Ln, e.lenbits = 9, e.distcode = Rn, e.distbits = 5;
  }
  function mo(e, t, n, r) {
    var i, a = e.state;
    return a.window === null && (a.wsize = 1 << a.wbits, a.wnext = 0, a.whave = 0, a.window = new ct.Buf8(a.wsize)), r >= a.wsize ? (ct.arraySet(a.window, t, n - a.wsize, a.wsize, 0), a.wnext = 0, a.whave = a.wsize) : (i = a.wsize - a.wnext, i > r && (i = r), ct.arraySet(a.window, t, n - r, i, a.wnext), r -= i, r ? (ct.arraySet(a.window, t, n - r, r, 0), a.wnext = r, a.whave = a.wsize) : (a.wnext += i, a.wnext === a.wsize && (a.wnext = 0), a.whave < a.wsize && (a.whave += i))), 0;
  }
  function Ku(e, t) {
    var n, r, i, a, o, s, y, u, l, k, X, g, b, d, f = 0, c, h, K, x, F, S, w, C, A = new ct.Buf8(4), O, I, Z = [
      16,
      17,
      18,
      0,
      8,
      7,
      9,
      6,
      10,
      5,
      11,
      4,
      12,
      3,
      13,
      2,
      14,
      1,
      15
    ];
    if (!e || !e.state || !e.output || !e.input && e.avail_in !== 0) return yt;
    n = e.state, n.mode === Pt && (n.mode = An), o = e.next_out, i = e.output, y = e.avail_out, a = e.next_in, r = e.input, s = e.avail_in, u = n.hold, l = n.bits, k = s, X = y, C = er;
    e: for (; ; ) switch (n.mode) {
      case po:
        if (n.wrap === 0) {
          n.mode = An;
          break;
        }
        for (; l < 16; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if (n.wrap & 2 && u === 35615) {
          n.check = 0, A[0] = u & 255, A[1] = u >>> 8 & 255, n.check = (0, Kt.default)(n.check, A, 2, 0), u = 0, l = 0, n.mode = Hi;
          break;
        }
        if (n.flags = 0, n.head && (n.head.done = false), !(n.wrap & 1) || (((u & 255) << 8) + (u >> 8)) % 31) {
          e.msg = "incorrect header check", n.mode = Be;
          break;
        }
        if ((u & 15) !== ji) {
          e.msg = "unknown compression method", n.mode = Be;
          break;
        }
        if (u >>>= 4, l -= 4, w = (u & 15) + 8, n.wbits === 0) n.wbits = w;
        else if (w > n.wbits) {
          e.msg = "invalid window size", n.mode = Be;
          break;
        }
        n.dmax = 1 << w, e.adler = n.check = 1, n.mode = u & 512 ? $i : Pt, u = 0, l = 0;
        break;
      case Hi:
        for (; l < 16; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if (n.flags = u, (n.flags & 255) !== ji) {
          e.msg = "unknown compression method", n.mode = Be;
          break;
        }
        if (n.flags & 57344) {
          e.msg = "unknown header flags set", n.mode = Be;
          break;
        }
        n.head && (n.head.text = u >> 8 & 1), n.flags & 512 && (A[0] = u & 255, A[1] = u >>> 8 & 255, n.check = (0, Kt.default)(n.check, A, 2, 0)), u = 0, l = 0, n.mode = Wi;
      case Wi:
        for (; l < 32; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        n.head && (n.head.time = u), n.flags & 512 && (A[0] = u & 255, A[1] = u >>> 8 & 255, A[2] = u >>> 16 & 255, A[3] = u >>> 24 & 255, n.check = (0, Kt.default)(n.check, A, 4, 0)), u = 0, l = 0, n.mode = zi;
      case zi:
        for (; l < 16; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        n.head && (n.head.xflags = u & 255, n.head.os = u >> 8), n.flags & 512 && (A[0] = u & 255, A[1] = u >>> 8 & 255, n.check = (0, Kt.default)(n.check, A, 2, 0)), u = 0, l = 0, n.mode = Gi;
      case Gi:
        if (n.flags & 1024) {
          for (; l < 16; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          n.length = u, n.head && (n.head.extra_len = u), n.flags & 512 && (A[0] = u & 255, A[1] = u >>> 8 & 255, n.check = (0, Kt.default)(n.check, A, 2, 0)), u = 0, l = 0;
        } else n.head && (n.head.extra = null);
        n.mode = Vi;
      case Vi:
        if (n.flags & 1024 && (g = n.length, g > s && (g = s), g && (n.head && (w = n.head.extra_len - n.length, n.head.extra || (n.head.extra = new Array(n.head.extra_len)), ct.arraySet(n.head.extra, r, a, g, w)), n.flags & 512 && (n.check = (0, Kt.default)(n.check, r, g, a)), s -= g, a += g, n.length -= g), n.length)) break e;
        n.length = 0, n.mode = Zi;
      case Zi:
        if (n.flags & 2048) {
          if (s === 0) break e;
          g = 0;
          do
            w = r[a + g++], n.head && w && n.length < 65536 && (n.head.name += String.fromCharCode(w));
          while (w && g < s);
          if (n.flags & 512 && (n.check = (0, Kt.default)(n.check, r, g, a)), s -= g, a += g, w) break e;
        } else n.head && (n.head.name = null);
        n.length = 0, n.mode = qi;
      case qi:
        if (n.flags & 4096) {
          if (s === 0) break e;
          g = 0;
          do
            w = r[a + g++], n.head && w && n.length < 65536 && (n.head.comment += String.fromCharCode(w));
          while (w && g < s);
          if (n.flags & 512 && (n.check = (0, Kt.default)(n.check, r, g, a)), s -= g, a += g, w) break e;
        } else n.head && (n.head.comment = null);
        n.mode = Yi;
      case Yi:
        if (n.flags & 512) {
          for (; l < 16; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          if (u !== (n.check & 65535)) {
            e.msg = "header crc mismatch", n.mode = Be;
            break;
          }
          u = 0, l = 0;
        }
        n.head && (n.head.hcrc = n.flags >> 9 & 1, n.head.done = true), e.adler = n.check = 0, n.mode = Pt;
        break;
      case $i:
        for (; l < 32; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        e.adler = n.check = ca(u), u = 0, l = 0, n.mode = dn;
      case dn:
        if (n.havedict === 0) return e.next_out = o, e.avail_out = y, e.next_in = a, e.avail_in = s, n.hold = u, n.bits = l, vu;
        e.adler = n.check = 1, n.mode = Pt;
      case Pt:
        if (t === _u || t === rn) break e;
      case An:
        if (n.last) {
          u >>>= l & 7, l -= l & 7, n.mode = Tn;
          break;
        }
        for (; l < 3; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        switch (n.last = u & 1, u >>>= 1, l -= 1, u & 3) {
          case 0:
            n.mode = Ji;
            break;
          case 1:
            if (Eu(n), n.mode = nn, t === rn) {
              u >>>= 2, l -= 2;
              break e;
            }
            break;
          case 2:
            n.mode = ta;
            break;
          case 3:
            e.msg = "invalid block type", n.mode = Be;
        }
        u >>>= 2, l -= 2;
        break;
      case Ji:
        for (u >>>= l & 7, l -= l & 7; l < 32; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if ((u & 65535) !== (u >>> 16 ^ 65535)) {
          e.msg = "invalid stored block lengths", n.mode = Be;
          break;
        }
        if (n.length = u & 65535, u = 0, l = 0, n.mode = Pn, t === rn) break e;
      case Pn:
        n.mode = ea;
      case ea:
        if (g = n.length, g) {
          if (g > s && (g = s), g > y && (g = y), g === 0) break e;
          ct.arraySet(i, r, a, g, o), s -= g, a += g, y -= g, o += g, n.length -= g;
          break;
        }
        n.mode = Pt;
        break;
      case ta:
        for (; l < 14; ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if (n.nlen = (u & 31) + 257, u >>>= 5, l -= 5, n.ndist = (u & 31) + 1, u >>>= 5, l -= 5, n.ncode = (u & 15) + 4, u >>>= 4, l -= 4, n.nlen > 286 || n.ndist > 30) {
          e.msg = "too many length or distance symbols", n.mode = Be;
          break;
        }
        n.have = 0, n.mode = ra;
      case ra:
        for (; n.have < n.ncode; ) {
          for (; l < 3; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          n.lens[Z[n.have++]] = u & 7, u >>>= 3, l -= 3;
        }
        for (; n.have < 19; ) n.lens[Z[n.have++]] = 0;
        if (n.lencode = n.lendyn, n.lenbits = 7, O = {
          bits: n.lenbits
        }, C = (0, Ar.default)(du, n.lens, 0, 19, n.lencode, 0, n.work, O), n.lenbits = O.bits, C) {
          e.msg = "invalid code lengths set", n.mode = Be;
          break;
        }
        n.have = 0, n.mode = na;
      case na:
        for (; n.have < n.nlen + n.ndist; ) {
          for (; f = n.lencode[u & (1 << n.lenbits) - 1], c = f >>> 24, h = f >>> 16 & 255, K = f & 65535, !(c <= l); ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          if (K < 16) u >>>= c, l -= c, n.lens[n.have++] = K;
          else {
            if (K === 16) {
              for (I = c + 2; l < I; ) {
                if (s === 0) break e;
                s--, u += r[a++] << l, l += 8;
              }
              if (u >>>= c, l -= c, n.have === 0) {
                e.msg = "invalid bit length repeat", n.mode = Be;
                break;
              }
              w = n.lens[n.have - 1], g = 3 + (u & 3), u >>>= 2, l -= 2;
            } else if (K === 17) {
              for (I = c + 3; l < I; ) {
                if (s === 0) break e;
                s--, u += r[a++] << l, l += 8;
              }
              u >>>= c, l -= c, w = 0, g = 3 + (u & 7), u >>>= 3, l -= 3;
            } else {
              for (I = c + 7; l < I; ) {
                if (s === 0) break e;
                s--, u += r[a++] << l, l += 8;
              }
              u >>>= c, l -= c, w = 0, g = 11 + (u & 127), u >>>= 7, l -= 7;
            }
            if (n.have + g > n.nlen + n.ndist) {
              e.msg = "invalid bit length repeat", n.mode = Be;
              break;
            }
            for (; g--; ) n.lens[n.have++] = w;
          }
        }
        if (n.mode === Be) break;
        if (n.lens[256] === 0) {
          e.msg = "invalid code -- missing end-of-block", n.mode = Be;
          break;
        }
        if (n.lenbits = 9, O = {
          bits: n.lenbits
        }, C = (0, Ar.default)(fo, n.lens, 0, n.nlen, n.lencode, 0, n.work, O), n.lenbits = O.bits, C) {
          e.msg = "invalid literal/lengths set", n.mode = Be;
          break;
        }
        if (n.distbits = 6, n.distcode = n.distdyn, O = {
          bits: n.distbits
        }, C = (0, Ar.default)(co, n.lens, n.nlen, n.ndist, n.distcode, 0, n.work, O), n.distbits = O.bits, C) {
          e.msg = "invalid distances set", n.mode = Be;
          break;
        }
        if (n.mode = nn, t === rn) break e;
      case nn:
        n.mode = an;
      case an:
        if (s >= 6 && y >= 258) {
          e.next_out = o, e.avail_out = y, e.next_in = a, e.avail_in = s, n.hold = u, n.bits = l, (0, cu.default)(e, X), o = e.next_out, i = e.output, y = e.avail_out, a = e.next_in, r = e.input, s = e.avail_in, u = n.hold, l = n.bits, n.mode === Pt && (n.back = -1);
          break;
        }
        for (n.back = 0; f = n.lencode[u & (1 << n.lenbits) - 1], c = f >>> 24, h = f >>> 16 & 255, K = f & 65535, !(c <= l); ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if (h && !(h & 240)) {
          for (x = c, F = h, S = K; f = n.lencode[S + ((u & (1 << x + F) - 1) >> x)], c = f >>> 24, h = f >>> 16 & 255, K = f & 65535, !(x + c <= l); ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          u >>>= x, l -= x, n.back += x;
        }
        if (u >>>= c, l -= c, n.back += c, n.length = K, h === 0) {
          n.mode = ua;
          break;
        }
        if (h & 32) {
          n.back = -1, n.mode = Pt;
          break;
        }
        if (h & 64) {
          e.msg = "invalid literal/length code", n.mode = Be;
          break;
        }
        n.extra = h & 15, n.mode = ia;
      case ia:
        if (n.extra) {
          for (I = n.extra; l < I; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          n.length += u & (1 << n.extra) - 1, u >>>= n.extra, l -= n.extra, n.back += n.extra;
        }
        n.was = n.length, n.mode = aa;
      case aa:
        for (; f = n.distcode[u & (1 << n.distbits) - 1], c = f >>> 24, h = f >>> 16 & 255, K = f & 65535, !(c <= l); ) {
          if (s === 0) break e;
          s--, u += r[a++] << l, l += 8;
        }
        if (!(h & 240)) {
          for (x = c, F = h, S = K; f = n.distcode[S + ((u & (1 << x + F) - 1) >> x)], c = f >>> 24, h = f >>> 16 & 255, K = f & 65535, !(x + c <= l); ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          u >>>= x, l -= x, n.back += x;
        }
        if (u >>>= c, l -= c, n.back += c, h & 64) {
          e.msg = "invalid distance code", n.mode = Be;
          break;
        }
        n.offset = K, n.extra = h & 15, n.mode = oa;
      case oa:
        if (n.extra) {
          for (I = n.extra; l < I; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          n.offset += u & (1 << n.extra) - 1, u >>>= n.extra, l -= n.extra, n.back += n.extra;
        }
        if (n.offset > n.dmax) {
          e.msg = "invalid distance too far back", n.mode = Be;
          break;
        }
        n.mode = sa;
      case sa:
        if (y === 0) break e;
        if (g = X - y, n.offset > g) {
          if (g = n.offset - g, g > n.whave && n.sane) {
            e.msg = "invalid distance too far back", n.mode = Be;
            break;
          }
          g > n.wnext ? (g -= n.wnext, b = n.wsize - g) : b = n.wnext - g, g > n.length && (g = n.length), d = n.window;
        } else d = i, b = o - n.offset, g = n.length;
        g > y && (g = y), y -= g, n.length -= g;
        do
          i[o++] = d[b++];
        while (--g);
        n.length === 0 && (n.mode = an);
        break;
      case ua:
        if (y === 0) break e;
        i[o++] = n.length, y--, n.mode = an;
        break;
      case Tn:
        if (n.wrap) {
          for (; l < 32; ) {
            if (s === 0) break e;
            s--, u |= r[a++] << l, l += 8;
          }
          if (X -= y, e.total_out += X, n.total += X, X && (e.adler = n.check = n.flags ? (0, Kt.default)(n.check, i, X, o - X) : (0, Zn.default)(n.check, i, X, o - X)), X = y, (n.flags ? u : ca(u)) !== n.check) {
            e.msg = "incorrect data check", n.mode = Be;
            break;
          }
          u = 0, l = 0;
        }
        n.mode = la;
      case la:
        if (n.wrap && n.flags) {
          for (; l < 32; ) {
            if (s === 0) break e;
            s--, u += r[a++] << l, l += 8;
          }
          if (u !== (n.total & 4294967295)) {
            e.msg = "incorrect length check", n.mode = Be;
            break;
          }
          u = 0, l = 0;
        }
        n.mode = fa;
      case fa:
        C = pu;
        break e;
      case Be:
        C = ho;
        break e;
      case vo:
        return _o;
      case xu:
      default:
        return yt;
    }
    return e.next_out = o, e.avail_out = y, e.next_in = a, e.avail_in = s, n.hold = u, n.bits = l, (n.wsize || X !== e.avail_out && n.mode < Be && (n.mode < Tn || t !== Ni)) && mo(e, e.output, e.next_out, X - e.avail_out), k -= e.avail_in, X -= e.avail_out, e.total_in += k, e.total_out += X, n.total += X, n.wrap && X && (e.adler = n.check = n.flags ? (0, Kt.default)(n.check, i, X, e.next_out - X) : (0, Zn.default)(n.check, i, X, e.next_out - X)), e.data_type = n.bits + (n.last ? 64 : 0) + (n.mode === Pt ? 128 : 0) + (n.mode === nn || n.mode === Pn ? 256 : 0), (k === 0 && X === 0 || t === Ni) && C === er && (C = yu), C;
  }
  function Xu(e) {
    if (!e || !e.state) return yt;
    var t = e.state;
    return t.window && (t.window = null), e.state = null, er;
  }
  function Fu(e, t) {
    var n;
    return !e || !e.state || (n = e.state, !(n.wrap & 2)) ? yt : (n.head = t, t.done = false, er);
  }
  function Cu(e, t) {
    var n = t.length, r, i, a;
    return !e || !e.state || (r = e.state, r.wrap !== 0 && r.mode !== dn) ? yt : r.mode === dn && (i = 1, i = (0, Zn.default)(i, t, n, 0), i !== r.check) ? ho : (a = mo(e, t, n, n), a ? (r.mode = vo, _o) : (r.havedict = 1, er));
  }
  Ke.inflateInfo = "pako inflate (from Nodeca project)";
  var _i = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = t;
    function t() {
      this.input = null, this.next_in = 0, this.avail_in = 0, this.total_in = 0, this.output = null, this.next_out = 0, this.avail_out = 0, this.total_out = 0, this.msg = "", this.state = null, this.data_type = 2, this.adler = 0;
    }
  })(_i);
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = Ke, n = r(_i);
    function r(l) {
      return l && l.__esModule ? l : {
        default: l
      };
    }
    function i(l) {
      "@babel/helpers - typeof";
      return i = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(k) {
        return typeof k;
      } : function(k) {
        return k && typeof Symbol == "function" && k.constructor === Symbol && k !== Symbol.prototype ? "symbol" : typeof k;
      }, i(l);
    }
    function a(l, k) {
      if (!(l instanceof k)) throw new TypeError("Cannot call a class as a function");
    }
    function o(l, k) {
      for (var X = 0; X < k.length; X++) {
        var g = k[X];
        g.enumerable = g.enumerable || false, g.configurable = true, "value" in g && (g.writable = true), Object.defineProperty(l, y(g.key), g);
      }
    }
    function s(l, k, X) {
      return k && o(l.prototype, k), Object.defineProperty(l, "prototype", {
        writable: false
      }), l;
    }
    function y(l) {
      var k = u(l, "string");
      return i(k) == "symbol" ? k : k + "";
    }
    function u(l, k) {
      if (i(l) != "object" || !l) return l;
      var X = l[Symbol.toPrimitive];
      if (X !== void 0) {
        var g = X.call(l, k);
        if (i(g) != "object") return g;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(l);
    }
    e.default = function() {
      function l() {
        a(this, l), this.strm = new n.default(), this.chunkSize = 1024 * 10 * 10, this.strm.output = new Uint8Array(this.chunkSize), (0, t.inflateInit)(this.strm);
      }
      return s(l, [
        {
          key: "setInput",
          value: function(X) {
            X ? (this.strm.input = X, this.strm.avail_in = this.strm.input.length, this.strm.next_in = 0) : (this.strm.input = null, this.strm.avail_in = 0, this.strm.next_in = 0);
          }
        },
        {
          key: "inflate",
          value: function(X) {
            X > this.chunkSize && (this.chunkSize = X, this.strm.output = new Uint8Array(this.chunkSize)), this.strm.next_out = 0, this.strm.avail_out = X;
            var g = (0, t.inflate)(this.strm, 0);
            if (g < 0) throw new Error("zlib inflate failed");
            if (this.strm.next_out != X) throw new Error("Incomplete zlib block");
            return new Uint8Array(this.strm.output.buffer, 0, this.strm.next_out);
          }
        },
        {
          key: "reset",
          value: function() {
            (0, t.inflateReset)(this.strm);
          }
        }
      ]);
    }();
  })(Hr);
  var wo = {}, ge = {}, or = {};
  function qn(e) {
    "@babel/helpers - typeof";
    return qn = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, qn(e);
  }
  Object.defineProperty(or, "__esModule", {
    value: true
  });
  or._tr_align = Zu;
  or._tr_flush_block = qu;
  or._tr_init = Vu;
  or._tr_stored_block = Bo;
  or._tr_tally = Yu;
  var Au = Pu(st);
  function ko(e) {
    if (typeof WeakMap != "function") return null;
    var t = /* @__PURE__ */ new WeakMap(), n = /* @__PURE__ */ new WeakMap();
    return (ko = function(i) {
      return i ? n : t;
    })(e);
  }
  function Pu(e, t) {
    if (e && e.__esModule) return e;
    if (e === null || qn(e) != "object" && typeof e != "function") return {
      default: e
    };
    var n = ko(t);
    if (n && n.has(e)) return n.get(e);
    var r = {
      __proto__: null
    }, i = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for (var a in e) if (a !== "default" && {}.hasOwnProperty.call(e, a)) {
      var o = i ? Object.getOwnPropertyDescriptor(e, a) : null;
      o && (o.get || o.set) ? Object.defineProperty(r, a, o) : r[a] = e[a];
    }
    return r.default = e, n && n.set(e, r), r;
  }
  var Tu = 4, da = 0, _a = 1, Lu = 2;
  function br(e) {
    for (var t = e.length; --t >= 0; ) e[t] = 0;
  }
  var Ru = 0, So = 1, Mu = 2, Du = 3, Ou = 258, pi = 29, Wr = 256, Mr = Wr + 1 + pi, _r = 30, vi = 19, Eo = 2 * Mr + 1, Yt = 15, Mn = 16, Bu = 7, yi = 256, Ko = 16, Xo = 17, Fo = 18, Yn = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    0
  ], ln = [
    0,
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    9,
    10,
    10,
    11,
    11,
    12,
    12,
    13,
    13
  ], Iu = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    2,
    3,
    7
  ], Co = [
    16,
    17,
    18,
    0,
    8,
    7,
    9,
    6,
    10,
    5,
    11,
    4,
    12,
    3,
    13,
    2,
    14,
    1,
    15
  ], Qu = 512, Tt = new Array((Mr + 2) * 2);
  br(Tt);
  var Pr = new Array(_r * 2);
  br(Pr);
  var Dr = new Array(Qu);
  br(Dr);
  var Or = new Array(Ou - Du + 1);
  br(Or);
  var xi = new Array(pi);
  br(xi);
  var _n = new Array(_r);
  br(_n);
  function Dn(e, t, n, r, i) {
    this.static_tree = e, this.extra_bits = t, this.extra_base = n, this.elems = r, this.max_length = i, this.has_stree = e && e.length;
  }
  var Ao, Po, To;
  function On(e, t) {
    this.dyn_tree = e, this.max_code = 0, this.stat_desc = t;
  }
  function Lo(e) {
    return e < 256 ? Dr[e] : Dr[256 + (e >>> 7)];
  }
  function Br(e, t) {
    e.pending_buf[e.pending++] = t & 255, e.pending_buf[e.pending++] = t >>> 8 & 255;
  }
  function ot(e, t, n) {
    e.bi_valid > Mn - n ? (e.bi_buf |= t << e.bi_valid & 65535, Br(e, e.bi_buf), e.bi_buf = t >> Mn - e.bi_valid, e.bi_valid += n - Mn) : (e.bi_buf |= t << e.bi_valid & 65535, e.bi_valid += n);
  }
  function Ct(e, t, n) {
    ot(e, n[t * 2], n[t * 2 + 1]);
  }
  function Ro(e, t) {
    var n = 0;
    do
      n |= e & 1, e >>>= 1, n <<= 1;
    while (--t > 0);
    return n >>> 1;
  }
  function Uu(e) {
    e.bi_valid === 16 ? (Br(e, e.bi_buf), e.bi_buf = 0, e.bi_valid = 0) : e.bi_valid >= 8 && (e.pending_buf[e.pending++] = e.bi_buf & 255, e.bi_buf >>= 8, e.bi_valid -= 8);
  }
  function Nu(e, t) {
    var n = t.dyn_tree, r = t.max_code, i = t.stat_desc.static_tree, a = t.stat_desc.has_stree, o = t.stat_desc.extra_bits, s = t.stat_desc.extra_base, y = t.stat_desc.max_length, u, l, k, X, g, b, d = 0;
    for (X = 0; X <= Yt; X++) e.bl_count[X] = 0;
    for (n[e.heap[e.heap_max] * 2 + 1] = 0, u = e.heap_max + 1; u < Eo; u++) l = e.heap[u], X = n[n[l * 2 + 1] * 2 + 1] + 1, X > y && (X = y, d++), n[l * 2 + 1] = X, !(l > r) && (e.bl_count[X]++, g = 0, l >= s && (g = o[l - s]), b = n[l * 2], e.opt_len += b * (X + g), a && (e.static_len += b * (i[l * 2 + 1] + g)));
    if (d !== 0) {
      do {
        for (X = y - 1; e.bl_count[X] === 0; ) X--;
        e.bl_count[X]--, e.bl_count[X + 1] += 2, e.bl_count[y]--, d -= 2;
      } while (d > 0);
      for (X = y; X !== 0; X--) for (l = e.bl_count[X]; l !== 0; ) k = e.heap[--u], !(k > r) && (n[k * 2 + 1] !== X && (e.opt_len += (X - n[k * 2 + 1]) * n[k * 2], n[k * 2 + 1] = X), l--);
    }
  }
  function Mo(e, t, n) {
    var r = new Array(Yt + 1), i = 0, a, o;
    for (a = 1; a <= Yt; a++) r[a] = i = i + n[a - 1] << 1;
    for (o = 0; o <= t; o++) {
      var s = e[o * 2 + 1];
      s !== 0 && (e[o * 2] = Ro(r[s]++, s));
    }
  }
  function ju() {
    var e, t, n, r, i, a = new Array(Yt + 1);
    for (n = 0, r = 0; r < pi - 1; r++) for (xi[r] = n, e = 0; e < 1 << Yn[r]; e++) Or[n++] = r;
    for (Or[n - 1] = r, i = 0, r = 0; r < 16; r++) for (_n[r] = i, e = 0; e < 1 << ln[r]; e++) Dr[i++] = r;
    for (i >>= 7; r < _r; r++) for (_n[r] = i << 7, e = 0; e < 1 << ln[r] - 7; e++) Dr[256 + i++] = r;
    for (t = 0; t <= Yt; t++) a[t] = 0;
    for (e = 0; e <= 143; ) Tt[e * 2 + 1] = 8, e++, a[8]++;
    for (; e <= 255; ) Tt[e * 2 + 1] = 9, e++, a[9]++;
    for (; e <= 279; ) Tt[e * 2 + 1] = 7, e++, a[7]++;
    for (; e <= 287; ) Tt[e * 2 + 1] = 8, e++, a[8]++;
    for (Mo(Tt, Mr + 1, a), e = 0; e < _r; e++) Pr[e * 2 + 1] = 5, Pr[e * 2] = Ro(e, 5);
    Ao = new Dn(Tt, Yn, Wr + 1, Mr, Yt), Po = new Dn(Pr, ln, 0, _r, Yt), To = new Dn(new Array(0), Iu, 0, vi, Bu);
  }
  function Do(e) {
    var t;
    for (t = 0; t < Mr; t++) e.dyn_ltree[t * 2] = 0;
    for (t = 0; t < _r; t++) e.dyn_dtree[t * 2] = 0;
    for (t = 0; t < vi; t++) e.bl_tree[t * 2] = 0;
    e.dyn_ltree[yi * 2] = 1, e.opt_len = e.static_len = 0, e.last_lit = e.matches = 0;
  }
  function Oo(e) {
    e.bi_valid > 8 ? Br(e, e.bi_buf) : e.bi_valid > 0 && (e.pending_buf[e.pending++] = e.bi_buf), e.bi_buf = 0, e.bi_valid = 0;
  }
  function Hu(e, t, n, r) {
    Oo(e), Br(e, n), Br(e, ~n), Au.arraySet(e.pending_buf, e.window, t, n, e.pending), e.pending += n;
  }
  function pa(e, t, n, r) {
    var i = t * 2, a = n * 2;
    return e[i] < e[a] || e[i] === e[a] && r[t] <= r[n];
  }
  function Bn(e, t, n) {
    for (var r = e.heap[n], i = n << 1; i <= e.heap_len && (i < e.heap_len && pa(t, e.heap[i + 1], e.heap[i], e.depth) && i++, !pa(t, r, e.heap[i], e.depth)); ) e.heap[n] = e.heap[i], n = i, i <<= 1;
    e.heap[n] = r;
  }
  function va(e, t, n) {
    var r, i, a = 0, o, s;
    if (e.last_lit !== 0) do
      r = e.pending_buf[e.d_buf + a * 2] << 8 | e.pending_buf[e.d_buf + a * 2 + 1], i = e.pending_buf[e.l_buf + a], a++, r === 0 ? Ct(e, i, t) : (o = Or[i], Ct(e, o + Wr + 1, t), s = Yn[o], s !== 0 && (i -= xi[o], ot(e, i, s)), r--, o = Lo(r), Ct(e, o, n), s = ln[o], s !== 0 && (r -= _n[o], ot(e, r, s)));
    while (a < e.last_lit);
    Ct(e, yi, t);
  }
  function $n(e, t) {
    var n = t.dyn_tree, r = t.stat_desc.static_tree, i = t.stat_desc.has_stree, a = t.stat_desc.elems, o, s, y = -1, u;
    for (e.heap_len = 0, e.heap_max = Eo, o = 0; o < a; o++) n[o * 2] !== 0 ? (e.heap[++e.heap_len] = y = o, e.depth[o] = 0) : n[o * 2 + 1] = 0;
    for (; e.heap_len < 2; ) u = e.heap[++e.heap_len] = y < 2 ? ++y : 0, n[u * 2] = 1, e.depth[u] = 0, e.opt_len--, i && (e.static_len -= r[u * 2 + 1]);
    for (t.max_code = y, o = e.heap_len >> 1; o >= 1; o--) Bn(e, n, o);
    u = a;
    do
      o = e.heap[1], e.heap[1] = e.heap[e.heap_len--], Bn(e, n, 1), s = e.heap[1], e.heap[--e.heap_max] = o, e.heap[--e.heap_max] = s, n[u * 2] = n[o * 2] + n[s * 2], e.depth[u] = (e.depth[o] >= e.depth[s] ? e.depth[o] : e.depth[s]) + 1, n[o * 2 + 1] = n[s * 2 + 1] = u, e.heap[1] = u++, Bn(e, n, 1);
    while (e.heap_len >= 2);
    e.heap[--e.heap_max] = e.heap[1], Nu(e, t), Mo(n, y, e.bl_count);
  }
  function ya(e, t, n) {
    var r, i = -1, a, o = t[0 * 2 + 1], s = 0, y = 7, u = 4;
    for (o === 0 && (y = 138, u = 3), t[(n + 1) * 2 + 1] = 65535, r = 0; r <= n; r++) a = o, o = t[(r + 1) * 2 + 1], !(++s < y && a === o) && (s < u ? e.bl_tree[a * 2] += s : a !== 0 ? (a !== i && e.bl_tree[a * 2]++, e.bl_tree[Ko * 2]++) : s <= 10 ? e.bl_tree[Xo * 2]++ : e.bl_tree[Fo * 2]++, s = 0, i = a, o === 0 ? (y = 138, u = 3) : a === o ? (y = 6, u = 3) : (y = 7, u = 4));
  }
  function xa(e, t, n) {
    var r, i = -1, a, o = t[0 * 2 + 1], s = 0, y = 7, u = 4;
    for (o === 0 && (y = 138, u = 3), r = 0; r <= n; r++) if (a = o, o = t[(r + 1) * 2 + 1], !(++s < y && a === o)) {
      if (s < u) do
        Ct(e, a, e.bl_tree);
      while (--s !== 0);
      else a !== 0 ? (a !== i && (Ct(e, a, e.bl_tree), s--), Ct(e, Ko, e.bl_tree), ot(e, s - 3, 2)) : s <= 10 ? (Ct(e, Xo, e.bl_tree), ot(e, s - 3, 3)) : (Ct(e, Fo, e.bl_tree), ot(e, s - 11, 7));
      s = 0, i = a, o === 0 ? (y = 138, u = 3) : a === o ? (y = 6, u = 3) : (y = 7, u = 4);
    }
  }
  function Wu(e) {
    var t;
    for (ya(e, e.dyn_ltree, e.l_desc.max_code), ya(e, e.dyn_dtree, e.d_desc.max_code), $n(e, e.bl_desc), t = vi - 1; t >= 3 && e.bl_tree[Co[t] * 2 + 1] === 0; t--) ;
    return e.opt_len += 3 * (t + 1) + 5 + 5 + 4, t;
  }
  function zu(e, t, n, r) {
    var i;
    for (ot(e, t - 257, 5), ot(e, n - 1, 5), ot(e, r - 4, 4), i = 0; i < r; i++) ot(e, e.bl_tree[Co[i] * 2 + 1], 3);
    xa(e, e.dyn_ltree, t - 1), xa(e, e.dyn_dtree, n - 1);
  }
  function Gu(e) {
    var t = 4093624447, n;
    for (n = 0; n <= 31; n++, t >>>= 1) if (t & 1 && e.dyn_ltree[n * 2] !== 0) return da;
    if (e.dyn_ltree[9 * 2] !== 0 || e.dyn_ltree[10 * 2] !== 0 || e.dyn_ltree[13 * 2] !== 0) return _a;
    for (n = 32; n < Wr; n++) if (e.dyn_ltree[n * 2] !== 0) return _a;
    return da;
  }
  var ga = false;
  function Vu(e) {
    ga || (ju(), ga = true), e.l_desc = new On(e.dyn_ltree, Ao), e.d_desc = new On(e.dyn_dtree, Po), e.bl_desc = new On(e.bl_tree, To), e.bi_buf = 0, e.bi_valid = 0, Do(e);
  }
  function Bo(e, t, n, r) {
    ot(e, (Ru << 1) + (r ? 1 : 0), 3), Hu(e, t, n);
  }
  function Zu(e) {
    ot(e, So << 1, 3), Ct(e, yi, Tt), Uu(e);
  }
  function qu(e, t, n, r) {
    var i, a, o = 0;
    e.level > 0 ? (e.strm.data_type === Lu && (e.strm.data_type = Gu(e)), $n(e, e.l_desc), $n(e, e.d_desc), o = Wu(e), i = e.opt_len + 3 + 7 >>> 3, a = e.static_len + 3 + 7 >>> 3, a <= i && (i = a)) : i = a = n + 5, n + 4 <= i && t !== -1 ? Bo(e, t, n, r) : e.strategy === Tu || a === i ? (ot(e, (So << 1) + (r ? 1 : 0), 3), va(e, Tt, Pr)) : (ot(e, (Mu << 1) + (r ? 1 : 0), 3), zu(e, e.l_desc.max_code + 1, e.d_desc.max_code + 1, o + 1), va(e, e.dyn_ltree, e.dyn_dtree)), Do(e), r && Oo(e);
  }
  function Yu(e, t, n) {
    return e.pending_buf[e.d_buf + e.last_lit * 2] = t >>> 8 & 255, e.pending_buf[e.d_buf + e.last_lit * 2 + 1] = t & 255, e.pending_buf[e.l_buf + e.last_lit] = n & 255, e.last_lit++, t === 0 ? e.dyn_ltree[n * 2]++ : (e.matches++, t--, e.dyn_ltree[(Or[n] + Wr + 1) * 2]++, e.dyn_dtree[Lo(t) * 2]++), e.last_lit === e.lit_bufsize - 1;
  }
  var Io = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0, e.default = {
      2: "need dictionary",
      1: "stream end",
      0: "",
      "-1": "file error",
      "-2": "stream error",
      "-3": "data error",
      "-4": "insufficient memory",
      "-5": "buffer error",
      "-6": "incompatible version"
    };
  })(Io);
  function Jn(e) {
    "@babel/helpers - typeof";
    return Jn = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, Jn(e);
  }
  Object.defineProperty(ge, "__esModule", {
    value: true
  });
  ge.Z_UNKNOWN = ge.Z_STREAM_ERROR = ge.Z_STREAM_END = ge.Z_RLE = ge.Z_PARTIAL_FLUSH = ge.Z_OK = ge.Z_NO_FLUSH = ge.Z_HUFFMAN_ONLY = ge.Z_FULL_FLUSH = ge.Z_FIXED = ge.Z_FINISH = ge.Z_FILTERED = ge.Z_DEFLATED = ge.Z_DEFAULT_STRATEGY = ge.Z_DEFAULT_COMPRESSION = ge.Z_DATA_ERROR = ge.Z_BUF_ERROR = ge.Z_BLOCK = void 0;
  ge.deflate = Xl;
  ge.deflateEnd = Fl;
  ge.deflateInfo = void 0;
  ge.deflateInit = Kl;
  ge.deflateInit2 = zo;
  ge.deflateReset = Wo;
  ge.deflateResetKeep = Ho;
  ge.deflateSetDictionary = Cl;
  ge.deflateSetHeader = El;
  var rt = No(st), pt = No(or), Qo = gi(hi), Dt = gi(di), $u = gi(Io);
  function gi(e) {
    return e && e.__esModule ? e : {
      default: e
    };
  }
  function Uo(e) {
    if (typeof WeakMap != "function") return null;
    var t = /* @__PURE__ */ new WeakMap(), n = /* @__PURE__ */ new WeakMap();
    return (Uo = function(i) {
      return i ? n : t;
    })(e);
  }
  function No(e, t) {
    if (e && e.__esModule) return e;
    if (e === null || Jn(e) != "object" && typeof e != "function") return {
      default: e
    };
    var n = Uo(t);
    if (n && n.has(e)) return n.get(e);
    var r = {
      __proto__: null
    }, i = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for (var a in e) if (a !== "default" && {}.hasOwnProperty.call(e, a)) {
      var o = i ? Object.getOwnPropertyDescriptor(e, a) : null;
      o && (o.get || o.set) ? Object.defineProperty(r, a, o) : r[a] = e[a];
    }
    return r.default = e, n && n.set(e, r), r;
  }
  var sr = ge.Z_NO_FLUSH = 0, Ju = ge.Z_PARTIAL_FLUSH = 1, el = ge.Z_FULL_FLUSH = 3, jt = ge.Z_FINISH = 4, ba = ge.Z_BLOCK = 5, At = ge.Z_OK = 0, ma = ge.Z_STREAM_END = 1, vt = ge.Z_STREAM_ERROR = -2, tl = ge.Z_DATA_ERROR = -3, In = ge.Z_BUF_ERROR = -5, rl = ge.Z_DEFAULT_COMPRESSION = -1, nl = ge.Z_FILTERED = 1, on = ge.Z_HUFFMAN_ONLY = 2, il = ge.Z_RLE = 3, al = ge.Z_FIXED = 4, ol = ge.Z_DEFAULT_STRATEGY = 0, sl = ge.Z_UNKNOWN = 2, gn = ge.Z_DEFLATED = 8, ul = 9, ll = 15, fl = 8, cl = 29, hl = 256, ei = hl + 1 + cl, dl = 30, _l = 19, pl = 2 * ei + 1, vl = 15, Ee = 3, It = 258, gt = It + Ee + 1, yl = 32, bn = 42, ti = 69, fn = 73, cn = 91, hn = 103, $t = 113, Fr = 666, Qe = 1, zr = 2, tr = 3, mr = 4, xl = 3;
  function Qt(e, t) {
    return e.msg = $u.default[t], t;
  }
  function wa(e) {
    return (e << 1) - (e > 4 ? 9 : 0);
  }
  function Bt(e) {
    for (var t = e.length; --t >= 0; ) e[t] = 0;
  }
  function Ot(e) {
    var t = e.state, n = t.pending;
    n > e.avail_out && (n = e.avail_out), n !== 0 && (rt.arraySet(e.output, t.pending_buf, t.pending_out, n, e.next_out), e.next_out += n, t.pending_out += n, e.total_out += n, e.avail_out -= n, t.pending -= n, t.pending === 0 && (t.pending_out = 0));
  }
  function Ve(e, t) {
    pt._tr_flush_block(e, e.block_start >= 0 ? e.block_start : -1, e.strstart - e.block_start, t), e.block_start = e.strstart, Ot(e.strm);
  }
  function Fe(e, t) {
    e.pending_buf[e.pending++] = t;
  }
  function Sr(e, t) {
    e.pending_buf[e.pending++] = t >>> 8 & 255, e.pending_buf[e.pending++] = t & 255;
  }
  function gl(e, t, n, r) {
    var i = e.avail_in;
    return i > r && (i = r), i === 0 ? 0 : (e.avail_in -= i, rt.arraySet(t, e.input, e.next_in, i, n), e.state.wrap === 1 ? e.adler = (0, Qo.default)(e.adler, t, i, n) : e.state.wrap === 2 && (e.adler = (0, Dt.default)(e.adler, t, i, n)), e.next_in += i, e.total_in += i, i);
  }
  function jo(e, t) {
    var n = e.max_chain_length, r = e.strstart, i, a, o = e.prev_length, s = e.nice_match, y = e.strstart > e.w_size - gt ? e.strstart - (e.w_size - gt) : 0, u = e.window, l = e.w_mask, k = e.prev, X = e.strstart + It, g = u[r + o - 1], b = u[r + o];
    e.prev_length >= e.good_match && (n >>= 2), s > e.lookahead && (s = e.lookahead);
    do
      if (i = t, !(u[i + o] !== b || u[i + o - 1] !== g || u[i] !== u[r] || u[++i] !== u[r + 1])) {
        r += 2, i++;
        do
          ;
        while (u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && u[++r] === u[++i] && r < X);
        if (a = It - (X - r), r = X - It, a > o) {
          if (e.match_start = t, o = a, a >= s) break;
          g = u[r + o - 1], b = u[r + o];
        }
      }
    while ((t = k[t & l]) > y && --n !== 0);
    return o <= e.lookahead ? o : e.lookahead;
  }
  function rr(e) {
    var t = e.w_size, n, r, i, a, o;
    do {
      if (a = e.window_size - e.lookahead - e.strstart, e.strstart >= t + (t - gt)) {
        rt.arraySet(e.window, e.window, t, t, 0), e.match_start -= t, e.strstart -= t, e.block_start -= t, r = e.hash_size, n = r;
        do
          i = e.head[--n], e.head[n] = i >= t ? i - t : 0;
        while (--r);
        r = t, n = r;
        do
          i = e.prev[--n], e.prev[n] = i >= t ? i - t : 0;
        while (--r);
        a += t;
      }
      if (e.strm.avail_in === 0) break;
      if (r = gl(e.strm, e.window, e.strstart + e.lookahead, a), e.lookahead += r, e.lookahead + e.insert >= Ee) for (o = e.strstart - e.insert, e.ins_h = e.window[o], e.ins_h = (e.ins_h << e.hash_shift ^ e.window[o + 1]) & e.hash_mask; e.insert && (e.ins_h = (e.ins_h << e.hash_shift ^ e.window[o + Ee - 1]) & e.hash_mask, e.prev[o & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = o, o++, e.insert--, !(e.lookahead + e.insert < Ee)); ) ;
    } while (e.lookahead < gt && e.strm.avail_in !== 0);
  }
  function bl(e, t) {
    var n = 65535;
    for (n > e.pending_buf_size - 5 && (n = e.pending_buf_size - 5); ; ) {
      if (e.lookahead <= 1) {
        if (rr(e), e.lookahead === 0 && t === sr) return Qe;
        if (e.lookahead === 0) break;
      }
      e.strstart += e.lookahead, e.lookahead = 0;
      var r = e.block_start + n;
      if ((e.strstart === 0 || e.strstart >= r) && (e.lookahead = e.strstart - r, e.strstart = r, Ve(e, false), e.strm.avail_out === 0) || e.strstart - e.block_start >= e.w_size - gt && (Ve(e, false), e.strm.avail_out === 0)) return Qe;
    }
    return e.insert = 0, t === jt ? (Ve(e, true), e.strm.avail_out === 0 ? tr : mr) : (e.strstart > e.block_start && (Ve(e, false), e.strm.avail_out === 0), Qe);
  }
  function Qn(e, t) {
    for (var n, r; ; ) {
      if (e.lookahead < gt) {
        if (rr(e), e.lookahead < gt && t === sr) return Qe;
        if (e.lookahead === 0) break;
      }
      if (n = 0, e.lookahead >= Ee && (e.ins_h = (e.ins_h << e.hash_shift ^ e.window[e.strstart + Ee - 1]) & e.hash_mask, n = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart), n !== 0 && e.strstart - n <= e.w_size - gt && (e.match_length = jo(e, n)), e.match_length >= Ee) if (r = pt._tr_tally(e, e.strstart - e.match_start, e.match_length - Ee), e.lookahead -= e.match_length, e.match_length <= e.max_lazy_match && e.lookahead >= Ee) {
        e.match_length--;
        do
          e.strstart++, e.ins_h = (e.ins_h << e.hash_shift ^ e.window[e.strstart + Ee - 1]) & e.hash_mask, n = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart;
        while (--e.match_length !== 0);
        e.strstart++;
      } else e.strstart += e.match_length, e.match_length = 0, e.ins_h = e.window[e.strstart], e.ins_h = (e.ins_h << e.hash_shift ^ e.window[e.strstart + 1]) & e.hash_mask;
      else r = pt._tr_tally(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++;
      if (r && (Ve(e, false), e.strm.avail_out === 0)) return Qe;
    }
    return e.insert = e.strstart < Ee - 1 ? e.strstart : Ee - 1, t === jt ? (Ve(e, true), e.strm.avail_out === 0 ? tr : mr) : e.last_lit && (Ve(e, false), e.strm.avail_out === 0) ? Qe : zr;
  }
  function lr(e, t) {
    for (var n, r, i; ; ) {
      if (e.lookahead < gt) {
        if (rr(e), e.lookahead < gt && t === sr) return Qe;
        if (e.lookahead === 0) break;
      }
      if (n = 0, e.lookahead >= Ee && (e.ins_h = (e.ins_h << e.hash_shift ^ e.window[e.strstart + Ee - 1]) & e.hash_mask, n = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart), e.prev_length = e.match_length, e.prev_match = e.match_start, e.match_length = Ee - 1, n !== 0 && e.prev_length < e.max_lazy_match && e.strstart - n <= e.w_size - gt && (e.match_length = jo(e, n), e.match_length <= 5 && (e.strategy === nl || e.match_length === Ee && e.strstart - e.match_start > 4096) && (e.match_length = Ee - 1)), e.prev_length >= Ee && e.match_length <= e.prev_length) {
        i = e.strstart + e.lookahead - Ee, r = pt._tr_tally(e, e.strstart - 1 - e.prev_match, e.prev_length - Ee), e.lookahead -= e.prev_length - 1, e.prev_length -= 2;
        do
          ++e.strstart <= i && (e.ins_h = (e.ins_h << e.hash_shift ^ e.window[e.strstart + Ee - 1]) & e.hash_mask, n = e.prev[e.strstart & e.w_mask] = e.head[e.ins_h], e.head[e.ins_h] = e.strstart);
        while (--e.prev_length !== 0);
        if (e.match_available = 0, e.match_length = Ee - 1, e.strstart++, r && (Ve(e, false), e.strm.avail_out === 0)) return Qe;
      } else if (e.match_available) {
        if (r = pt._tr_tally(e, 0, e.window[e.strstart - 1]), r && Ve(e, false), e.strstart++, e.lookahead--, e.strm.avail_out === 0) return Qe;
      } else e.match_available = 1, e.strstart++, e.lookahead--;
    }
    return e.match_available && (r = pt._tr_tally(e, 0, e.window[e.strstart - 1]), e.match_available = 0), e.insert = e.strstart < Ee - 1 ? e.strstart : Ee - 1, t === jt ? (Ve(e, true), e.strm.avail_out === 0 ? tr : mr) : e.last_lit && (Ve(e, false), e.strm.avail_out === 0) ? Qe : zr;
  }
  function ml(e, t) {
    for (var n, r, i, a, o = e.window; ; ) {
      if (e.lookahead <= It) {
        if (rr(e), e.lookahead <= It && t === sr) return Qe;
        if (e.lookahead === 0) break;
      }
      if (e.match_length = 0, e.lookahead >= Ee && e.strstart > 0 && (i = e.strstart - 1, r = o[i], r === o[++i] && r === o[++i] && r === o[++i])) {
        a = e.strstart + It;
        do
          ;
        while (r === o[++i] && r === o[++i] && r === o[++i] && r === o[++i] && r === o[++i] && r === o[++i] && r === o[++i] && r === o[++i] && i < a);
        e.match_length = It - (a - i), e.match_length > e.lookahead && (e.match_length = e.lookahead);
      }
      if (e.match_length >= Ee ? (n = pt._tr_tally(e, 1, e.match_length - Ee), e.lookahead -= e.match_length, e.strstart += e.match_length, e.match_length = 0) : (n = pt._tr_tally(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++), n && (Ve(e, false), e.strm.avail_out === 0)) return Qe;
    }
    return e.insert = 0, t === jt ? (Ve(e, true), e.strm.avail_out === 0 ? tr : mr) : e.last_lit && (Ve(e, false), e.strm.avail_out === 0) ? Qe : zr;
  }
  function wl(e, t) {
    for (var n; ; ) {
      if (e.lookahead === 0 && (rr(e), e.lookahead === 0)) {
        if (t === sr) return Qe;
        break;
      }
      if (e.match_length = 0, n = pt._tr_tally(e, 0, e.window[e.strstart]), e.lookahead--, e.strstart++, n && (Ve(e, false), e.strm.avail_out === 0)) return Qe;
    }
    return e.insert = 0, t === jt ? (Ve(e, true), e.strm.avail_out === 0 ? tr : mr) : e.last_lit && (Ve(e, false), e.strm.avail_out === 0) ? Qe : zr;
  }
  function Xt(e, t, n, r, i) {
    this.good_length = e, this.max_lazy = t, this.nice_length = n, this.max_chain = r, this.func = i;
  }
  var cr;
  cr = [
    new Xt(0, 0, 0, 0, bl),
    new Xt(4, 4, 8, 4, Qn),
    new Xt(4, 5, 16, 8, Qn),
    new Xt(4, 6, 32, 32, Qn),
    new Xt(4, 4, 16, 16, lr),
    new Xt(8, 16, 32, 32, lr),
    new Xt(8, 16, 128, 128, lr),
    new Xt(8, 32, 128, 256, lr),
    new Xt(32, 128, 258, 1024, lr),
    new Xt(32, 258, 258, 4096, lr)
  ];
  function kl(e) {
    e.window_size = 2 * e.w_size, Bt(e.head), e.max_lazy_match = cr[e.level].max_lazy, e.good_match = cr[e.level].good_length, e.nice_match = cr[e.level].nice_length, e.max_chain_length = cr[e.level].max_chain, e.strstart = 0, e.block_start = 0, e.lookahead = 0, e.insert = 0, e.match_length = e.prev_length = Ee - 1, e.match_available = 0, e.ins_h = 0;
  }
  function Sl() {
    this.strm = null, this.status = 0, this.pending_buf = null, this.pending_buf_size = 0, this.pending_out = 0, this.pending = 0, this.wrap = 0, this.gzhead = null, this.gzindex = 0, this.method = gn, this.last_flush = -1, this.w_size = 0, this.w_bits = 0, this.w_mask = 0, this.window = null, this.window_size = 0, this.prev = null, this.head = null, this.ins_h = 0, this.hash_size = 0, this.hash_bits = 0, this.hash_mask = 0, this.hash_shift = 0, this.block_start = 0, this.match_length = 0, this.prev_match = 0, this.match_available = 0, this.strstart = 0, this.match_start = 0, this.lookahead = 0, this.prev_length = 0, this.max_chain_length = 0, this.max_lazy_match = 0, this.level = 0, this.strategy = 0, this.good_match = 0, this.nice_match = 0, this.dyn_ltree = new rt.Buf16(pl * 2), this.dyn_dtree = new rt.Buf16((2 * dl + 1) * 2), this.bl_tree = new rt.Buf16((2 * _l + 1) * 2), Bt(this.dyn_ltree), Bt(this.dyn_dtree), Bt(this.bl_tree), this.l_desc = null, this.d_desc = null, this.bl_desc = null, this.bl_count = new rt.Buf16(vl + 1), this.heap = new rt.Buf16(2 * ei + 1), Bt(this.heap), this.heap_len = 0, this.heap_max = 0, this.depth = new rt.Buf16(2 * ei + 1), Bt(this.depth), this.l_buf = 0, this.lit_bufsize = 0, this.last_lit = 0, this.d_buf = 0, this.opt_len = 0, this.static_len = 0, this.matches = 0, this.insert = 0, this.bi_buf = 0, this.bi_valid = 0;
  }
  function Ho(e) {
    var t;
    return !e || !e.state ? Qt(e, vt) : (e.total_in = e.total_out = 0, e.data_type = sl, t = e.state, t.pending = 0, t.pending_out = 0, t.wrap < 0 && (t.wrap = -t.wrap), t.status = t.wrap ? bn : $t, e.adler = t.wrap === 2 ? 0 : 1, t.last_flush = sr, pt._tr_init(t), At);
  }
  function Wo(e) {
    var t = Ho(e);
    return t === At && kl(e.state), t;
  }
  function El(e, t) {
    return !e || !e.state || e.state.wrap !== 2 ? vt : (e.state.gzhead = t, At);
  }
  function zo(e, t, n, r, i, a) {
    if (!e) return vt;
    var o = 1;
    if (t === rl && (t = 6), r < 0 ? (o = 0, r = -r) : r > 15 && (o = 2, r -= 16), i < 1 || i > ul || n !== gn || r < 8 || r > 15 || t < 0 || t > 9 || a < 0 || a > al) return Qt(e, vt);
    r === 8 && (r = 9);
    var s = new Sl();
    return e.state = s, s.strm = e, s.wrap = o, s.gzhead = null, s.w_bits = r, s.w_size = 1 << s.w_bits, s.w_mask = s.w_size - 1, s.hash_bits = i + 7, s.hash_size = 1 << s.hash_bits, s.hash_mask = s.hash_size - 1, s.hash_shift = ~~((s.hash_bits + Ee - 1) / Ee), s.window = new rt.Buf8(s.w_size * 2), s.head = new rt.Buf16(s.hash_size), s.prev = new rt.Buf16(s.w_size), s.lit_bufsize = 1 << i + 6, s.pending_buf_size = s.lit_bufsize * 4, s.pending_buf = new rt.Buf8(s.pending_buf_size), s.d_buf = 1 * s.lit_bufsize, s.l_buf = 3 * s.lit_bufsize, s.level = t, s.strategy = a, s.method = n, Wo(e);
  }
  function Kl(e, t) {
    return zo(e, t, gn, ll, fl, ol);
  }
  function Xl(e, t) {
    var n, r, i, a;
    if (!e || !e.state || t > ba || t < 0) return e ? Qt(e, vt) : vt;
    if (r = e.state, !e.output || !e.input && e.avail_in !== 0 || r.status === Fr && t !== jt) return Qt(e, e.avail_out === 0 ? In : vt);
    if (r.strm = e, n = r.last_flush, r.last_flush = t, r.status === bn) if (r.wrap === 2) e.adler = 0, Fe(r, 31), Fe(r, 139), Fe(r, 8), r.gzhead ? (Fe(r, (r.gzhead.text ? 1 : 0) + (r.gzhead.hcrc ? 2 : 0) + (r.gzhead.extra ? 4 : 0) + (r.gzhead.name ? 8 : 0) + (r.gzhead.comment ? 16 : 0)), Fe(r, r.gzhead.time & 255), Fe(r, r.gzhead.time >> 8 & 255), Fe(r, r.gzhead.time >> 16 & 255), Fe(r, r.gzhead.time >> 24 & 255), Fe(r, r.level === 9 ? 2 : r.strategy >= on || r.level < 2 ? 4 : 0), Fe(r, r.gzhead.os & 255), r.gzhead.extra && r.gzhead.extra.length && (Fe(r, r.gzhead.extra.length & 255), Fe(r, r.gzhead.extra.length >> 8 & 255)), r.gzhead.hcrc && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending, 0)), r.gzindex = 0, r.status = ti) : (Fe(r, 0), Fe(r, 0), Fe(r, 0), Fe(r, 0), Fe(r, 0), Fe(r, r.level === 9 ? 2 : r.strategy >= on || r.level < 2 ? 4 : 0), Fe(r, xl), r.status = $t);
    else {
      var o = gn + (r.w_bits - 8 << 4) << 8, s = -1;
      r.strategy >= on || r.level < 2 ? s = 0 : r.level < 6 ? s = 1 : r.level === 6 ? s = 2 : s = 3, o |= s << 6, r.strstart !== 0 && (o |= yl), o += 31 - o % 31, r.status = $t, Sr(r, o), r.strstart !== 0 && (Sr(r, e.adler >>> 16), Sr(r, e.adler & 65535)), e.adler = 1;
    }
    if (r.status === ti) if (r.gzhead.extra) {
      for (i = r.pending; r.gzindex < (r.gzhead.extra.length & 65535) && !(r.pending === r.pending_buf_size && (r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), Ot(e), i = r.pending, r.pending === r.pending_buf_size)); ) Fe(r, r.gzhead.extra[r.gzindex] & 255), r.gzindex++;
      r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), r.gzindex === r.gzhead.extra.length && (r.gzindex = 0, r.status = fn);
    } else r.status = fn;
    if (r.status === fn) if (r.gzhead.name) {
      i = r.pending;
      do {
        if (r.pending === r.pending_buf_size && (r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), Ot(e), i = r.pending, r.pending === r.pending_buf_size)) {
          a = 1;
          break;
        }
        r.gzindex < r.gzhead.name.length ? a = r.gzhead.name.charCodeAt(r.gzindex++) & 255 : a = 0, Fe(r, a);
      } while (a !== 0);
      r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), a === 0 && (r.gzindex = 0, r.status = cn);
    } else r.status = cn;
    if (r.status === cn) if (r.gzhead.comment) {
      i = r.pending;
      do {
        if (r.pending === r.pending_buf_size && (r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), Ot(e), i = r.pending, r.pending === r.pending_buf_size)) {
          a = 1;
          break;
        }
        r.gzindex < r.gzhead.comment.length ? a = r.gzhead.comment.charCodeAt(r.gzindex++) & 255 : a = 0, Fe(r, a);
      } while (a !== 0);
      r.gzhead.hcrc && r.pending > i && (e.adler = (0, Dt.default)(e.adler, r.pending_buf, r.pending - i, i)), a === 0 && (r.status = hn);
    } else r.status = hn;
    if (r.status === hn && (r.gzhead.hcrc ? (r.pending + 2 > r.pending_buf_size && Ot(e), r.pending + 2 <= r.pending_buf_size && (Fe(r, e.adler & 255), Fe(r, e.adler >> 8 & 255), e.adler = 0, r.status = $t)) : r.status = $t), r.pending !== 0) {
      if (Ot(e), e.avail_out === 0) return r.last_flush = -1, At;
    } else if (e.avail_in === 0 && wa(t) <= wa(n) && t !== jt) return Qt(e, In);
    if (r.status === Fr && e.avail_in !== 0) return Qt(e, In);
    if (e.avail_in !== 0 || r.lookahead !== 0 || t !== sr && r.status !== Fr) {
      var y = r.strategy === on ? wl(r, t) : r.strategy === il ? ml(r, t) : cr[r.level].func(r, t);
      if ((y === tr || y === mr) && (r.status = Fr), y === Qe || y === tr) return e.avail_out === 0 && (r.last_flush = -1), At;
      if (y === zr && (t === Ju ? pt._tr_align(r) : t !== ba && (pt._tr_stored_block(r, 0, 0, false), t === el && (Bt(r.head), r.lookahead === 0 && (r.strstart = 0, r.block_start = 0, r.insert = 0))), Ot(e), e.avail_out === 0)) return r.last_flush = -1, At;
    }
    return t !== jt ? At : r.wrap <= 0 ? ma : (r.wrap === 2 ? (Fe(r, e.adler & 255), Fe(r, e.adler >> 8 & 255), Fe(r, e.adler >> 16 & 255), Fe(r, e.adler >> 24 & 255), Fe(r, e.total_in & 255), Fe(r, e.total_in >> 8 & 255), Fe(r, e.total_in >> 16 & 255), Fe(r, e.total_in >> 24 & 255)) : (Sr(r, e.adler >>> 16), Sr(r, e.adler & 65535)), Ot(e), r.wrap > 0 && (r.wrap = -r.wrap), r.pending !== 0 ? At : ma);
  }
  function Fl(e) {
    var t;
    return !e || !e.state ? vt : (t = e.state.status, t !== bn && t !== ti && t !== fn && t !== cn && t !== hn && t !== $t && t !== Fr ? Qt(e, vt) : (e.state = null, t === $t ? Qt(e, tl) : At));
  }
  function Cl(e, t) {
    var n = t.length, r, i, a, o, s, y, u, l;
    if (!e || !e.state || (r = e.state, o = r.wrap, o === 2 || o === 1 && r.status !== bn || r.lookahead)) return vt;
    for (o === 1 && (e.adler = (0, Qo.default)(e.adler, t, n, 0)), r.wrap = 0, n >= r.w_size && (o === 0 && (Bt(r.head), r.strstart = 0, r.block_start = 0, r.insert = 0), l = new rt.Buf8(r.w_size), rt.arraySet(l, t, n - r.w_size, r.w_size, 0), t = l, n = r.w_size), s = e.avail_in, y = e.next_in, u = e.input, e.avail_in = n, e.next_in = 0, e.input = t, rr(r); r.lookahead >= Ee; ) {
      i = r.strstart, a = r.lookahead - (Ee - 1);
      do
        r.ins_h = (r.ins_h << r.hash_shift ^ r.window[i + Ee - 1]) & r.hash_mask, r.prev[i & r.w_mask] = r.head[r.ins_h], r.head[r.ins_h] = i, i++;
      while (--a);
      r.strstart = i, r.lookahead = Ee - 1, rr(r);
    }
    return r.strstart += r.lookahead, r.block_start = r.strstart, r.insert = r.lookahead, r.lookahead = 0, r.match_length = r.prev_length = Ee - 1, r.match_available = 0, e.next_in = y, e.input = u, e.avail_in = s, r.wrap = o, At;
  }
  ge.deflateInfo = "pako deflate (from Nodeca project)";
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = ge, n = r(_i);
    function r(l) {
      return l && l.__esModule ? l : {
        default: l
      };
    }
    function i(l) {
      "@babel/helpers - typeof";
      return i = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(k) {
        return typeof k;
      } : function(k) {
        return k && typeof Symbol == "function" && k.constructor === Symbol && k !== Symbol.prototype ? "symbol" : typeof k;
      }, i(l);
    }
    function a(l, k) {
      if (!(l instanceof k)) throw new TypeError("Cannot call a class as a function");
    }
    function o(l, k) {
      for (var X = 0; X < k.length; X++) {
        var g = k[X];
        g.enumerable = g.enumerable || false, g.configurable = true, "value" in g && (g.writable = true), Object.defineProperty(l, y(g.key), g);
      }
    }
    function s(l, k, X) {
      return k && o(l.prototype, k), Object.defineProperty(l, "prototype", {
        writable: false
      }), l;
    }
    function y(l) {
      var k = u(l, "string");
      return i(k) == "symbol" ? k : k + "";
    }
    function u(l, k) {
      if (i(l) != "object" || !l) return l;
      var X = l[Symbol.toPrimitive];
      if (X !== void 0) {
        var g = X.call(l, k);
        if (i(g) != "object") return g;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(l);
    }
    e.default = function() {
      function l() {
        a(this, l), this.strm = new n.default(), this.chunkSize = 1024 * 10 * 10, this.outputBuffer = new Uint8Array(this.chunkSize), (0, t.deflateInit)(this.strm, t.Z_DEFAULT_COMPRESSION);
      }
      return s(l, [
        {
          key: "deflate",
          value: function(X) {
            this.strm.input = X, this.strm.avail_in = this.strm.input.length, this.strm.next_in = 0, this.strm.output = this.outputBuffer, this.strm.avail_out = this.chunkSize, this.strm.next_out = 0;
            var g = (0, t.deflate)(this.strm, t.Z_FULL_FLUSH), b = new Uint8Array(this.strm.output.buffer, 0, this.strm.next_out);
            if (g < 0) throw new Error("zlib deflate failed");
            if (this.strm.avail_in > 0) {
              var d = [
                b
              ], f = b.length;
              do {
                if (this.strm.output = new Uint8Array(this.chunkSize), this.strm.next_out = 0, this.strm.avail_out = this.chunkSize, g = (0, t.deflate)(this.strm, t.Z_FULL_FLUSH), g < 0) throw new Error("zlib deflate failed");
                var c = new Uint8Array(this.strm.output.buffer, 0, this.strm.next_out);
                f += c.length, d.push(c);
              } while (this.strm.avail_in > 0);
              for (var h = new Uint8Array(f), K = 0, x = 0; x < d.length; x++) h.set(d[x], K), K += d[x].length;
              b = h;
            }
            return this.strm.input = null, this.strm.avail_in = 0, this.strm.next_in = 0, b;
          }
        }
      ]);
    }();
  })(wo);
  var Go = {}, Gr = {}, Vr = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0, e.default = {
      XK_VoidSymbol: 16777215,
      XK_BackSpace: 65288,
      XK_Tab: 65289,
      XK_Linefeed: 65290,
      XK_Clear: 65291,
      XK_Return: 65293,
      XK_Pause: 65299,
      XK_Scroll_Lock: 65300,
      XK_Sys_Req: 65301,
      XK_Escape: 65307,
      XK_Delete: 65535,
      XK_Multi_key: 65312,
      XK_Codeinput: 65335,
      XK_SingleCandidate: 65340,
      XK_MultipleCandidate: 65341,
      XK_PreviousCandidate: 65342,
      XK_Kanji: 65313,
      XK_Muhenkan: 65314,
      XK_Henkan_Mode: 65315,
      XK_Henkan: 65315,
      XK_Romaji: 65316,
      XK_Hiragana: 65317,
      XK_Katakana: 65318,
      XK_Hiragana_Katakana: 65319,
      XK_Zenkaku: 65320,
      XK_Hankaku: 65321,
      XK_Zenkaku_Hankaku: 65322,
      XK_Touroku: 65323,
      XK_Massyo: 65324,
      XK_Kana_Lock: 65325,
      XK_Kana_Shift: 65326,
      XK_Eisu_Shift: 65327,
      XK_Eisu_toggle: 65328,
      XK_Kanji_Bangou: 65335,
      XK_Zen_Koho: 65341,
      XK_Mae_Koho: 65342,
      XK_Home: 65360,
      XK_Left: 65361,
      XK_Up: 65362,
      XK_Right: 65363,
      XK_Down: 65364,
      XK_Prior: 65365,
      XK_Page_Up: 65365,
      XK_Next: 65366,
      XK_Page_Down: 65366,
      XK_End: 65367,
      XK_Begin: 65368,
      XK_Select: 65376,
      XK_Print: 65377,
      XK_Execute: 65378,
      XK_Insert: 65379,
      XK_Undo: 65381,
      XK_Redo: 65382,
      XK_Menu: 65383,
      XK_Find: 65384,
      XK_Cancel: 65385,
      XK_Help: 65386,
      XK_Break: 65387,
      XK_Mode_switch: 65406,
      XK_script_switch: 65406,
      XK_Num_Lock: 65407,
      XK_KP_Space: 65408,
      XK_KP_Tab: 65417,
      XK_KP_Enter: 65421,
      XK_KP_F1: 65425,
      XK_KP_F2: 65426,
      XK_KP_F3: 65427,
      XK_KP_F4: 65428,
      XK_KP_Home: 65429,
      XK_KP_Left: 65430,
      XK_KP_Up: 65431,
      XK_KP_Right: 65432,
      XK_KP_Down: 65433,
      XK_KP_Prior: 65434,
      XK_KP_Page_Up: 65434,
      XK_KP_Next: 65435,
      XK_KP_Page_Down: 65435,
      XK_KP_End: 65436,
      XK_KP_Begin: 65437,
      XK_KP_Insert: 65438,
      XK_KP_Delete: 65439,
      XK_KP_Equal: 65469,
      XK_KP_Multiply: 65450,
      XK_KP_Add: 65451,
      XK_KP_Separator: 65452,
      XK_KP_Subtract: 65453,
      XK_KP_Decimal: 65454,
      XK_KP_Divide: 65455,
      XK_KP_0: 65456,
      XK_KP_1: 65457,
      XK_KP_2: 65458,
      XK_KP_3: 65459,
      XK_KP_4: 65460,
      XK_KP_5: 65461,
      XK_KP_6: 65462,
      XK_KP_7: 65463,
      XK_KP_8: 65464,
      XK_KP_9: 65465,
      XK_F1: 65470,
      XK_F2: 65471,
      XK_F3: 65472,
      XK_F4: 65473,
      XK_F5: 65474,
      XK_F6: 65475,
      XK_F7: 65476,
      XK_F8: 65477,
      XK_F9: 65478,
      XK_F10: 65479,
      XK_F11: 65480,
      XK_L1: 65480,
      XK_F12: 65481,
      XK_L2: 65481,
      XK_F13: 65482,
      XK_L3: 65482,
      XK_F14: 65483,
      XK_L4: 65483,
      XK_F15: 65484,
      XK_L5: 65484,
      XK_F16: 65485,
      XK_L6: 65485,
      XK_F17: 65486,
      XK_L7: 65486,
      XK_F18: 65487,
      XK_L8: 65487,
      XK_F19: 65488,
      XK_L9: 65488,
      XK_F20: 65489,
      XK_L10: 65489,
      XK_F21: 65490,
      XK_R1: 65490,
      XK_F22: 65491,
      XK_R2: 65491,
      XK_F23: 65492,
      XK_R3: 65492,
      XK_F24: 65493,
      XK_R4: 65493,
      XK_F25: 65494,
      XK_R5: 65494,
      XK_F26: 65495,
      XK_R6: 65495,
      XK_F27: 65496,
      XK_R7: 65496,
      XK_F28: 65497,
      XK_R8: 65497,
      XK_F29: 65498,
      XK_R9: 65498,
      XK_F30: 65499,
      XK_R10: 65499,
      XK_F31: 65500,
      XK_R11: 65500,
      XK_F32: 65501,
      XK_R12: 65501,
      XK_F33: 65502,
      XK_R13: 65502,
      XK_F34: 65503,
      XK_R14: 65503,
      XK_F35: 65504,
      XK_R15: 65504,
      XK_Shift_L: 65505,
      XK_Shift_R: 65506,
      XK_Control_L: 65507,
      XK_Control_R: 65508,
      XK_Caps_Lock: 65509,
      XK_Shift_Lock: 65510,
      XK_Meta_L: 65511,
      XK_Meta_R: 65512,
      XK_Alt_L: 65513,
      XK_Alt_R: 65514,
      XK_Super_L: 65515,
      XK_Super_R: 65516,
      XK_Hyper_L: 65517,
      XK_Hyper_R: 65518,
      XK_ISO_Level3_Shift: 65027,
      XK_ISO_Next_Group: 65032,
      XK_ISO_Prev_Group: 65034,
      XK_ISO_First_Group: 65036,
      XK_ISO_Last_Group: 65038,
      XK_space: 32,
      XK_exclam: 33,
      XK_quotedbl: 34,
      XK_numbersign: 35,
      XK_dollar: 36,
      XK_percent: 37,
      XK_ampersand: 38,
      XK_apostrophe: 39,
      XK_quoteright: 39,
      XK_parenleft: 40,
      XK_parenright: 41,
      XK_asterisk: 42,
      XK_plus: 43,
      XK_comma: 44,
      XK_minus: 45,
      XK_period: 46,
      XK_slash: 47,
      XK_0: 48,
      XK_1: 49,
      XK_2: 50,
      XK_3: 51,
      XK_4: 52,
      XK_5: 53,
      XK_6: 54,
      XK_7: 55,
      XK_8: 56,
      XK_9: 57,
      XK_colon: 58,
      XK_semicolon: 59,
      XK_less: 60,
      XK_equal: 61,
      XK_greater: 62,
      XK_question: 63,
      XK_at: 64,
      XK_A: 65,
      XK_B: 66,
      XK_C: 67,
      XK_D: 68,
      XK_E: 69,
      XK_F: 70,
      XK_G: 71,
      XK_H: 72,
      XK_I: 73,
      XK_J: 74,
      XK_K: 75,
      XK_L: 76,
      XK_M: 77,
      XK_N: 78,
      XK_O: 79,
      XK_P: 80,
      XK_Q: 81,
      XK_R: 82,
      XK_S: 83,
      XK_T: 84,
      XK_U: 85,
      XK_V: 86,
      XK_W: 87,
      XK_X: 88,
      XK_Y: 89,
      XK_Z: 90,
      XK_bracketleft: 91,
      XK_backslash: 92,
      XK_bracketright: 93,
      XK_asciicircum: 94,
      XK_underscore: 95,
      XK_grave: 96,
      XK_quoteleft: 96,
      XK_a: 97,
      XK_b: 98,
      XK_c: 99,
      XK_d: 100,
      XK_e: 101,
      XK_f: 102,
      XK_g: 103,
      XK_h: 104,
      XK_i: 105,
      XK_j: 106,
      XK_k: 107,
      XK_l: 108,
      XK_m: 109,
      XK_n: 110,
      XK_o: 111,
      XK_p: 112,
      XK_q: 113,
      XK_r: 114,
      XK_s: 115,
      XK_t: 116,
      XK_u: 117,
      XK_v: 118,
      XK_w: 119,
      XK_x: 120,
      XK_y: 121,
      XK_z: 122,
      XK_braceleft: 123,
      XK_bar: 124,
      XK_braceright: 125,
      XK_asciitilde: 126,
      XK_nobreakspace: 160,
      XK_exclamdown: 161,
      XK_cent: 162,
      XK_sterling: 163,
      XK_currency: 164,
      XK_yen: 165,
      XK_brokenbar: 166,
      XK_section: 167,
      XK_diaeresis: 168,
      XK_copyright: 169,
      XK_ordfeminine: 170,
      XK_guillemotleft: 171,
      XK_notsign: 172,
      XK_hyphen: 173,
      XK_registered: 174,
      XK_macron: 175,
      XK_degree: 176,
      XK_plusminus: 177,
      XK_twosuperior: 178,
      XK_threesuperior: 179,
      XK_acute: 180,
      XK_mu: 181,
      XK_paragraph: 182,
      XK_periodcentered: 183,
      XK_cedilla: 184,
      XK_onesuperior: 185,
      XK_masculine: 186,
      XK_guillemotright: 187,
      XK_onequarter: 188,
      XK_onehalf: 189,
      XK_threequarters: 190,
      XK_questiondown: 191,
      XK_Agrave: 192,
      XK_Aacute: 193,
      XK_Acircumflex: 194,
      XK_Atilde: 195,
      XK_Adiaeresis: 196,
      XK_Aring: 197,
      XK_AE: 198,
      XK_Ccedilla: 199,
      XK_Egrave: 200,
      XK_Eacute: 201,
      XK_Ecircumflex: 202,
      XK_Ediaeresis: 203,
      XK_Igrave: 204,
      XK_Iacute: 205,
      XK_Icircumflex: 206,
      XK_Idiaeresis: 207,
      XK_ETH: 208,
      XK_Eth: 208,
      XK_Ntilde: 209,
      XK_Ograve: 210,
      XK_Oacute: 211,
      XK_Ocircumflex: 212,
      XK_Otilde: 213,
      XK_Odiaeresis: 214,
      XK_multiply: 215,
      XK_Oslash: 216,
      XK_Ooblique: 216,
      XK_Ugrave: 217,
      XK_Uacute: 218,
      XK_Ucircumflex: 219,
      XK_Udiaeresis: 220,
      XK_Yacute: 221,
      XK_THORN: 222,
      XK_Thorn: 222,
      XK_ssharp: 223,
      XK_agrave: 224,
      XK_aacute: 225,
      XK_acircumflex: 226,
      XK_atilde: 227,
      XK_adiaeresis: 228,
      XK_aring: 229,
      XK_ae: 230,
      XK_ccedilla: 231,
      XK_egrave: 232,
      XK_eacute: 233,
      XK_ecircumflex: 234,
      XK_ediaeresis: 235,
      XK_igrave: 236,
      XK_iacute: 237,
      XK_icircumflex: 238,
      XK_idiaeresis: 239,
      XK_eth: 240,
      XK_ntilde: 241,
      XK_ograve: 242,
      XK_oacute: 243,
      XK_ocircumflex: 244,
      XK_otilde: 245,
      XK_odiaeresis: 246,
      XK_division: 247,
      XK_oslash: 248,
      XK_ooblique: 248,
      XK_ugrave: 249,
      XK_uacute: 250,
      XK_ucircumflex: 251,
      XK_udiaeresis: 252,
      XK_yacute: 253,
      XK_thorn: 254,
      XK_ydiaeresis: 255,
      XK_Hangul: 65329,
      XK_Hangul_Hanja: 65332,
      XK_Hangul_Jeonja: 65336,
      XF86XK_ModeLock: 269025025,
      XF86XK_MonBrightnessUp: 269025026,
      XF86XK_MonBrightnessDown: 269025027,
      XF86XK_KbdLightOnOff: 269025028,
      XF86XK_KbdBrightnessUp: 269025029,
      XF86XK_KbdBrightnessDown: 269025030,
      XF86XK_Standby: 269025040,
      XF86XK_AudioLowerVolume: 269025041,
      XF86XK_AudioMute: 269025042,
      XF86XK_AudioRaiseVolume: 269025043,
      XF86XK_AudioPlay: 269025044,
      XF86XK_AudioStop: 269025045,
      XF86XK_AudioPrev: 269025046,
      XF86XK_AudioNext: 269025047,
      XF86XK_HomePage: 269025048,
      XF86XK_Mail: 269025049,
      XF86XK_Start: 269025050,
      XF86XK_Search: 269025051,
      XF86XK_AudioRecord: 269025052,
      XF86XK_Calculator: 269025053,
      XF86XK_Memo: 269025054,
      XF86XK_ToDoList: 269025055,
      XF86XK_Calendar: 269025056,
      XF86XK_PowerDown: 269025057,
      XF86XK_ContrastAdjust: 269025058,
      XF86XK_RockerUp: 269025059,
      XF86XK_RockerDown: 269025060,
      XF86XK_RockerEnter: 269025061,
      XF86XK_Back: 269025062,
      XF86XK_Forward: 269025063,
      XF86XK_Stop: 269025064,
      XF86XK_Refresh: 269025065,
      XF86XK_PowerOff: 269025066,
      XF86XK_WakeUp: 269025067,
      XF86XK_Eject: 269025068,
      XF86XK_ScreenSaver: 269025069,
      XF86XK_WWW: 269025070,
      XF86XK_Sleep: 269025071,
      XF86XK_Favorites: 269025072,
      XF86XK_AudioPause: 269025073,
      XF86XK_AudioMedia: 269025074,
      XF86XK_MyComputer: 269025075,
      XF86XK_VendorHome: 269025076,
      XF86XK_LightBulb: 269025077,
      XF86XK_Shop: 269025078,
      XF86XK_History: 269025079,
      XF86XK_OpenURL: 269025080,
      XF86XK_AddFavorite: 269025081,
      XF86XK_HotLinks: 269025082,
      XF86XK_BrightnessAdjust: 269025083,
      XF86XK_Finance: 269025084,
      XF86XK_Community: 269025085,
      XF86XK_AudioRewind: 269025086,
      XF86XK_BackForward: 269025087,
      XF86XK_Launch0: 269025088,
      XF86XK_Launch1: 269025089,
      XF86XK_Launch2: 269025090,
      XF86XK_Launch3: 269025091,
      XF86XK_Launch4: 269025092,
      XF86XK_Launch5: 269025093,
      XF86XK_Launch6: 269025094,
      XF86XK_Launch7: 269025095,
      XF86XK_Launch8: 269025096,
      XF86XK_Launch9: 269025097,
      XF86XK_LaunchA: 269025098,
      XF86XK_LaunchB: 269025099,
      XF86XK_LaunchC: 269025100,
      XF86XK_LaunchD: 269025101,
      XF86XK_LaunchE: 269025102,
      XF86XK_LaunchF: 269025103,
      XF86XK_ApplicationLeft: 269025104,
      XF86XK_ApplicationRight: 269025105,
      XF86XK_Book: 269025106,
      XF86XK_CD: 269025107,
      XF86XK_Calculater: 269025108,
      XF86XK_Clear: 269025109,
      XF86XK_Close: 269025110,
      XF86XK_Copy: 269025111,
      XF86XK_Cut: 269025112,
      XF86XK_Display: 269025113,
      XF86XK_DOS: 269025114,
      XF86XK_Documents: 269025115,
      XF86XK_Excel: 269025116,
      XF86XK_Explorer: 269025117,
      XF86XK_Game: 269025118,
      XF86XK_Go: 269025119,
      XF86XK_iTouch: 269025120,
      XF86XK_LogOff: 269025121,
      XF86XK_Market: 269025122,
      XF86XK_Meeting: 269025123,
      XF86XK_MenuKB: 269025125,
      XF86XK_MenuPB: 269025126,
      XF86XK_MySites: 269025127,
      XF86XK_New: 269025128,
      XF86XK_News: 269025129,
      XF86XK_OfficeHome: 269025130,
      XF86XK_Open: 269025131,
      XF86XK_Option: 269025132,
      XF86XK_Paste: 269025133,
      XF86XK_Phone: 269025134,
      XF86XK_Q: 269025136,
      XF86XK_Reply: 269025138,
      XF86XK_Reload: 269025139,
      XF86XK_RotateWindows: 269025140,
      XF86XK_RotationPB: 269025141,
      XF86XK_RotationKB: 269025142,
      XF86XK_Save: 269025143,
      XF86XK_ScrollUp: 269025144,
      XF86XK_ScrollDown: 269025145,
      XF86XK_ScrollClick: 269025146,
      XF86XK_Send: 269025147,
      XF86XK_Spell: 269025148,
      XF86XK_SplitScreen: 269025149,
      XF86XK_Support: 269025150,
      XF86XK_TaskPane: 269025151,
      XF86XK_Terminal: 269025152,
      XF86XK_Tools: 269025153,
      XF86XK_Travel: 269025154,
      XF86XK_UserPB: 269025156,
      XF86XK_User1KB: 269025157,
      XF86XK_User2KB: 269025158,
      XF86XK_Video: 269025159,
      XF86XK_WheelButton: 269025160,
      XF86XK_Word: 269025161,
      XF86XK_Xfer: 269025162,
      XF86XK_ZoomIn: 269025163,
      XF86XK_ZoomOut: 269025164,
      XF86XK_Away: 269025165,
      XF86XK_Messenger: 269025166,
      XF86XK_WebCam: 269025167,
      XF86XK_MailForward: 269025168,
      XF86XK_Pictures: 269025169,
      XF86XK_Music: 269025170,
      XF86XK_Battery: 269025171,
      XF86XK_Bluetooth: 269025172,
      XF86XK_WLAN: 269025173,
      XF86XK_UWB: 269025174,
      XF86XK_AudioForward: 269025175,
      XF86XK_AudioRepeat: 269025176,
      XF86XK_AudioRandomPlay: 269025177,
      XF86XK_Subtitle: 269025178,
      XF86XK_AudioCycleTrack: 269025179,
      XF86XK_CycleAngle: 269025180,
      XF86XK_FrameBack: 269025181,
      XF86XK_FrameForward: 269025182,
      XF86XK_Time: 269025183,
      XF86XK_Select: 269025184,
      XF86XK_View: 269025185,
      XF86XK_TopMenu: 269025186,
      XF86XK_Red: 269025187,
      XF86XK_Green: 269025188,
      XF86XK_Yellow: 269025189,
      XF86XK_Blue: 269025190,
      XF86XK_Suspend: 269025191,
      XF86XK_Hibernate: 269025192,
      XF86XK_TouchpadToggle: 269025193,
      XF86XK_TouchpadOn: 269025200,
      XF86XK_TouchpadOff: 269025201,
      XF86XK_AudioMicMute: 269025202,
      XF86XK_Switch_VT_1: 269024769,
      XF86XK_Switch_VT_2: 269024770,
      XF86XK_Switch_VT_3: 269024771,
      XF86XK_Switch_VT_4: 269024772,
      XF86XK_Switch_VT_5: 269024773,
      XF86XK_Switch_VT_6: 269024774,
      XF86XK_Switch_VT_7: 269024775,
      XF86XK_Switch_VT_8: 269024776,
      XF86XK_Switch_VT_9: 269024777,
      XF86XK_Switch_VT_10: 269024778,
      XF86XK_Switch_VT_11: 269024779,
      XF86XK_Switch_VT_12: 269024780,
      XF86XK_Ungrab: 269024800,
      XF86XK_ClearGrab: 269024801,
      XF86XK_Next_VMode: 269024802,
      XF86XK_Prev_VMode: 269024803,
      XF86XK_LogWindowTree: 269024804,
      XF86XK_LogGrabInfo: 269024805
    };
  })(Vr);
  var Vo = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = {
      256: 960,
      257: 992,
      258: 451,
      259: 483,
      260: 417,
      261: 433,
      262: 454,
      263: 486,
      264: 710,
      265: 742,
      266: 709,
      267: 741,
      268: 456,
      269: 488,
      270: 463,
      271: 495,
      272: 464,
      273: 496,
      274: 938,
      275: 954,
      278: 972,
      279: 1004,
      280: 458,
      281: 490,
      282: 460,
      283: 492,
      284: 728,
      285: 760,
      286: 683,
      287: 699,
      288: 725,
      289: 757,
      290: 939,
      291: 955,
      292: 678,
      293: 694,
      294: 673,
      295: 689,
      296: 933,
      297: 949,
      298: 975,
      299: 1007,
      302: 967,
      303: 999,
      304: 681,
      305: 697,
      308: 684,
      309: 700,
      310: 979,
      311: 1011,
      312: 930,
      313: 453,
      314: 485,
      315: 934,
      316: 950,
      317: 421,
      318: 437,
      321: 419,
      322: 435,
      323: 465,
      324: 497,
      325: 977,
      326: 1009,
      327: 466,
      328: 498,
      330: 957,
      331: 959,
      332: 978,
      333: 1010,
      336: 469,
      337: 501,
      338: 5052,
      339: 5053,
      340: 448,
      341: 480,
      342: 931,
      343: 947,
      344: 472,
      345: 504,
      346: 422,
      347: 438,
      348: 734,
      349: 766,
      350: 426,
      351: 442,
      352: 425,
      353: 441,
      354: 478,
      355: 510,
      356: 427,
      357: 443,
      358: 940,
      359: 956,
      360: 989,
      361: 1021,
      362: 990,
      363: 1022,
      364: 733,
      365: 765,
      366: 473,
      367: 505,
      368: 475,
      369: 507,
      370: 985,
      371: 1017,
      376: 5054,
      377: 428,
      378: 444,
      379: 431,
      380: 447,
      381: 430,
      382: 446,
      402: 2294,
      466: 16777681,
      711: 439,
      728: 418,
      729: 511,
      731: 434,
      733: 445,
      901: 1966,
      902: 1953,
      904: 1954,
      905: 1955,
      906: 1956,
      908: 1959,
      910: 1960,
      911: 1963,
      912: 1974,
      913: 1985,
      914: 1986,
      915: 1987,
      916: 1988,
      917: 1989,
      918: 1990,
      919: 1991,
      920: 1992,
      921: 1993,
      922: 1994,
      923: 1995,
      924: 1996,
      925: 1997,
      926: 1998,
      927: 1999,
      928: 2e3,
      929: 2001,
      931: 2002,
      932: 2004,
      933: 2005,
      934: 2006,
      935: 2007,
      936: 2008,
      937: 2009,
      938: 1957,
      939: 1961,
      940: 1969,
      941: 1970,
      942: 1971,
      943: 1972,
      944: 1978,
      945: 2017,
      946: 2018,
      947: 2019,
      948: 2020,
      949: 2021,
      950: 2022,
      951: 2023,
      952: 2024,
      953: 2025,
      954: 2026,
      955: 2027,
      956: 2028,
      957: 2029,
      958: 2030,
      959: 2031,
      960: 2032,
      961: 2033,
      962: 2035,
      963: 2034,
      964: 2036,
      965: 2037,
      966: 2038,
      967: 2039,
      968: 2040,
      969: 2041,
      970: 1973,
      971: 1977,
      972: 1975,
      973: 1976,
      974: 1979,
      1025: 1715,
      1026: 1713,
      1027: 1714,
      1028: 1716,
      1029: 1717,
      1030: 1718,
      1031: 1719,
      1032: 1720,
      1033: 1721,
      1034: 1722,
      1035: 1723,
      1036: 1724,
      1038: 1726,
      1039: 1727,
      1040: 1761,
      1041: 1762,
      1042: 1783,
      1043: 1767,
      1044: 1764,
      1045: 1765,
      1046: 1782,
      1047: 1786,
      1048: 1769,
      1049: 1770,
      1050: 1771,
      1051: 1772,
      1052: 1773,
      1053: 1774,
      1054: 1775,
      1055: 1776,
      1056: 1778,
      1057: 1779,
      1058: 1780,
      1059: 1781,
      1060: 1766,
      1061: 1768,
      1062: 1763,
      1063: 1790,
      1064: 1787,
      1065: 1789,
      1066: 1791,
      1067: 1785,
      1068: 1784,
      1069: 1788,
      1070: 1760,
      1071: 1777,
      1072: 1729,
      1073: 1730,
      1074: 1751,
      1075: 1735,
      1076: 1732,
      1077: 1733,
      1078: 1750,
      1079: 1754,
      1080: 1737,
      1081: 1738,
      1082: 1739,
      1083: 1740,
      1084: 1741,
      1085: 1742,
      1086: 1743,
      1087: 1744,
      1088: 1746,
      1089: 1747,
      1090: 1748,
      1091: 1749,
      1092: 1734,
      1093: 1736,
      1094: 1731,
      1095: 1758,
      1096: 1755,
      1097: 1757,
      1098: 1759,
      1099: 1753,
      1100: 1752,
      1101: 1756,
      1102: 1728,
      1103: 1745,
      1105: 1699,
      1106: 1697,
      1107: 1698,
      1108: 1700,
      1109: 1701,
      1110: 1702,
      1111: 1703,
      1112: 1704,
      1113: 1705,
      1114: 1706,
      1115: 1707,
      1116: 1708,
      1118: 1710,
      1119: 1711,
      1168: 1725,
      1169: 1709,
      1488: 3296,
      1489: 3297,
      1490: 3298,
      1491: 3299,
      1492: 3300,
      1493: 3301,
      1494: 3302,
      1495: 3303,
      1496: 3304,
      1497: 3305,
      1498: 3306,
      1499: 3307,
      1500: 3308,
      1501: 3309,
      1502: 3310,
      1503: 3311,
      1504: 3312,
      1505: 3313,
      1506: 3314,
      1507: 3315,
      1508: 3316,
      1509: 3317,
      1510: 3318,
      1511: 3319,
      1512: 3320,
      1513: 3321,
      1514: 3322,
      1548: 1452,
      1563: 1467,
      1567: 1471,
      1569: 1473,
      1570: 1474,
      1571: 1475,
      1572: 1476,
      1573: 1477,
      1574: 1478,
      1575: 1479,
      1576: 1480,
      1577: 1481,
      1578: 1482,
      1579: 1483,
      1580: 1484,
      1581: 1485,
      1582: 1486,
      1583: 1487,
      1584: 1488,
      1585: 1489,
      1586: 1490,
      1587: 1491,
      1588: 1492,
      1589: 1493,
      1590: 1494,
      1591: 1495,
      1592: 1496,
      1593: 1497,
      1594: 1498,
      1600: 1504,
      1601: 1505,
      1602: 1506,
      1603: 1507,
      1604: 1508,
      1605: 1509,
      1606: 1510,
      1607: 1511,
      1608: 1512,
      1609: 1513,
      1610: 1514,
      1611: 1515,
      1612: 1516,
      1613: 1517,
      1614: 1518,
      1615: 1519,
      1616: 1520,
      1617: 1521,
      1618: 1522,
      3585: 3489,
      3586: 3490,
      3587: 3491,
      3588: 3492,
      3589: 3493,
      3590: 3494,
      3591: 3495,
      3592: 3496,
      3593: 3497,
      3594: 3498,
      3595: 3499,
      3596: 3500,
      3597: 3501,
      3598: 3502,
      3599: 3503,
      3600: 3504,
      3601: 3505,
      3602: 3506,
      3603: 3507,
      3604: 3508,
      3605: 3509,
      3606: 3510,
      3607: 3511,
      3608: 3512,
      3609: 3513,
      3610: 3514,
      3611: 3515,
      3612: 3516,
      3613: 3517,
      3614: 3518,
      3615: 3519,
      3616: 3520,
      3617: 3521,
      3618: 3522,
      3619: 3523,
      3620: 3524,
      3621: 3525,
      3622: 3526,
      3623: 3527,
      3624: 3528,
      3625: 3529,
      3626: 3530,
      3627: 3531,
      3628: 3532,
      3629: 3533,
      3630: 3534,
      3631: 3535,
      3632: 3536,
      3633: 3537,
      3634: 3538,
      3635: 3539,
      3636: 3540,
      3637: 3541,
      3638: 3542,
      3639: 3543,
      3640: 3544,
      3641: 3545,
      3642: 3546,
      3647: 3551,
      3648: 3552,
      3649: 3553,
      3650: 3554,
      3651: 3555,
      3652: 3556,
      3653: 3557,
      3654: 3558,
      3655: 3559,
      3656: 3560,
      3657: 3561,
      3658: 3562,
      3659: 3563,
      3660: 3564,
      3661: 3565,
      3664: 3568,
      3665: 3569,
      3666: 3570,
      3667: 3571,
      3668: 3572,
      3669: 3573,
      3670: 3574,
      3671: 3575,
      3672: 3576,
      3673: 3577,
      8194: 2722,
      8195: 2721,
      8196: 2723,
      8197: 2724,
      8199: 2725,
      8200: 2726,
      8201: 2727,
      8202: 2728,
      8210: 2747,
      8211: 2730,
      8212: 2729,
      8213: 1967,
      8215: 3295,
      8216: 2768,
      8217: 2769,
      8218: 2813,
      8220: 2770,
      8221: 2771,
      8222: 2814,
      8224: 2801,
      8225: 2802,
      8226: 2790,
      8229: 2735,
      8230: 2734,
      8240: 2773,
      8242: 2774,
      8243: 2775,
      8248: 2812,
      8254: 1150,
      8361: 3839,
      8364: 8364,
      8453: 2744,
      8470: 1712,
      8471: 2811,
      8478: 2772,
      8482: 2761,
      8531: 2736,
      8532: 2737,
      8533: 2738,
      8534: 2739,
      8535: 2740,
      8536: 2741,
      8537: 2742,
      8538: 2743,
      8539: 2755,
      8540: 2756,
      8541: 2757,
      8542: 2758,
      8592: 2299,
      8593: 2300,
      8594: 2301,
      8595: 2302,
      8658: 2254,
      8660: 2253,
      8706: 2287,
      8711: 2245,
      8728: 3018,
      8730: 2262,
      8733: 2241,
      8734: 2242,
      8743: 2270,
      8744: 2271,
      8745: 2268,
      8746: 2269,
      8747: 2239,
      8756: 2240,
      8764: 2248,
      8771: 2249,
      8773: 16785992,
      8800: 2237,
      8801: 2255,
      8804: 2236,
      8805: 2238,
      8834: 2266,
      8835: 2267,
      8866: 3068,
      8867: 3036,
      8868: 3010,
      8869: 3022,
      8968: 3027,
      8970: 3012,
      8981: 2810,
      8992: 2212,
      8993: 2213,
      9109: 3020,
      9115: 2219,
      9117: 2220,
      9118: 2221,
      9120: 2222,
      9121: 2215,
      9123: 2216,
      9124: 2217,
      9126: 2218,
      9128: 2223,
      9132: 2224,
      9143: 2209,
      9146: 2543,
      9147: 2544,
      9148: 2546,
      9149: 2547,
      9225: 2530,
      9226: 2533,
      9227: 2537,
      9228: 2531,
      9229: 2532,
      9251: 2732,
      9252: 2536,
      9472: 2211,
      9474: 2214,
      9484: 2210,
      9488: 2539,
      9492: 2541,
      9496: 2538,
      9500: 2548,
      9508: 2549,
      9516: 2551,
      9524: 2550,
      9532: 2542,
      9618: 2529,
      9642: 2791,
      9643: 2785,
      9644: 2779,
      9645: 2786,
      9646: 2783,
      9647: 2767,
      9650: 2792,
      9651: 2787,
      9654: 2781,
      9655: 2765,
      9660: 2793,
      9661: 2788,
      9664: 2780,
      9665: 2764,
      9670: 2528,
      9675: 2766,
      9679: 2782,
      9702: 2784,
      9734: 2789,
      9742: 2809,
      9747: 2762,
      9756: 2794,
      9758: 2795,
      9792: 2808,
      9794: 2807,
      9827: 2796,
      9829: 2798,
      9830: 2797,
      9837: 2806,
      9839: 2805,
      10003: 2803,
      10007: 2804,
      10013: 2777,
      10016: 2800,
      10216: 2748,
      10217: 2750,
      12289: 1188,
      12290: 1185,
      12300: 1186,
      12301: 1187,
      12443: 1246,
      12444: 1247,
      12449: 1191,
      12450: 1201,
      12451: 1192,
      12452: 1202,
      12453: 1193,
      12454: 1203,
      12455: 1194,
      12456: 1204,
      12457: 1195,
      12458: 1205,
      12459: 1206,
      12461: 1207,
      12463: 1208,
      12465: 1209,
      12467: 1210,
      12469: 1211,
      12471: 1212,
      12473: 1213,
      12475: 1214,
      12477: 1215,
      12479: 1216,
      12481: 1217,
      12483: 1199,
      12484: 1218,
      12486: 1219,
      12488: 1220,
      12490: 1221,
      12491: 1222,
      12492: 1223,
      12493: 1224,
      12494: 1225,
      12495: 1226,
      12498: 1227,
      12501: 1228,
      12504: 1229,
      12507: 1230,
      12510: 1231,
      12511: 1232,
      12512: 1233,
      12513: 1234,
      12514: 1235,
      12515: 1196,
      12516: 1236,
      12517: 1197,
      12518: 1237,
      12519: 1198,
      12520: 1238,
      12521: 1239,
      12522: 1240,
      12523: 1241,
      12524: 1242,
      12525: 1243,
      12527: 1244,
      12530: 1190,
      12531: 1245,
      12539: 1189,
      12540: 1200
    };
    e.default = {
      lookup: function(r) {
        if (r >= 32 && r <= 255) return r;
        var i = t[r];
        return i !== void 0 ? i : 16777216 | r;
      }
    };
  })(Vo);
  var Zo = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0, e.default = {
      8: "Backspace",
      9: "Tab",
      10: "NumpadClear",
      13: "Enter",
      16: "ShiftLeft",
      17: "ControlLeft",
      18: "AltLeft",
      19: "Pause",
      20: "CapsLock",
      21: "Lang1",
      25: "Lang2",
      27: "Escape",
      28: "Convert",
      29: "NonConvert",
      32: "Space",
      33: "PageUp",
      34: "PageDown",
      35: "End",
      36: "Home",
      37: "ArrowLeft",
      38: "ArrowUp",
      39: "ArrowRight",
      40: "ArrowDown",
      41: "Select",
      44: "PrintScreen",
      45: "Insert",
      46: "Delete",
      47: "Help",
      48: "Digit0",
      49: "Digit1",
      50: "Digit2",
      51: "Digit3",
      52: "Digit4",
      53: "Digit5",
      54: "Digit6",
      55: "Digit7",
      56: "Digit8",
      57: "Digit9",
      91: "MetaLeft",
      92: "MetaRight",
      93: "ContextMenu",
      95: "Sleep",
      96: "Numpad0",
      97: "Numpad1",
      98: "Numpad2",
      99: "Numpad3",
      100: "Numpad4",
      101: "Numpad5",
      102: "Numpad6",
      103: "Numpad7",
      104: "Numpad8",
      105: "Numpad9",
      106: "NumpadMultiply",
      107: "NumpadAdd",
      108: "NumpadDecimal",
      109: "NumpadSubtract",
      110: "NumpadDecimal",
      111: "NumpadDivide",
      112: "F1",
      113: "F2",
      114: "F3",
      115: "F4",
      116: "F5",
      117: "F6",
      118: "F7",
      119: "F8",
      120: "F9",
      121: "F10",
      122: "F11",
      123: "F12",
      124: "F13",
      125: "F14",
      126: "F15",
      127: "F16",
      128: "F17",
      129: "F18",
      130: "F19",
      131: "F20",
      132: "F21",
      133: "F22",
      134: "F23",
      135: "F24",
      144: "NumLock",
      145: "ScrollLock",
      166: "BrowserBack",
      167: "BrowserForward",
      168: "BrowserRefresh",
      169: "BrowserStop",
      170: "BrowserSearch",
      171: "BrowserFavorites",
      172: "BrowserHome",
      173: "AudioVolumeMute",
      174: "AudioVolumeDown",
      175: "AudioVolumeUp",
      176: "MediaTrackNext",
      177: "MediaTrackPrevious",
      178: "MediaStop",
      179: "MediaPlayPause",
      180: "LaunchMail",
      181: "MediaSelect",
      182: "LaunchApp1",
      183: "LaunchApp2",
      225: "AltRight"
    };
  })(Zo);
  var qo = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0, e.default = {
      Backspace: "Backspace",
      AltLeft: "Alt",
      AltRight: "Alt",
      CapsLock: "CapsLock",
      ContextMenu: "ContextMenu",
      ControlLeft: "Control",
      ControlRight: "Control",
      Enter: "Enter",
      MetaLeft: "Meta",
      MetaRight: "Meta",
      ShiftLeft: "Shift",
      ShiftRight: "Shift",
      Tab: "Tab",
      Delete: "Delete",
      End: "End",
      Help: "Help",
      Home: "Home",
      Insert: "Insert",
      PageDown: "PageDown",
      PageUp: "PageUp",
      ArrowDown: "ArrowDown",
      ArrowLeft: "ArrowLeft",
      ArrowRight: "ArrowRight",
      ArrowUp: "ArrowUp",
      NumLock: "NumLock",
      NumpadBackspace: "Backspace",
      NumpadClear: "Clear",
      Escape: "Escape",
      F1: "F1",
      F2: "F2",
      F3: "F3",
      F4: "F4",
      F5: "F5",
      F6: "F6",
      F7: "F7",
      F8: "F8",
      F9: "F9",
      F10: "F10",
      F11: "F11",
      F12: "F12",
      F13: "F13",
      F14: "F14",
      F15: "F15",
      F16: "F16",
      F17: "F17",
      F18: "F18",
      F19: "F19",
      F20: "F20",
      F21: "F21",
      F22: "F22",
      F23: "F23",
      F24: "F24",
      F25: "F25",
      F26: "F26",
      F27: "F27",
      F28: "F28",
      F29: "F29",
      F30: "F30",
      F31: "F31",
      F32: "F32",
      F33: "F33",
      F34: "F34",
      F35: "F35",
      PrintScreen: "PrintScreen",
      ScrollLock: "ScrollLock",
      Pause: "Pause",
      BrowserBack: "BrowserBack",
      BrowserFavorites: "BrowserFavorites",
      BrowserForward: "BrowserForward",
      BrowserHome: "BrowserHome",
      BrowserRefresh: "BrowserRefresh",
      BrowserSearch: "BrowserSearch",
      BrowserStop: "BrowserStop",
      Eject: "Eject",
      LaunchApp1: "LaunchMyComputer",
      LaunchApp2: "LaunchCalendar",
      LaunchMail: "LaunchMail",
      MediaPlayPause: "MediaPlay",
      MediaStop: "MediaStop",
      MediaTrackNext: "MediaTrackNext",
      MediaTrackPrevious: "MediaTrackPrevious",
      Power: "Power",
      Sleep: "Sleep",
      AudioVolumeDown: "AudioVolumeDown",
      AudioVolumeMute: "AudioVolumeMute",
      AudioVolumeUp: "AudioVolumeUp",
      WakeUp: "WakeUp"
    };
  })(qo);
  var Yo = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = n(Vr);
    function n(s) {
      return s && s.__esModule ? s : {
        default: s
      };
    }
    var r = {};
    function i(s, y) {
      if (y === void 0) throw new Error('Undefined keysym for key "' + s + '"');
      if (s in r) throw new Error('Duplicate entry for key "' + s + '"');
      r[s] = [
        y,
        y,
        y,
        y
      ];
    }
    function a(s, y, u) {
      if (y === void 0) throw new Error('Undefined keysym for key "' + s + '"');
      if (u === void 0) throw new Error('Undefined keysym for key "' + s + '"');
      if (s in r) throw new Error('Duplicate entry for key "' + s + '"');
      r[s] = [
        y,
        y,
        u,
        y
      ];
    }
    function o(s, y, u) {
      if (y === void 0) throw new Error('Undefined keysym for key "' + s + '"');
      if (u === void 0) throw new Error('Undefined keysym for key "' + s + '"');
      if (s in r) throw new Error('Duplicate entry for key "' + s + '"');
      r[s] = [
        y,
        y,
        y,
        u
      ];
    }
    a("Alt", t.default.XK_Alt_L, t.default.XK_Alt_R), i("AltGraph", t.default.XK_ISO_Level3_Shift), i("CapsLock", t.default.XK_Caps_Lock), a("Control", t.default.XK_Control_L, t.default.XK_Control_R), a("Meta", t.default.XK_Super_L, t.default.XK_Super_R), i("NumLock", t.default.XK_Num_Lock), i("ScrollLock", t.default.XK_Scroll_Lock), a("Shift", t.default.XK_Shift_L, t.default.XK_Shift_R), o("Enter", t.default.XK_Return, t.default.XK_KP_Enter), i("Tab", t.default.XK_Tab), o(" ", t.default.XK_space, t.default.XK_KP_Space), o("ArrowDown", t.default.XK_Down, t.default.XK_KP_Down), o("ArrowLeft", t.default.XK_Left, t.default.XK_KP_Left), o("ArrowRight", t.default.XK_Right, t.default.XK_KP_Right), o("ArrowUp", t.default.XK_Up, t.default.XK_KP_Up), o("End", t.default.XK_End, t.default.XK_KP_End), o("Home", t.default.XK_Home, t.default.XK_KP_Home), o("PageDown", t.default.XK_Next, t.default.XK_KP_Next), o("PageUp", t.default.XK_Prior, t.default.XK_KP_Prior), i("Backspace", t.default.XK_BackSpace), o("Clear", t.default.XK_Clear, t.default.XK_KP_Begin), i("Copy", t.default.XF86XK_Copy), i("Cut", t.default.XF86XK_Cut), o("Delete", t.default.XK_Delete, t.default.XK_KP_Delete), o("Insert", t.default.XK_Insert, t.default.XK_KP_Insert), i("Paste", t.default.XF86XK_Paste), i("Redo", t.default.XK_Redo), i("Undo", t.default.XK_Undo), i("Cancel", t.default.XK_Cancel), i("ContextMenu", t.default.XK_Menu), i("Escape", t.default.XK_Escape), i("Execute", t.default.XK_Execute), i("Find", t.default.XK_Find), i("Help", t.default.XK_Help), i("Pause", t.default.XK_Pause), i("Select", t.default.XK_Select), i("ZoomIn", t.default.XF86XK_ZoomIn), i("ZoomOut", t.default.XF86XK_ZoomOut), i("BrightnessDown", t.default.XF86XK_MonBrightnessDown), i("BrightnessUp", t.default.XF86XK_MonBrightnessUp), i("Eject", t.default.XF86XK_Eject), i("LogOff", t.default.XF86XK_LogOff), i("Power", t.default.XF86XK_PowerOff), i("PowerOff", t.default.XF86XK_PowerDown), i("PrintScreen", t.default.XK_Print), i("Hibernate", t.default.XF86XK_Hibernate), i("Standby", t.default.XF86XK_Standby), i("WakeUp", t.default.XF86XK_WakeUp), i("AllCandidates", t.default.XK_MultipleCandidate), i("Alphanumeric", t.default.XK_Eisu_toggle), i("CodeInput", t.default.XK_Codeinput), i("Compose", t.default.XK_Multi_key), i("Convert", t.default.XK_Henkan), i("GroupFirst", t.default.XK_ISO_First_Group), i("GroupLast", t.default.XK_ISO_Last_Group), i("GroupNext", t.default.XK_ISO_Next_Group), i("GroupPrevious", t.default.XK_ISO_Prev_Group), i("NonConvert", t.default.XK_Muhenkan), i("PreviousCandidate", t.default.XK_PreviousCandidate), i("SingleCandidate", t.default.XK_SingleCandidate), i("HangulMode", t.default.XK_Hangul), i("HanjaMode", t.default.XK_Hangul_Hanja), i("JunjaMode", t.default.XK_Hangul_Jeonja), i("Eisu", t.default.XK_Eisu_toggle), i("Hankaku", t.default.XK_Hankaku), i("Hiragana", t.default.XK_Hiragana), i("HiraganaKatakana", t.default.XK_Hiragana_Katakana), i("KanaMode", t.default.XK_Kana_Shift), i("KanjiMode", t.default.XK_Kanji), i("Katakana", t.default.XK_Katakana), i("Romaji", t.default.XK_Romaji), i("Zenkaku", t.default.XK_Zenkaku), i("ZenkakuHankaku", t.default.XK_Zenkaku_Hankaku), i("F1", t.default.XK_F1), i("F2", t.default.XK_F2), i("F3", t.default.XK_F3), i("F4", t.default.XK_F4), i("F5", t.default.XK_F5), i("F6", t.default.XK_F6), i("F7", t.default.XK_F7), i("F8", t.default.XK_F8), i("F9", t.default.XK_F9), i("F10", t.default.XK_F10), i("F11", t.default.XK_F11), i("F12", t.default.XK_F12), i("F13", t.default.XK_F13), i("F14", t.default.XK_F14), i("F15", t.default.XK_F15), i("F16", t.default.XK_F16), i("F17", t.default.XK_F17), i("F18", t.default.XK_F18), i("F19", t.default.XK_F19), i("F20", t.default.XK_F20), i("F21", t.default.XK_F21), i("F22", t.default.XK_F22), i("F23", t.default.XK_F23), i("F24", t.default.XK_F24), i("F25", t.default.XK_F25), i("F26", t.default.XK_F26), i("F27", t.default.XK_F27), i("F28", t.default.XK_F28), i("F29", t.default.XK_F29), i("F30", t.default.XK_F30), i("F31", t.default.XK_F31), i("F32", t.default.XK_F32), i("F33", t.default.XK_F33), i("F34", t.default.XK_F34), i("F35", t.default.XK_F35), i("Close", t.default.XF86XK_Close), i("MailForward", t.default.XF86XK_MailForward), i("MailReply", t.default.XF86XK_Reply), i("MailSend", t.default.XF86XK_Send), i("MediaFastForward", t.default.XF86XK_AudioForward), i("MediaPause", t.default.XF86XK_AudioPause), i("MediaPlay", t.default.XF86XK_AudioPlay), i("MediaRecord", t.default.XF86XK_AudioRecord), i("MediaRewind", t.default.XF86XK_AudioRewind), i("MediaStop", t.default.XF86XK_AudioStop), i("MediaTrackNext", t.default.XF86XK_AudioNext), i("MediaTrackPrevious", t.default.XF86XK_AudioPrev), i("New", t.default.XF86XK_New), i("Open", t.default.XF86XK_Open), i("Print", t.default.XK_Print), i("Save", t.default.XF86XK_Save), i("SpellCheck", t.default.XF86XK_Spell), i("AudioVolumeDown", t.default.XF86XK_AudioLowerVolume), i("AudioVolumeUp", t.default.XF86XK_AudioRaiseVolume), i("AudioVolumeMute", t.default.XF86XK_AudioMute), i("MicrophoneVolumeMute", t.default.XF86XK_AudioMicMute), i("LaunchApplication1", t.default.XF86XK_MyComputer), i("LaunchApplication2", t.default.XF86XK_Calculator), i("LaunchCalendar", t.default.XF86XK_Calendar), i("LaunchMail", t.default.XF86XK_Mail), i("LaunchMediaPlayer", t.default.XF86XK_AudioMedia), i("LaunchMusicPlayer", t.default.XF86XK_Music), i("LaunchPhone", t.default.XF86XK_Phone), i("LaunchScreenSaver", t.default.XF86XK_ScreenSaver), i("LaunchSpreadsheet", t.default.XF86XK_Excel), i("LaunchWebBrowser", t.default.XF86XK_WWW), i("LaunchWebCam", t.default.XF86XK_WebCam), i("LaunchWordProcessor", t.default.XF86XK_Word), i("BrowserBack", t.default.XF86XK_Back), i("BrowserFavorites", t.default.XF86XK_Favorites), i("BrowserForward", t.default.XF86XK_Forward), i("BrowserHome", t.default.XF86XK_HomePage), i("BrowserRefresh", t.default.XF86XK_Refresh), i("BrowserSearch", t.default.XF86XK_Search), i("BrowserStop", t.default.XF86XK_Stop), i("Dimmer", t.default.XF86XK_BrightnessAdjust), i("MediaAudioTrack", t.default.XF86XK_AudioCycleTrack), i("RandomToggle", t.default.XF86XK_AudioRandomPlay), i("SplitScreenToggle", t.default.XF86XK_SplitScreen), i("Subtitle", t.default.XF86XK_Subtitle), i("VideoModeNext", t.default.XF86XK_Next_VMode), o("=", t.default.XK_equal, t.default.XK_KP_Equal), o("+", t.default.XK_plus, t.default.XK_KP_Add), o("-", t.default.XK_minus, t.default.XK_KP_Subtract), o("*", t.default.XK_asterisk, t.default.XK_KP_Multiply), o("/", t.default.XK_slash, t.default.XK_KP_Divide), o(".", t.default.XK_period, t.default.XK_KP_Decimal), o(",", t.default.XK_comma, t.default.XK_KP_Separator), o("0", t.default.XK_0, t.default.XK_KP_0), o("1", t.default.XK_1, t.default.XK_KP_1), o("2", t.default.XK_2, t.default.XK_KP_2), o("3", t.default.XK_3, t.default.XK_KP_3), o("4", t.default.XK_4, t.default.XK_KP_4), o("5", t.default.XK_5, t.default.XK_KP_5), o("6", t.default.XK_6, t.default.XK_KP_6), o("7", t.default.XK_7, t.default.XK_KP_7), o("8", t.default.XK_8, t.default.XK_KP_8), o("9", t.default.XK_9, t.default.XK_KP_9), e.default = r;
  })(Yo);
  function ri(e) {
    "@babel/helpers - typeof";
    return ri = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, ri(e);
  }
  Object.defineProperty(Gr, "__esModule", {
    value: true
  });
  Gr.getKey = es;
  Gr.getKeycode = Tr;
  Gr.getKeysym = Tl;
  var Er = Zr(Vr), Al = Zr(Vo), ka = Zr(Zo), Sa = Zr(qo), Ea = Zr(Yo), $o = Pl(Ae);
  function Jo(e) {
    if (typeof WeakMap != "function") return null;
    var t = /* @__PURE__ */ new WeakMap(), n = /* @__PURE__ */ new WeakMap();
    return (Jo = function(i) {
      return i ? n : t;
    })(e);
  }
  function Pl(e, t) {
    if (e && e.__esModule) return e;
    if (e === null || ri(e) != "object" && typeof e != "function") return {
      default: e
    };
    var n = Jo(t);
    if (n && n.has(e)) return n.get(e);
    var r = {
      __proto__: null
    }, i = Object.defineProperty && Object.getOwnPropertyDescriptor;
    for (var a in e) if (a !== "default" && {}.hasOwnProperty.call(e, a)) {
      var o = i ? Object.getOwnPropertyDescriptor(e, a) : null;
      o && (o.get || o.set) ? Object.defineProperty(r, a, o) : r[a] = e[a];
    }
    return r.default = e, n && n.set(e, r), r;
  }
  function Zr(e) {
    return e && e.__esModule ? e : {
      default: e
    };
  }
  function Tr(e) {
    if (e.code) {
      switch (e.code) {
        case "OSLeft":
          return "MetaLeft";
        case "OSRight":
          return "MetaRight";
      }
      return e.code;
    }
    if (e.keyCode in ka.default) {
      var t = ka.default[e.keyCode];
      if ($o.isMac() && t === "ContextMenu" && (t = "MetaRight"), e.location === 2) switch (t) {
        case "ShiftLeft":
          return "ShiftRight";
        case "ControlLeft":
          return "ControlRight";
        case "AltLeft":
          return "AltRight";
      }
      if (e.location === 3) switch (t) {
        case "Delete":
          return "NumpadDecimal";
        case "Insert":
          return "Numpad0";
        case "End":
          return "Numpad1";
        case "ArrowDown":
          return "Numpad2";
        case "PageDown":
          return "Numpad3";
        case "ArrowLeft":
          return "Numpad4";
        case "ArrowRight":
          return "Numpad6";
        case "Home":
          return "Numpad7";
        case "ArrowUp":
          return "Numpad8";
        case "PageUp":
          return "Numpad9";
        case "Enter":
          return "NumpadEnter";
      }
      return t;
    }
    return "Unidentified";
  }
  function es(e) {
    if (e.key !== void 0 && e.key !== "Unidentified") {
      switch (e.key) {
        case "OS":
          return "Meta";
        case "LaunchMyComputer":
          return "LaunchApplication1";
        case "LaunchCalculator":
          return "LaunchApplication2";
      }
      switch (e.key) {
        case "UIKeyInputUpArrow":
          return "ArrowUp";
        case "UIKeyInputDownArrow":
          return "ArrowDown";
        case "UIKeyInputLeftArrow":
          return "ArrowLeft";
        case "UIKeyInputRightArrow":
          return "ArrowRight";
        case "UIKeyInputEscape":
          return "Escape";
      }
      return e.key === "\0" && e.code === "NumpadDecimal" ? "Delete" : e.key;
    }
    var t = Tr(e);
    return t in Sa.default ? Sa.default[t] : e.charCode ? String.fromCharCode(e.charCode) : "Unidentified";
  }
  function Tl(e) {
    var t = es(e);
    if (t === "Unidentified") return null;
    if (t in Ea.default) {
      var n = e.location;
      if (t === "Meta" && n === 0 && (n = 2), t === "Clear" && n === 3) {
        var r = Tr(e);
        r === "NumLock" && (n = 0);
      }
      if ((n === void 0 || n > 3) && (n = 0), t === "Meta") {
        var i = Tr(e);
        if (i === "AltLeft") return Er.default.XK_Meta_L;
        if (i === "AltRight") return Er.default.XK_Meta_R;
      }
      if (t === "Clear") {
        var a = Tr(e);
        if (a === "NumLock") return Er.default.XK_Num_Lock;
      }
      if ($o.isWindows()) switch (t) {
        case "Zenkaku":
        case "Hankaku":
          return Er.default.XK_Zenkaku_Hankaku;
        case "Romaji":
        case "KanaMode":
          return Er.default.XK_Romaji;
      }
      return Ea.default[t][n];
    }
    if (t.length !== 1) return null;
    var o = t.charCodeAt();
    return o ? Al.default.lookup(o) : null;
  }
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = y(Re), n = ar, r = y(Gr), i = o(Vr), a = y(Ae);
    function o(d) {
      return d && d.__esModule ? d : {
        default: d
      };
    }
    function s(d) {
      if (typeof WeakMap != "function") return null;
      var f = /* @__PURE__ */ new WeakMap(), c = /* @__PURE__ */ new WeakMap();
      return (s = function(K) {
        return K ? c : f;
      })(d);
    }
    function y(d, f) {
      if (d && d.__esModule) return d;
      if (d === null || u(d) != "object" && typeof d != "function") return {
        default: d
      };
      var c = s(f);
      if (c && c.has(d)) return c.get(d);
      var h = {
        __proto__: null
      }, K = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var x in d) if (x !== "default" && {}.hasOwnProperty.call(d, x)) {
        var F = K ? Object.getOwnPropertyDescriptor(d, x) : null;
        F && (F.get || F.set) ? Object.defineProperty(h, x, F) : h[x] = d[x];
      }
      return h.default = d, c && c.set(d, h), h;
    }
    function u(d) {
      "@babel/helpers - typeof";
      return u = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(f) {
        return typeof f;
      } : function(f) {
        return f && typeof Symbol == "function" && f.constructor === Symbol && f !== Symbol.prototype ? "symbol" : typeof f;
      }, u(d);
    }
    function l(d, f) {
      if (!(d instanceof f)) throw new TypeError("Cannot call a class as a function");
    }
    function k(d, f) {
      for (var c = 0; c < f.length; c++) {
        var h = f[c];
        h.enumerable = h.enumerable || false, h.configurable = true, "value" in h && (h.writable = true), Object.defineProperty(d, g(h.key), h);
      }
    }
    function X(d, f, c) {
      return f && k(d.prototype, f), Object.defineProperty(d, "prototype", {
        writable: false
      }), d;
    }
    function g(d) {
      var f = b(d, "string");
      return u(f) == "symbol" ? f : f + "";
    }
    function b(d, f) {
      if (u(d) != "object" || !d) return d;
      var c = d[Symbol.toPrimitive];
      if (c !== void 0) {
        var h = c.call(d, f);
        if (u(h) != "object") return h;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(d);
    }
    e.default = function() {
      function d(f) {
        l(this, d), this._target = f || null, this._keyDownList = {}, this._altGrArmed = false, this._eventHandlers = {
          keyup: this._handleKeyUp.bind(this),
          keydown: this._handleKeyDown.bind(this),
          blur: this._allKeysUp.bind(this)
        }, this.onkeyevent = function() {
        };
      }
      return X(d, [
        {
          key: "_sendKeyEvent",
          value: function(c, h, K) {
            var x = arguments.length > 3 && arguments[3] !== void 0 ? arguments[3] : null, F = arguments.length > 4 && arguments[4] !== void 0 ? arguments[4] : null;
            if (K) this._keyDownList[h] = c;
            else {
              if (!(h in this._keyDownList)) return;
              delete this._keyDownList[h];
            }
            t.Debug("onkeyevent " + (K ? "down" : "up") + ", keysym: " + c, ", code: " + h + ", numlock: " + x + ", capslock: " + F), this.onkeyevent(c, h, K, x, F);
          }
        },
        {
          key: "_getKeyCode",
          value: function(c) {
            var h = r.getKeycode(c);
            if (h !== "Unidentified") return h;
            if (c.keyCode && c.keyCode !== 229) return "Platform" + c.keyCode;
            if (c.keyIdentifier) {
              if (c.keyIdentifier.substr(0, 2) !== "U+") return c.keyIdentifier;
              var K = parseInt(c.keyIdentifier.substr(2), 16), x = String.fromCharCode(K).toUpperCase();
              return "Platform" + x.charCodeAt();
            }
            return "Unidentified";
          }
        },
        {
          key: "_handleKeyDown",
          value: function(c) {
            var h = this._getKeyCode(c), K = r.getKeysym(c), x = c.getModifierState("NumLock"), F = c.getModifierState("CapsLock");
            if ((a.isMac() || a.isIOS()) && (x = null), this._altGrArmed && (this._altGrArmed = false, clearTimeout(this._altGrTimeout), h === "AltRight" && c.timeStamp - this._altGrCtrlTime < 50 ? K = i.default.XK_ISO_Level3_Shift : this._sendKeyEvent(i.default.XK_Control_L, "ControlLeft", true, x, F)), h === "Unidentified") {
              K && (this._sendKeyEvent(K, h, true, x, F), this._sendKeyEvent(K, h, false, x, F)), (0, n.stopEvent)(c);
              return;
            }
            if (a.isMac() || a.isIOS()) switch (K) {
              case i.default.XK_Super_L:
                K = i.default.XK_Alt_L;
                break;
              case i.default.XK_Super_R:
                K = i.default.XK_Super_L;
                break;
              case i.default.XK_Alt_L:
                K = i.default.XK_Mode_switch;
                break;
              case i.default.XK_Alt_R:
                K = i.default.XK_ISO_Level3_Shift;
                break;
            }
            if (h in this._keyDownList && (K = this._keyDownList[h]), (a.isMac() || a.isIOS()) && c.metaKey && h !== "MetaLeft" && h !== "MetaRight") {
              this._sendKeyEvent(K, h, true, x, F), this._sendKeyEvent(K, h, false, x, F), (0, n.stopEvent)(c);
              return;
            }
            if ((a.isMac() || a.isIOS()) && h === "CapsLock") {
              this._sendKeyEvent(i.default.XK_Caps_Lock, "CapsLock", true, x, F), this._sendKeyEvent(i.default.XK_Caps_Lock, "CapsLock", false, x, F), (0, n.stopEvent)(c);
              return;
            }
            var S = [
              i.default.XK_Zenkaku_Hankaku,
              i.default.XK_Eisu_toggle,
              i.default.XK_Katakana,
              i.default.XK_Hiragana,
              i.default.XK_Romaji
            ];
            if (a.isWindows() && S.includes(K)) {
              this._sendKeyEvent(K, h, true, x, F), this._sendKeyEvent(K, h, false, x, F), (0, n.stopEvent)(c);
              return;
            }
            if ((0, n.stopEvent)(c), h === "ControlLeft" && a.isWindows() && !("ControlLeft" in this._keyDownList)) {
              this._altGrArmed = true, this._altGrTimeout = setTimeout(this._interruptAltGrSequence.bind(this), 100), this._altGrCtrlTime = c.timeStamp;
              return;
            }
            this._sendKeyEvent(K, h, true, x, F);
          }
        },
        {
          key: "_handleKeyUp",
          value: function(c) {
            (0, n.stopEvent)(c);
            var h = this._getKeyCode(c);
            if (this._interruptAltGrSequence(), (a.isMac() || a.isIOS()) && h === "CapsLock") {
              this._sendKeyEvent(i.default.XK_Caps_Lock, "CapsLock", true), this._sendKeyEvent(i.default.XK_Caps_Lock, "CapsLock", false);
              return;
            }
            this._sendKeyEvent(this._keyDownList[h], h, false), a.isWindows() && (h === "ShiftLeft" || h === "ShiftRight") && ("ShiftRight" in this._keyDownList && this._sendKeyEvent(this._keyDownList.ShiftRight, "ShiftRight", false), "ShiftLeft" in this._keyDownList && this._sendKeyEvent(this._keyDownList.ShiftLeft, "ShiftLeft", false));
          }
        },
        {
          key: "_interruptAltGrSequence",
          value: function() {
            this._altGrArmed && (this._altGrArmed = false, clearTimeout(this._altGrTimeout), this._sendKeyEvent(i.default.XK_Control_L, "ControlLeft", true));
          }
        },
        {
          key: "_allKeysUp",
          value: function() {
            t.Debug(">> Keyboard.allKeysUp"), this._interruptAltGrSequence();
            for (var c in this._keyDownList) this._sendKeyEvent(this._keyDownList[c], c, false);
            t.Debug("<< Keyboard.allKeysUp");
          }
        },
        {
          key: "grab",
          value: function() {
            this._target.addEventListener("keydown", this._eventHandlers.keydown), this._target.addEventListener("keyup", this._eventHandlers.keyup), window.addEventListener("blur", this._eventHandlers.blur);
          }
        },
        {
          key: "ungrab",
          value: function() {
            this._target.removeEventListener("keydown", this._eventHandlers.keydown), this._target.removeEventListener("keyup", this._eventHandlers.keyup), window.removeEventListener("blur", this._eventHandlers.blur), this._allKeysUp();
          }
        }
      ]);
    }();
  })(Go);
  var ts = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(S) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(w) {
        return typeof w;
      } : function(w) {
        return w && typeof Symbol == "function" && w.constructor === Symbol && w !== Symbol.prototype ? "symbol" : typeof w;
      }, t(S);
    }
    function n(S, w) {
      if (!(S instanceof w)) throw new TypeError("Cannot call a class as a function");
    }
    function r(S, w) {
      for (var C = 0; C < w.length; C++) {
        var A = w[C];
        A.enumerable = A.enumerable || false, A.configurable = true, "value" in A && (A.writable = true), Object.defineProperty(S, a(A.key), A);
      }
    }
    function i(S, w, C) {
      return w && r(S.prototype, w), Object.defineProperty(S, "prototype", {
        writable: false
      }), S;
    }
    function a(S) {
      var w = o(S, "string");
      return t(w) == "symbol" ? w : w + "";
    }
    function o(S, w) {
      if (t(S) != "object" || !S) return S;
      var C = S[Symbol.toPrimitive];
      if (C !== void 0) {
        var A = C.call(S, w);
        if (t(A) != "object") return A;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(S);
    }
    var s = 0, y = 1, u = 2, l = 4, k = 8, X = 16, g = 32, b = 64, d = 127, f = 50, c = 90, h = 250, K = 1e3, x = 1e3, F = 50;
    e.default = function() {
      function S() {
        n(this, S), this._target = null, this._state = d, this._tracked = [], this._ignored = [], this._waitingRelease = false, this._releaseStart = 0, this._longpressTimeoutId = null, this._twoTouchTimeoutId = null, this._boundEventHandler = this._eventHandler.bind(this);
      }
      return i(S, [
        {
          key: "attach",
          value: function(C) {
            this.detach(), this._target = C, this._target.addEventListener("touchstart", this._boundEventHandler), this._target.addEventListener("touchmove", this._boundEventHandler), this._target.addEventListener("touchend", this._boundEventHandler), this._target.addEventListener("touchcancel", this._boundEventHandler);
          }
        },
        {
          key: "detach",
          value: function() {
            this._target && (this._stopLongpressTimeout(), this._stopTwoTouchTimeout(), this._target.removeEventListener("touchstart", this._boundEventHandler), this._target.removeEventListener("touchmove", this._boundEventHandler), this._target.removeEventListener("touchend", this._boundEventHandler), this._target.removeEventListener("touchcancel", this._boundEventHandler), this._target = null);
          }
        },
        {
          key: "_eventHandler",
          value: function(C) {
            var A;
            switch (C.stopPropagation(), C.preventDefault(), C.type) {
              case "touchstart":
                A = this._touchStart;
                break;
              case "touchmove":
                A = this._touchMove;
                break;
              case "touchend":
              case "touchcancel":
                A = this._touchEnd;
                break;
            }
            for (var O = 0; O < C.changedTouches.length; O++) {
              var I = C.changedTouches[O];
              A.call(this, I.identifier, I.clientX, I.clientY);
            }
          }
        },
        {
          key: "_touchStart",
          value: function(C, A, O) {
            if (this._hasDetectedGesture() || this._state === s) {
              this._ignored.push(C);
              return;
            }
            if (this._tracked.length > 0 && Date.now() - this._tracked[0].started > h) {
              this._state = s, this._ignored.push(C);
              return;
            }
            if (this._waitingRelease) {
              this._state = s, this._ignored.push(C);
              return;
            }
            switch (this._tracked.push({
              id: C,
              started: Date.now(),
              active: true,
              firstX: A,
              firstY: O,
              lastX: A,
              lastY: O,
              angle: 0
            }), this._tracked.length) {
              case 1:
                this._startLongpressTimeout();
                break;
              case 2:
                this._state &= -26, this._stopLongpressTimeout();
                break;
              case 3:
                this._state &= -99;
                break;
              default:
                this._state = s;
            }
          }
        },
        {
          key: "_touchMove",
          value: function(C, A, O) {
            var I = this._tracked.find(function(p) {
              return p.id === C;
            });
            if (I !== void 0) {
              I.lastX = A, I.lastY = O;
              var Z = A - I.firstX, q = O - I.firstY;
              if ((I.firstX !== I.lastX || I.firstY !== I.lastY) && (I.angle = Math.atan2(q, Z) * 180 / Math.PI), !this._hasDetectedGesture()) {
                if (Math.hypot(Z, q) < f) return;
                if (this._state &= -24, this._stopLongpressTimeout(), this._tracked.length !== 1 && (this._state &= ~k), this._tracked.length !== 2 && (this._state &= -97), this._tracked.length === 2) {
                  var $ = this._tracked.find(function(p) {
                    return p.id !== C;
                  }), ne = Math.hypot($.firstX - $.lastX, $.firstY - $.lastY);
                  if (ne > f) {
                    var E = Math.abs(I.angle - $.angle);
                    E = Math.abs((E + 180) % 360 - 180), E > c ? this._state &= ~g : this._state &= ~b, this._isTwoTouchTimeoutRunning() && this._stopTwoTouchTimeout();
                  } else this._isTwoTouchTimeoutRunning() || this._startTwoTouchTimeout();
                }
                if (!this._hasDetectedGesture()) return;
                this._pushEvent("gesturestart");
              }
              this._pushEvent("gesturemove");
            }
          }
        },
        {
          key: "_touchEnd",
          value: function(C, A, O) {
            if (this._ignored.indexOf(C) !== -1) {
              this._ignored.splice(this._ignored.indexOf(C), 1), this._ignored.length === 0 && this._tracked.length === 0 && (this._state = d, this._waitingRelease = false);
              return;
            }
            if (!this._hasDetectedGesture() && this._isTwoTouchTimeoutRunning() && (this._stopTwoTouchTimeout(), this._state = s), !this._hasDetectedGesture() && (this._state &= -105, this._state &= ~X, this._stopLongpressTimeout(), !this._waitingRelease)) switch (this._releaseStart = Date.now(), this._waitingRelease = true, this._tracked.length) {
              case 1:
                this._state &= -7;
                break;
              case 2:
                this._state &= -6;
                break;
            }
            if (this._waitingRelease) {
              Date.now() - this._releaseStart > h && (this._state = s), this._tracked.some(function(q) {
                return Date.now() - q.started > K;
              }) && (this._state = s);
              var I = this._tracked.find(function(q) {
                return q.id === C;
              });
              if (I.active = false, this._hasDetectedGesture()) this._pushEvent("gesturestart");
              else if (this._state !== s) return;
            }
            this._hasDetectedGesture() && this._pushEvent("gestureend");
            for (var Z = 0; Z < this._tracked.length; Z++) this._tracked[Z].active && this._ignored.push(this._tracked[Z].id);
            this._tracked = [], this._state = s, this._ignored.indexOf(C) !== -1 && this._ignored.splice(this._ignored.indexOf(C), 1), this._ignored.length === 0 && (this._state = d, this._waitingRelease = false);
          }
        },
        {
          key: "_hasDetectedGesture",
          value: function() {
            return !(this._state === s || this._state & this._state - 1 || this._state & (y | u | l) && this._tracked.some(function(C) {
              return C.active;
            }));
          }
        },
        {
          key: "_startLongpressTimeout",
          value: function() {
            var C = this;
            this._stopLongpressTimeout(), this._longpressTimeoutId = setTimeout(function() {
              return C._longpressTimeout();
            }, x);
          }
        },
        {
          key: "_stopLongpressTimeout",
          value: function() {
            clearTimeout(this._longpressTimeoutId), this._longpressTimeoutId = null;
          }
        },
        {
          key: "_longpressTimeout",
          value: function() {
            if (this._hasDetectedGesture()) throw new Error("A longpress gesture failed, conflict with a different gesture");
            this._state = X, this._pushEvent("gesturestart");
          }
        },
        {
          key: "_startTwoTouchTimeout",
          value: function() {
            var C = this;
            this._stopTwoTouchTimeout(), this._twoTouchTimeoutId = setTimeout(function() {
              return C._twoTouchTimeout();
            }, F);
          }
        },
        {
          key: "_stopTwoTouchTimeout",
          value: function() {
            clearTimeout(this._twoTouchTimeoutId), this._twoTouchTimeoutId = null;
          }
        },
        {
          key: "_isTwoTouchTimeoutRunning",
          value: function() {
            return this._twoTouchTimeoutId !== null;
          }
        },
        {
          key: "_twoTouchTimeout",
          value: function() {
            if (this._tracked.length === 0) throw new Error("A pinch or two drag gesture failed, no tracked touches");
            var C = this._getAverageMovement(), A = Math.abs(C.x), O = Math.abs(C.y), I = this._getAverageDistance(), Z = Math.abs(Math.hypot(I.first.x, I.first.y) - Math.hypot(I.last.x, I.last.y));
            O < Z && A < Z ? this._state = b : this._state = g, this._pushEvent("gesturestart"), this._pushEvent("gesturemove");
          }
        },
        {
          key: "_pushEvent",
          value: function(C) {
            var A = {
              type: this._stateToGesture(this._state)
            }, O = this._getPosition(), I = O.last;
            switch (C === "gesturestart" && (I = O.first), this._state) {
              case g:
              case b:
                I = O.first;
                break;
            }
            if (A.clientX = I.x, A.clientY = I.y, this._state === b) {
              var Z = this._getAverageDistance();
              C === "gesturestart" ? (A.magnitudeX = Z.first.x, A.magnitudeY = Z.first.y) : (A.magnitudeX = Z.last.x, A.magnitudeY = Z.last.y);
            } else if (this._state === g) if (C === "gesturestart") A.magnitudeX = 0, A.magnitudeY = 0;
            else {
              var q = this._getAverageMovement();
              A.magnitudeX = q.x, A.magnitudeY = q.y;
            }
            var $ = new CustomEvent(C, {
              detail: A
            });
            this._target.dispatchEvent($);
          }
        },
        {
          key: "_stateToGesture",
          value: function(C) {
            switch (C) {
              case y:
                return "onetap";
              case u:
                return "twotap";
              case l:
                return "threetap";
              case k:
                return "drag";
              case X:
                return "longpress";
              case g:
                return "twodrag";
              case b:
                return "pinch";
            }
            throw new Error("Unknown gesture state: " + C);
          }
        },
        {
          key: "_getPosition",
          value: function() {
            if (this._tracked.length === 0) throw new Error("Failed to get gesture position, no tracked touches");
            for (var C = this._tracked.length, A = 0, O = 0, I = 0, Z = 0, q = 0; q < this._tracked.length; q++) A += this._tracked[q].firstX, O += this._tracked[q].firstY, I += this._tracked[q].lastX, Z += this._tracked[q].lastY;
            return {
              first: {
                x: A / C,
                y: O / C
              },
              last: {
                x: I / C,
                y: Z / C
              }
            };
          }
        },
        {
          key: "_getAverageMovement",
          value: function() {
            if (this._tracked.length === 0) throw new Error("Failed to get gesture movement, no tracked touches");
            var C, A;
            C = A = 0;
            for (var O = this._tracked.length, I = 0; I < this._tracked.length; I++) C += this._tracked[I].lastX - this._tracked[I].firstX, A += this._tracked[I].lastY - this._tracked[I].firstY;
            return {
              x: C / O,
              y: A / O
            };
          }
        },
        {
          key: "_getAverageDistance",
          value: function() {
            if (this._tracked.length === 0) throw new Error("Failed to get gesture distance, no tracked touches");
            var C = this._tracked[0], A = this._tracked[this._tracked.length - 1], O = Math.abs(A.firstX - C.firstX), I = Math.abs(A.firstY - C.firstY), Z = Math.abs(A.lastX - C.lastX), q = Math.abs(A.lastY - C.lastY);
            return {
              first: {
                x: O,
                y: I
              },
              last: {
                x: Z,
                y: q
              }
            };
          }
        }
      ]);
    }();
  })(ts);
  var rs = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = Ae;
    function n(u) {
      "@babel/helpers - typeof";
      return n = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(l) {
        return typeof l;
      } : function(l) {
        return l && typeof Symbol == "function" && l.constructor === Symbol && l !== Symbol.prototype ? "symbol" : typeof l;
      }, n(u);
    }
    function r(u, l) {
      if (!(u instanceof l)) throw new TypeError("Cannot call a class as a function");
    }
    function i(u, l) {
      for (var k = 0; k < l.length; k++) {
        var X = l[k];
        X.enumerable = X.enumerable || false, X.configurable = true, "value" in X && (X.writable = true), Object.defineProperty(u, o(X.key), X);
      }
    }
    function a(u, l, k) {
      return l && i(u.prototype, l), Object.defineProperty(u, "prototype", {
        writable: false
      }), u;
    }
    function o(u) {
      var l = s(u, "string");
      return n(l) == "symbol" ? l : l + "";
    }
    function s(u, l) {
      if (n(u) != "object" || !u) return u;
      var k = u[Symbol.toPrimitive];
      if (k !== void 0) {
        var X = k.call(u, l);
        if (n(X) != "object") return X;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(u);
    }
    var y = !t.supportsCursorURIs || t.isTouchDevice;
    e.default = function() {
      function u() {
        r(this, u), this._target = null, this._canvas = document.createElement("canvas"), y && (this._canvas.style.position = "fixed", this._canvas.style.zIndex = "65535", this._canvas.style.pointerEvents = "none", this._canvas.style.userSelect = "none", this._canvas.style.WebkitUserSelect = "none", this._canvas.style.visibility = "hidden"), this._position = {
          x: 0,
          y: 0
        }, this._hotSpot = {
          x: 0,
          y: 0
        }, this._eventHandlers = {
          mouseover: this._handleMouseOver.bind(this),
          mouseleave: this._handleMouseLeave.bind(this),
          mousemove: this._handleMouseMove.bind(this),
          mouseup: this._handleMouseUp.bind(this)
        };
      }
      return a(u, [
        {
          key: "attach",
          value: function(k) {
            if (this._target && this.detach(), this._target = k, y) {
              document.body.appendChild(this._canvas);
              var X = {
                capture: true,
                passive: true
              };
              this._target.addEventListener("mouseover", this._eventHandlers.mouseover, X), this._target.addEventListener("mouseleave", this._eventHandlers.mouseleave, X), this._target.addEventListener("mousemove", this._eventHandlers.mousemove, X), this._target.addEventListener("mouseup", this._eventHandlers.mouseup, X);
            }
            this.clear();
          }
        },
        {
          key: "detach",
          value: function() {
            if (this._target) {
              if (y) {
                var k = {
                  capture: true,
                  passive: true
                };
                this._target.removeEventListener("mouseover", this._eventHandlers.mouseover, k), this._target.removeEventListener("mouseleave", this._eventHandlers.mouseleave, k), this._target.removeEventListener("mousemove", this._eventHandlers.mousemove, k), this._target.removeEventListener("mouseup", this._eventHandlers.mouseup, k), document.contains(this._canvas) && document.body.removeChild(this._canvas);
              }
              this._target = null;
            }
          }
        },
        {
          key: "change",
          value: function(k, X, g, b, d) {
            if (b === 0 || d === 0) {
              this.clear();
              return;
            }
            this._position.x = this._position.x + this._hotSpot.x - X, this._position.y = this._position.y + this._hotSpot.y - g, this._hotSpot.x = X, this._hotSpot.y = g;
            var f = this._canvas.getContext("2d");
            this._canvas.width = b, this._canvas.height = d;
            var c = new ImageData(new Uint8ClampedArray(k), b, d);
            if (f.clearRect(0, 0, b, d), f.putImageData(c, 0, 0), y) this._updatePosition();
            else {
              var h = this._canvas.toDataURL();
              this._target.style.cursor = "url(" + h + ")" + X + " " + g + ", default";
            }
          }
        },
        {
          key: "clear",
          value: function() {
            this._target.style.cursor = "none", this._canvas.width = 0, this._canvas.height = 0, this._position.x = this._position.x + this._hotSpot.x, this._position.y = this._position.y + this._hotSpot.y, this._hotSpot.x = 0, this._hotSpot.y = 0;
          }
        },
        {
          key: "move",
          value: function(k, X) {
            if (y) {
              window.visualViewport ? (this._position.x = k + window.visualViewport.offsetLeft, this._position.y = X + window.visualViewport.offsetTop) : (this._position.x = k, this._position.y = X), this._updatePosition();
              var g = document.elementFromPoint(k, X);
              this._updateVisibility(g);
            }
          }
        },
        {
          key: "_handleMouseOver",
          value: function(k) {
            this._handleMouseMove(k);
          }
        },
        {
          key: "_handleMouseLeave",
          value: function(k) {
            this._updateVisibility(k.relatedTarget);
          }
        },
        {
          key: "_handleMouseMove",
          value: function(k) {
            this._updateVisibility(k.target), this._position.x = k.clientX - this._hotSpot.x, this._position.y = k.clientY - this._hotSpot.y, this._updatePosition();
          }
        },
        {
          key: "_handleMouseUp",
          value: function(k) {
            var X = this, g = document.elementFromPoint(k.clientX, k.clientY);
            this._updateVisibility(g), this._captureIsActive() && window.setTimeout(function() {
              X._target && (g = document.elementFromPoint(k.clientX, k.clientY), X._updateVisibility(g));
            }, 0);
          }
        },
        {
          key: "_showCursor",
          value: function() {
            this._canvas.style.visibility === "hidden" && (this._canvas.style.visibility = "");
          }
        },
        {
          key: "_hideCursor",
          value: function() {
            this._canvas.style.visibility !== "hidden" && (this._canvas.style.visibility = "hidden");
          }
        },
        {
          key: "_shouldShowCursor",
          value: function(k) {
            return k ? k === this._target ? true : !(!this._target.contains(k) || window.getComputedStyle(k).cursor !== "none") : false;
          }
        },
        {
          key: "_updateVisibility",
          value: function(k) {
            this._captureIsActive() && (k = document.captureElement), this._shouldShowCursor(k) ? this._showCursor() : this._hideCursor();
          }
        },
        {
          key: "_updatePosition",
          value: function() {
            this._canvas.style.left = this._position.x + "px", this._canvas.style.top = this._position.y + "px";
          }
        },
        {
          key: "_captureIsActive",
          value: function() {
            return document.captureElement && document.documentElement.contains(document.captureElement);
          }
        }
      ]);
    }();
  })(rs);
  var ns = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = r(Re);
    function n(x) {
      if (typeof WeakMap != "function") return null;
      var F = /* @__PURE__ */ new WeakMap(), S = /* @__PURE__ */ new WeakMap();
      return (n = function(C) {
        return C ? S : F;
      })(x);
    }
    function r(x, F) {
      if (x && x.__esModule) return x;
      if (x === null || i(x) != "object" && typeof x != "function") return {
        default: x
      };
      var S = n(F);
      if (S && S.has(x)) return S.get(x);
      var w = {
        __proto__: null
      }, C = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var A in x) if (A !== "default" && {}.hasOwnProperty.call(x, A)) {
        var O = C ? Object.getOwnPropertyDescriptor(x, A) : null;
        O && (O.get || O.set) ? Object.defineProperty(w, A, O) : w[A] = x[A];
      }
      return w.default = x, S && S.set(x, w), w;
    }
    function i(x) {
      "@babel/helpers - typeof";
      return i = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(F) {
        return typeof F;
      } : function(F) {
        return F && typeof Symbol == "function" && F.constructor === Symbol && F !== Symbol.prototype ? "symbol" : typeof F;
      }, i(x);
    }
    function a(x) {
      return u(x) || y(x) || s(x) || o();
    }
    function o() {
      throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
    }
    function s(x, F) {
      if (x) {
        if (typeof x == "string") return l(x, F);
        var S = {}.toString.call(x).slice(8, -1);
        return S === "Object" && x.constructor && (S = x.constructor.name), S === "Map" || S === "Set" ? Array.from(x) : S === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(S) ? l(x, F) : void 0;
      }
    }
    function y(x) {
      if (typeof Symbol < "u" && x[Symbol.iterator] != null || x["@@iterator"] != null) return Array.from(x);
    }
    function u(x) {
      if (Array.isArray(x)) return l(x);
    }
    function l(x, F) {
      (F == null || F > x.length) && (F = x.length);
      for (var S = 0, w = Array(F); S < F; S++) w[S] = x[S];
      return w;
    }
    function k(x, F) {
      if (!(x instanceof F)) throw new TypeError("Cannot call a class as a function");
    }
    function X(x, F) {
      for (var S = 0; S < F.length; S++) {
        var w = F[S];
        w.enumerable = w.enumerable || false, w.configurable = true, "value" in w && (w.writable = true), Object.defineProperty(x, b(w.key), w);
      }
    }
    function g(x, F, S) {
      return F && X(x.prototype, F), Object.defineProperty(x, "prototype", {
        writable: false
      }), x;
    }
    function b(x) {
      var F = d(x, "string");
      return i(F) == "symbol" ? F : F + "";
    }
    function d(x, F) {
      if (i(x) != "object" || !x) return x;
      var S = x[Symbol.toPrimitive];
      if (S !== void 0) {
        var w = S.call(x, F);
        if (i(w) != "object") return w;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(x);
    }
    var f = 40 * 1024 * 1024, c = {
      CONNECTING: "connecting",
      OPEN: "open",
      CLOSING: "closing",
      CLOSED: "closed"
    }, h = {
      CONNECTING: [
        WebSocket.CONNECTING,
        c.CONNECTING
      ],
      OPEN: [
        WebSocket.OPEN,
        c.OPEN
      ],
      CLOSING: [
        WebSocket.CLOSING,
        c.CLOSING
      ],
      CLOSED: [
        WebSocket.CLOSED,
        c.CLOSED
      ]
    }, K = [
      "send",
      "close",
      "binaryType",
      "onerror",
      "onmessage",
      "onopen",
      "protocol",
      "readyState"
    ];
    e.default = function() {
      function x() {
        k(this, x), this._websocket = null, this._rQi = 0, this._rQlen = 0, this._rQbufferSize = 1024 * 1024 * 4, this._rQ = null, this._sQbufferSize = 1024 * 10, this._sQlen = 0, this._sQ = null, this._eventHandlers = {
          message: function() {
          },
          open: function() {
          },
          close: function() {
          },
          error: function() {
          }
        };
      }
      return g(x, [
        {
          key: "readyState",
          get: function() {
            var S;
            return this._websocket === null ? "unused" : (S = this._websocket.readyState, h.CONNECTING.includes(S) ? "connecting" : h.OPEN.includes(S) ? "open" : h.CLOSING.includes(S) ? "closing" : h.CLOSED.includes(S) ? "closed" : "unknown");
          }
        },
        {
          key: "rQpeek8",
          value: function() {
            return this._rQ[this._rQi];
          }
        },
        {
          key: "rQskipBytes",
          value: function(S) {
            this._rQi += S;
          }
        },
        {
          key: "rQshift8",
          value: function() {
            return this._rQshift(1);
          }
        },
        {
          key: "rQshift16",
          value: function() {
            return this._rQshift(2);
          }
        },
        {
          key: "rQshift32",
          value: function() {
            return this._rQshift(4);
          }
        },
        {
          key: "_rQshift",
          value: function(S) {
            for (var w = 0, C = S - 1; C >= 0; C--) w += this._rQ[this._rQi++] << C * 8;
            return w >>> 0;
          }
        },
        {
          key: "rQshiftStr",
          value: function(S) {
            for (var w = "", C = 0; C < S; C += 4096) {
              var A = this.rQshiftBytes(Math.min(4096, S - C), false);
              w += String.fromCharCode.apply(null, A);
            }
            return w;
          }
        },
        {
          key: "rQshiftBytes",
          value: function(S) {
            var w = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : true;
            return this._rQi += S, w ? this._rQ.slice(this._rQi - S, this._rQi) : this._rQ.subarray(this._rQi - S, this._rQi);
          }
        },
        {
          key: "rQshiftTo",
          value: function(S, w) {
            S.set(new Uint8Array(this._rQ.buffer, this._rQi, w)), this._rQi += w;
          }
        },
        {
          key: "rQpeekBytes",
          value: function(S) {
            var w = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : true;
            return w ? this._rQ.slice(this._rQi, this._rQi + S) : this._rQ.subarray(this._rQi, this._rQi + S);
          }
        },
        {
          key: "rQwait",
          value: function(S, w, C) {
            if (this._rQlen - this._rQi < w) {
              if (C) {
                if (this._rQi < C) throw new Error("rQwait cannot backup " + C + " bytes");
                this._rQi -= C;
              }
              return true;
            }
            return false;
          }
        },
        {
          key: "sQpush8",
          value: function(S) {
            this._sQensureSpace(1), this._sQ[this._sQlen++] = S;
          }
        },
        {
          key: "sQpush16",
          value: function(S) {
            this._sQensureSpace(2), this._sQ[this._sQlen++] = S >> 8 & 255, this._sQ[this._sQlen++] = S >> 0 & 255;
          }
        },
        {
          key: "sQpush32",
          value: function(S) {
            this._sQensureSpace(4), this._sQ[this._sQlen++] = S >> 24 & 255, this._sQ[this._sQlen++] = S >> 16 & 255, this._sQ[this._sQlen++] = S >> 8 & 255, this._sQ[this._sQlen++] = S >> 0 & 255;
          }
        },
        {
          key: "sQpushString",
          value: function(S) {
            var w = S.split("").map(function(C) {
              return C.charCodeAt(0);
            });
            this.sQpushBytes(new Uint8Array(w));
          }
        },
        {
          key: "sQpushBytes",
          value: function(S) {
            for (var w = 0; w < S.length; ) {
              this._sQensureSpace(1);
              var C = this._sQbufferSize - this._sQlen;
              C > S.length - w && (C = S.length - w), this._sQ.set(S.subarray(w, w + C), this._sQlen), this._sQlen += C, w += C;
            }
          }
        },
        {
          key: "flush",
          value: function() {
            this._sQlen > 0 && this.readyState === "open" && (this._websocket.send(new Uint8Array(this._sQ.buffer, 0, this._sQlen)), this._sQlen = 0);
          }
        },
        {
          key: "_sQensureSpace",
          value: function(S) {
            this._sQbufferSize - this._sQlen < S && this.flush();
          }
        },
        {
          key: "off",
          value: function(S) {
            this._eventHandlers[S] = function() {
            };
          }
        },
        {
          key: "on",
          value: function(S, w) {
            this._eventHandlers[S] = w;
          }
        },
        {
          key: "_allocateBuffers",
          value: function() {
            this._rQ = new Uint8Array(this._rQbufferSize), this._sQ = new Uint8Array(this._sQbufferSize);
          }
        },
        {
          key: "init",
          value: function() {
            this._allocateBuffers(), this._rQi = 0, this._websocket = null;
          }
        },
        {
          key: "open",
          value: function(S, w) {
            this.attach(new WebSocket(S, w));
          }
        },
        {
          key: "attach",
          value: function(S) {
            var w = this;
            this.init();
            for (var C = [].concat(a(Object.keys(S)), a(Object.getOwnPropertyNames(Object.getPrototypeOf(S)))), A = 0; A < K.length; A++) {
              var O = K[A];
              if (C.indexOf(O) < 0) throw new Error("Raw channel missing property: " + O);
            }
            this._websocket = S, this._websocket.binaryType = "arraybuffer", this._websocket.onmessage = this._recvMessage.bind(this), this._websocket.onopen = function() {
              t.Debug(">> WebSock.onopen"), w._websocket.protocol && t.Info("Server choose sub-protocol: " + w._websocket.protocol), w._eventHandlers.open(), t.Debug("<< WebSock.onopen");
            }, this._websocket.onclose = function(I) {
              t.Debug(">> WebSock.onclose"), w._eventHandlers.close(I), t.Debug("<< WebSock.onclose");
            }, this._websocket.onerror = function(I) {
              t.Debug(">> WebSock.onerror: " + I), w._eventHandlers.error(I), t.Debug("<< WebSock.onerror: " + I);
            };
          }
        },
        {
          key: "close",
          value: function() {
            this._websocket && ((this.readyState === "connecting" || this.readyState === "open") && (t.Info("Closing WebSocket connection"), this._websocket.close()), this._websocket.onmessage = function() {
            });
          }
        },
        {
          key: "_expandCompactRQ",
          value: function(S) {
            var w = (this._rQlen - this._rQi + S) * 8, C = this._rQbufferSize < w;
            if (C && (this._rQbufferSize = Math.max(this._rQbufferSize * 2, w)), this._rQbufferSize > f && (this._rQbufferSize = f, this._rQbufferSize - (this._rQlen - this._rQi) < S)) throw new Error("Receive queue buffer exceeded " + f + " bytes, and the new message could not fit");
            if (C) {
              var A = this._rQ.buffer;
              this._rQ = new Uint8Array(this._rQbufferSize), this._rQ.set(new Uint8Array(A, this._rQi, this._rQlen - this._rQi));
            } else this._rQ.copyWithin(0, this._rQi, this._rQlen);
            this._rQlen = this._rQlen - this._rQi, this._rQi = 0;
          }
        },
        {
          key: "_recvMessage",
          value: function(S) {
            this._rQlen == this._rQi && (this._rQlen = 0, this._rQi = 0);
            var w = new Uint8Array(S.data);
            w.length > this._rQbufferSize - this._rQlen && this._expandCompactRQ(w.length), this._rQ.set(w, this._rQlen), this._rQlen += w.length, this._rQlen - this._rQi > 0 ? this._eventHandlers.message() : t.Debug("Ignoring empty message");
          }
        }
      ]);
    }();
  })(ns);
  var is = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0, e.default = {
      Again: 57349,
      AltLeft: 56,
      AltRight: 57400,
      ArrowDown: 57424,
      ArrowLeft: 57419,
      ArrowRight: 57421,
      ArrowUp: 57416,
      AudioVolumeDown: 57390,
      AudioVolumeMute: 57376,
      AudioVolumeUp: 57392,
      Backquote: 41,
      Backslash: 43,
      Backspace: 14,
      BracketLeft: 26,
      BracketRight: 27,
      BrowserBack: 57450,
      BrowserFavorites: 57446,
      BrowserForward: 57449,
      BrowserHome: 57394,
      BrowserRefresh: 57447,
      BrowserSearch: 57445,
      BrowserStop: 57448,
      CapsLock: 58,
      Comma: 51,
      ContextMenu: 57437,
      ControlLeft: 29,
      ControlRight: 57373,
      Convert: 121,
      Copy: 57464,
      Cut: 57404,
      Delete: 57427,
      Digit0: 11,
      Digit1: 2,
      Digit2: 3,
      Digit3: 4,
      Digit4: 5,
      Digit5: 6,
      Digit6: 7,
      Digit7: 8,
      Digit8: 9,
      Digit9: 10,
      Eject: 57469,
      End: 57423,
      Enter: 28,
      Equal: 13,
      Escape: 1,
      F1: 59,
      F10: 68,
      F11: 87,
      F12: 88,
      F13: 93,
      F14: 94,
      F15: 95,
      F16: 85,
      F17: 57347,
      F18: 57463,
      F19: 57348,
      F2: 60,
      F20: 90,
      F21: 116,
      F22: 57465,
      F23: 109,
      F24: 111,
      F3: 61,
      F4: 62,
      F5: 63,
      F6: 64,
      F7: 65,
      F8: 66,
      F9: 67,
      Find: 57409,
      Help: 57461,
      Hiragana: 119,
      Home: 57415,
      Insert: 57426,
      IntlBackslash: 86,
      IntlRo: 115,
      IntlYen: 125,
      KanaMode: 112,
      Katakana: 120,
      KeyA: 30,
      KeyB: 48,
      KeyC: 46,
      KeyD: 32,
      KeyE: 18,
      KeyF: 33,
      KeyG: 34,
      KeyH: 35,
      KeyI: 23,
      KeyJ: 36,
      KeyK: 37,
      KeyL: 38,
      KeyM: 50,
      KeyN: 49,
      KeyO: 24,
      KeyP: 25,
      KeyQ: 16,
      KeyR: 19,
      KeyS: 31,
      KeyT: 20,
      KeyU: 22,
      KeyV: 47,
      KeyW: 17,
      KeyX: 45,
      KeyY: 21,
      KeyZ: 44,
      Lang1: 114,
      Lang2: 113,
      Lang3: 120,
      Lang4: 119,
      Lang5: 118,
      LaunchApp1: 57451,
      LaunchApp2: 57377,
      LaunchMail: 57452,
      MediaPlayPause: 57378,
      MediaSelect: 57453,
      MediaStop: 57380,
      MediaTrackNext: 57369,
      MediaTrackPrevious: 57360,
      MetaLeft: 57435,
      MetaRight: 57436,
      Minus: 12,
      NonConvert: 123,
      NumLock: 69,
      Numpad0: 82,
      Numpad1: 79,
      Numpad2: 80,
      Numpad3: 81,
      Numpad4: 75,
      Numpad5: 76,
      Numpad6: 77,
      Numpad7: 71,
      Numpad8: 72,
      Numpad9: 73,
      NumpadAdd: 78,
      NumpadComma: 126,
      NumpadDecimal: 83,
      NumpadDivide: 57397,
      NumpadEnter: 57372,
      NumpadEqual: 89,
      NumpadMultiply: 55,
      NumpadParenLeft: 57462,
      NumpadParenRight: 57467,
      NumpadSubtract: 74,
      Open: 100,
      PageDown: 57425,
      PageUp: 57417,
      Paste: 101,
      Pause: 57414,
      Period: 52,
      Power: 57438,
      PrintScreen: 84,
      Props: 57350,
      Quote: 40,
      ScrollLock: 70,
      Semicolon: 39,
      ShiftLeft: 42,
      ShiftRight: 54,
      Slash: 53,
      Sleep: 57439,
      Space: 57,
      Suspend: 57381,
      Tab: 15,
      Undo: 57351,
      WakeUp: 57443
    };
  })(is);
  var qr = {};
  Object.defineProperty(qr, "__esModule", {
    value: true
  });
  qr.encodingName = Ll;
  qr.encodings = void 0;
  var Ft = qr.encodings = {
    encodingRaw: 0,
    encodingCopyRect: 1,
    encodingRRE: 2,
    encodingHextile: 5,
    encodingZlib: 6,
    encodingTight: 7,
    encodingZRLE: 16,
    encodingTightPNG: -260,
    encodingJPEG: 21,
    encodingH264: 50,
    pseudoEncodingQualityLevel9: -23,
    pseudoEncodingQualityLevel0: -32,
    pseudoEncodingDesktopSize: -223,
    pseudoEncodingLastRect: -224,
    pseudoEncodingCursor: -239,
    pseudoEncodingQEMUExtendedKeyEvent: -258,
    pseudoEncodingQEMULedEvent: -261,
    pseudoEncodingDesktopName: -307,
    pseudoEncodingExtendedDesktopSize: -308,
    pseudoEncodingXvp: -309,
    pseudoEncodingFence: -312,
    pseudoEncodingContinuousUpdates: -313,
    pseudoEncodingExtendedMouseButtons: -316,
    pseudoEncodingCompressLevel9: -247,
    pseudoEncodingCompressLevel0: -256,
    pseudoEncodingVMwareCursor: 1464686180,
    pseudoEncodingExtendedClipboard: 3231835598
  };
  function Ll(e) {
    switch (e) {
      case Ft.encodingRaw:
        return "Raw";
      case Ft.encodingCopyRect:
        return "CopyRect";
      case Ft.encodingRRE:
        return "RRE";
      case Ft.encodingHextile:
        return "Hextile";
      case Ft.encodingZlib:
        return "Zlib";
      case Ft.encodingTight:
        return "Tight";
      case Ft.encodingZRLE:
        return "ZRLE";
      case Ft.encodingTightPNG:
        return "TightPNG";
      case Ft.encodingJPEG:
        return "JPEG";
      case Ft.encodingH264:
        return "H.264";
      default:
        return "[unknown encoding " + e + "]";
    }
  }
  var as = {}, bi = {}, vr = {};
  Object.defineProperty(vr, "__esModule", {
    value: true
  });
  vr.AESECBCipher = vr.AESEAXCipher = void 0;
  function nr(e) {
    "@babel/helpers - typeof";
    return nr = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, nr(e);
  }
  function De() {
    De = function() {
      return t;
    };
    var e, t = {}, n = Object.prototype, r = n.hasOwnProperty, i = Object.defineProperty || function(E, p, m) {
      E[p] = m.value;
    }, a = typeof Symbol == "function" ? Symbol : {}, o = a.iterator || "@@iterator", s = a.asyncIterator || "@@asyncIterator", y = a.toStringTag || "@@toStringTag";
    function u(E, p, m) {
      return Object.defineProperty(E, p, {
        value: m,
        enumerable: true,
        configurable: true,
        writable: true
      }), E[p];
    }
    try {
      u({}, "");
    } catch {
      u = function(m, L, B) {
        return m[L] = B;
      };
    }
    function l(E, p, m, L) {
      var B = p && p.prototype instanceof c ? p : c, M = Object.create(B.prototype), V = new $(L || []);
      return i(M, "_invoke", {
        value: O(E, m, V)
      }), M;
    }
    function k(E, p, m) {
      try {
        return {
          type: "normal",
          arg: E.call(p, m)
        };
      } catch (L) {
        return {
          type: "throw",
          arg: L
        };
      }
    }
    t.wrap = l;
    var X = "suspendedStart", g = "suspendedYield", b = "executing", d = "completed", f = {};
    function c() {
    }
    function h() {
    }
    function K() {
    }
    var x = {};
    u(x, o, function() {
      return this;
    });
    var F = Object.getPrototypeOf, S = F && F(F(ne([])));
    S && S !== n && r.call(S, o) && (x = S);
    var w = K.prototype = c.prototype = Object.create(x);
    function C(E) {
      [
        "next",
        "throw",
        "return"
      ].forEach(function(p) {
        u(E, p, function(m) {
          return this._invoke(p, m);
        });
      });
    }
    function A(E, p) {
      function m(B, M, V, re) {
        var oe = k(E[B], E, M);
        if (oe.type !== "throw") {
          var ce = oe.arg, pe = ce.value;
          return pe && nr(pe) == "object" && r.call(pe, "__await") ? p.resolve(pe.__await).then(function(ye) {
            m("next", ye, V, re);
          }, function(ye) {
            m("throw", ye, V, re);
          }) : p.resolve(pe).then(function(ye) {
            ce.value = ye, V(ce);
          }, function(ye) {
            return m("throw", ye, V, re);
          });
        }
        re(oe.arg);
      }
      var L;
      i(this, "_invoke", {
        value: function(M, V) {
          function re() {
            return new p(function(oe, ce) {
              m(M, V, oe, ce);
            });
          }
          return L = L ? L.then(re, re) : re();
        }
      });
    }
    function O(E, p, m) {
      var L = X;
      return function(B, M) {
        if (L === b) throw Error("Generator is already running");
        if (L === d) {
          if (B === "throw") throw M;
          return {
            value: e,
            done: true
          };
        }
        for (m.method = B, m.arg = M; ; ) {
          var V = m.delegate;
          if (V) {
            var re = I(V, m);
            if (re) {
              if (re === f) continue;
              return re;
            }
          }
          if (m.method === "next") m.sent = m._sent = m.arg;
          else if (m.method === "throw") {
            if (L === X) throw L = d, m.arg;
            m.dispatchException(m.arg);
          } else m.method === "return" && m.abrupt("return", m.arg);
          L = b;
          var oe = k(E, p, m);
          if (oe.type === "normal") {
            if (L = m.done ? d : g, oe.arg === f) continue;
            return {
              value: oe.arg,
              done: m.done
            };
          }
          oe.type === "throw" && (L = d, m.method = "throw", m.arg = oe.arg);
        }
      };
    }
    function I(E, p) {
      var m = p.method, L = E.iterator[m];
      if (L === e) return p.delegate = null, m === "throw" && E.iterator.return && (p.method = "return", p.arg = e, I(E, p), p.method === "throw") || m !== "return" && (p.method = "throw", p.arg = new TypeError("The iterator does not provide a '" + m + "' method")), f;
      var B = k(L, E.iterator, p.arg);
      if (B.type === "throw") return p.method = "throw", p.arg = B.arg, p.delegate = null, f;
      var M = B.arg;
      return M ? M.done ? (p[E.resultName] = M.value, p.next = E.nextLoc, p.method !== "return" && (p.method = "next", p.arg = e), p.delegate = null, f) : M : (p.method = "throw", p.arg = new TypeError("iterator result is not an object"), p.delegate = null, f);
    }
    function Z(E) {
      var p = {
        tryLoc: E[0]
      };
      1 in E && (p.catchLoc = E[1]), 2 in E && (p.finallyLoc = E[2], p.afterLoc = E[3]), this.tryEntries.push(p);
    }
    function q(E) {
      var p = E.completion || {};
      p.type = "normal", delete p.arg, E.completion = p;
    }
    function $(E) {
      this.tryEntries = [
        {
          tryLoc: "root"
        }
      ], E.forEach(Z, this), this.reset(true);
    }
    function ne(E) {
      if (E || E === "") {
        var p = E[o];
        if (p) return p.call(E);
        if (typeof E.next == "function") return E;
        if (!isNaN(E.length)) {
          var m = -1, L = function B() {
            for (; ++m < E.length; ) if (r.call(E, m)) return B.value = E[m], B.done = false, B;
            return B.value = e, B.done = true, B;
          };
          return L.next = L;
        }
      }
      throw new TypeError(nr(E) + " is not iterable");
    }
    return h.prototype = K, i(w, "constructor", {
      value: K,
      configurable: true
    }), i(K, "constructor", {
      value: h,
      configurable: true
    }), h.displayName = u(K, y, "GeneratorFunction"), t.isGeneratorFunction = function(E) {
      var p = typeof E == "function" && E.constructor;
      return !!p && (p === h || (p.displayName || p.name) === "GeneratorFunction");
    }, t.mark = function(E) {
      return Object.setPrototypeOf ? Object.setPrototypeOf(E, K) : (E.__proto__ = K, u(E, y, "GeneratorFunction")), E.prototype = Object.create(w), E;
    }, t.awrap = function(E) {
      return {
        __await: E
      };
    }, C(A.prototype), u(A.prototype, s, function() {
      return this;
    }), t.AsyncIterator = A, t.async = function(E, p, m, L, B) {
      B === void 0 && (B = Promise);
      var M = new A(l(E, p, m, L), B);
      return t.isGeneratorFunction(p) ? M : M.next().then(function(V) {
        return V.done ? V.value : M.next();
      });
    }, C(w), u(w, y, "Generator"), u(w, o, function() {
      return this;
    }), u(w, "toString", function() {
      return "[object Generator]";
    }), t.keys = function(E) {
      var p = Object(E), m = [];
      for (var L in p) m.push(L);
      return m.reverse(), function B() {
        for (; m.length; ) {
          var M = m.pop();
          if (M in p) return B.value = M, B.done = false, B;
        }
        return B.done = true, B;
      };
    }, t.values = ne, $.prototype = {
      constructor: $,
      reset: function(p) {
        if (this.prev = 0, this.next = 0, this.sent = this._sent = e, this.done = false, this.delegate = null, this.method = "next", this.arg = e, this.tryEntries.forEach(q), !p) for (var m in this) m.charAt(0) === "t" && r.call(this, m) && !isNaN(+m.slice(1)) && (this[m] = e);
      },
      stop: function() {
        this.done = true;
        var p = this.tryEntries[0].completion;
        if (p.type === "throw") throw p.arg;
        return this.rval;
      },
      dispatchException: function(p) {
        if (this.done) throw p;
        var m = this;
        function L(ce, pe) {
          return V.type = "throw", V.arg = p, m.next = ce, pe && (m.method = "next", m.arg = e), !!pe;
        }
        for (var B = this.tryEntries.length - 1; B >= 0; --B) {
          var M = this.tryEntries[B], V = M.completion;
          if (M.tryLoc === "root") return L("end");
          if (M.tryLoc <= this.prev) {
            var re = r.call(M, "catchLoc"), oe = r.call(M, "finallyLoc");
            if (re && oe) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            } else if (re) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
            } else {
              if (!oe) throw Error("try statement without catch or finally");
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            }
          }
        }
      },
      abrupt: function(p, m) {
        for (var L = this.tryEntries.length - 1; L >= 0; --L) {
          var B = this.tryEntries[L];
          if (B.tryLoc <= this.prev && r.call(B, "finallyLoc") && this.prev < B.finallyLoc) {
            var M = B;
            break;
          }
        }
        M && (p === "break" || p === "continue") && M.tryLoc <= m && m <= M.finallyLoc && (M = null);
        var V = M ? M.completion : {};
        return V.type = p, V.arg = m, M ? (this.method = "next", this.next = M.finallyLoc, f) : this.complete(V);
      },
      complete: function(p, m) {
        if (p.type === "throw") throw p.arg;
        return p.type === "break" || p.type === "continue" ? this.next = p.arg : p.type === "return" ? (this.rval = this.arg = p.arg, this.method = "return", this.next = "end") : p.type === "normal" && m && (this.next = m), f;
      },
      finish: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.finallyLoc === p) return this.complete(L.completion, L.afterLoc), q(L), f;
        }
      },
      catch: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.tryLoc === p) {
            var B = L.completion;
            if (B.type === "throw") {
              var M = B.arg;
              q(L);
            }
            return M;
          }
        }
        throw Error("illegal catch attempt");
      },
      delegateYield: function(p, m, L) {
        return this.delegate = {
          iterator: ne(p),
          resultName: m,
          nextLoc: L
        }, this.method === "next" && (this.arg = e), f;
      }
    }, t;
  }
  function Ka(e, t, n, r, i, a, o) {
    try {
      var s = e[a](o), y = s.value;
    } catch (u) {
      return void n(u);
    }
    s.done ? t(y) : Promise.resolve(y).then(r, i);
  }
  function dt(e) {
    return function() {
      var t = this, n = arguments;
      return new Promise(function(r, i) {
        var a = e.apply(t, n);
        function o(y) {
          Ka(a, r, i, o, s, "next", y);
        }
        function s(y) {
          Ka(a, r, i, o, s, "throw", y);
        }
        o(void 0);
      });
    };
  }
  function os(e, t) {
    if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
  }
  function Xa(e, t) {
    for (var n = 0; n < t.length; n++) {
      var r = t[n];
      r.enumerable = r.enumerable || false, r.configurable = true, "value" in r && (r.writable = true), Object.defineProperty(e, Rl(r.key), r);
    }
  }
  function ss(e, t, n) {
    return t && Xa(e.prototype, t), n && Xa(e, n), Object.defineProperty(e, "prototype", {
      writable: false
    }), e;
  }
  function Rl(e) {
    var t = Ml(e, "string");
    return nr(t) == "symbol" ? t : t + "";
  }
  function Ml(e, t) {
    if (nr(e) != "object" || !e) return e;
    var n = e[Symbol.toPrimitive];
    if (n !== void 0) {
      var r = n.call(e, t);
      if (nr(r) != "object") return r;
      throw new TypeError("@@toPrimitive must return a primitive value.");
    }
    return String(e);
  }
  vr.AESECBCipher = function() {
    function e() {
      os(this, e), this._key = null;
    }
    return ss(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "AES-ECB"
          };
        }
      },
      {
        key: "_importKey",
        value: function() {
          var t = dt(De().mark(function r(i, a, o) {
            return De().wrap(function(y) {
              for (; ; ) switch (y.prev = y.next) {
                case 0:
                  return y.next = 2, window.crypto.subtle.importKey("raw", i, {
                    name: "AES-CBC"
                  }, a, o);
                case 2:
                  this._key = y.sent;
                case 3:
                case "end":
                  return y.stop();
              }
            }, r, this);
          }));
          function n(r, i, a) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "encrypt",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o, s, y, u;
            return De().wrap(function(k) {
              for (; ; ) switch (k.prev = k.next) {
                case 0:
                  if (o = new Uint8Array(a), !(o.length % 16 !== 0 || this._key === null)) {
                    k.next = 3;
                    break;
                  }
                  return k.abrupt("return", null);
                case 3:
                  s = o.length / 16, y = 0;
                case 5:
                  if (!(y < s)) {
                    k.next = 15;
                    break;
                  }
                  return k.t0 = Uint8Array, k.next = 9, window.crypto.subtle.encrypt({
                    name: "AES-CBC",
                    iv: new Uint8Array(16)
                  }, this._key, o.slice(y * 16, y * 16 + 16));
                case 9:
                  k.t1 = k.sent, u = new k.t0(k.t1).slice(0, 16), o.set(u, y * 16);
                case 12:
                  y++, k.next = 5;
                  break;
                case 15:
                  return k.abrupt("return", o);
                case 16:
                case "end":
                  return k.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ], [
      {
        key: "importKey",
        value: function() {
          var t = dt(De().mark(function r(i, a, o, s) {
            var y;
            return De().wrap(function(l) {
              for (; ; ) switch (l.prev = l.next) {
                case 0:
                  return y = new e(), l.next = 3, y._importKey(i, o, s);
                case 3:
                  return l.abrupt("return", y);
                case 4:
                case "end":
                  return l.stop();
              }
            }, r);
          }));
          function n(r, i, a, o) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ]);
  }();
  vr.AESEAXCipher = function() {
    function e() {
      os(this, e), this._rawKey = null, this._ctrKey = null, this._cbcKey = null, this._zeroBlock = new Uint8Array(16), this._prefixBlock0 = this._zeroBlock, this._prefixBlock1 = new Uint8Array([
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1
      ]), this._prefixBlock2 = new Uint8Array([
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        2
      ]);
    }
    return ss(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "AES-EAX"
          };
        }
      },
      {
        key: "_encryptBlock",
        value: function() {
          var t = dt(De().mark(function r(i) {
            var a;
            return De().wrap(function(s) {
              for (; ; ) switch (s.prev = s.next) {
                case 0:
                  return s.next = 2, window.crypto.subtle.encrypt({
                    name: "AES-CBC",
                    iv: this._zeroBlock
                  }, this._cbcKey, i);
                case 2:
                  return a = s.sent, s.abrupt("return", new Uint8Array(a).slice(0, 16));
                case 4:
                case "end":
                  return s.stop();
              }
            }, r, this);
          }));
          function n(r) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_initCMAC",
        value: function() {
          var t = dt(De().mark(function r() {
            var i, a, o, s, y;
            return De().wrap(function(l) {
              for (; ; ) switch (l.prev = l.next) {
                case 0:
                  return l.next = 2, this._encryptBlock(this._zeroBlock);
                case 2:
                  for (i = l.sent, a = new Uint8Array(16), o = i[0] >>> 6, s = 0; s < 15; s++) a[s] = i[s + 1] >> 6 | i[s] << 2, i[s] = i[s + 1] >> 7 | i[s] << 1;
                  y = [
                    0,
                    135,
                    14,
                    137
                  ], a[14] ^= o >>> 1, a[15] = i[15] << 2 ^ y[o], i[15] = i[15] << 1 ^ y[o >> 1], this._k1 = i, this._k2 = a;
                case 12:
                case "end":
                  return l.stop();
              }
            }, r, this);
          }));
          function n() {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_encryptCTR",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o;
            return De().wrap(function(y) {
              for (; ; ) switch (y.prev = y.next) {
                case 0:
                  return y.next = 2, window.crypto.subtle.encrypt({
                    name: "AES-CTR",
                    counter: a,
                    length: 128
                  }, this._ctrKey, i);
                case 2:
                  return o = y.sent, y.abrupt("return", new Uint8Array(o));
                case 4:
                case "end":
                  return y.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_decryptCTR",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o;
            return De().wrap(function(y) {
              for (; ; ) switch (y.prev = y.next) {
                case 0:
                  return y.next = 2, window.crypto.subtle.decrypt({
                    name: "AES-CTR",
                    counter: a,
                    length: 128
                  }, this._ctrKey, i);
                case 2:
                  return o = y.sent, y.abrupt("return", new Uint8Array(o));
                case 4:
                case "end":
                  return y.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_computeCMAC",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o, s, y, u, l, k, X, g;
            return De().wrap(function(d) {
              for (; ; ) switch (d.prev = d.next) {
                case 0:
                  if (a.length === 16) {
                    d.next = 2;
                    break;
                  }
                  return d.abrupt("return", null);
                case 2:
                  if (o = Math.floor(i.length / 16), s = Math.ceil(i.length / 16), y = i.length - o * 16, u = new Uint8Array((s + 1) * 16), u.set(a), u.set(i, 16), y === 0) for (l = 0; l < 16; l++) u[o * 16 + l] ^= this._k1[l];
                  else for (u[(o + 1) * 16 + y] = 128, k = 0; k < 16; k++) u[(o + 1) * 16 + k] ^= this._k2[k];
                  return d.next = 11, window.crypto.subtle.encrypt({
                    name: "AES-CBC",
                    iv: this._zeroBlock
                  }, this._cbcKey, u);
                case 11:
                  return X = d.sent, X = new Uint8Array(X), g = X.slice(X.length - 32, X.length - 16), d.abrupt("return", g);
                case 15:
                case "end":
                  return d.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_importKey",
        value: function() {
          var t = dt(De().mark(function r(i) {
            return De().wrap(function(o) {
              for (; ; ) switch (o.prev = o.next) {
                case 0:
                  return this._rawKey = i, o.next = 3, window.crypto.subtle.importKey("raw", i, {
                    name: "AES-CTR"
                  }, false, [
                    "encrypt",
                    "decrypt"
                  ]);
                case 3:
                  return this._ctrKey = o.sent, o.next = 6, window.crypto.subtle.importKey("raw", i, {
                    name: "AES-CBC"
                  }, false, [
                    "encrypt"
                  ]);
                case 6:
                  return this._cbcKey = o.sent, o.next = 9, this._initCMAC();
                case 9:
                case "end":
                  return o.stop();
              }
            }, r, this);
          }));
          function n(r) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "encrypt",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o, s, y, u, l, k, X, g;
            return De().wrap(function(d) {
              for (; ; ) switch (d.prev = d.next) {
                case 0:
                  return o = i.additionalData, s = i.iv, d.next = 4, this._computeCMAC(s, this._prefixBlock0);
                case 4:
                  return y = d.sent, d.next = 7, this._encryptCTR(a, y);
                case 7:
                  return u = d.sent, d.next = 10, this._computeCMAC(o, this._prefixBlock1);
                case 10:
                  return l = d.sent, d.next = 13, this._computeCMAC(u, this._prefixBlock2);
                case 13:
                  for (k = d.sent, X = 0; X < 16; X++) k[X] ^= y[X] ^ l[X];
                  return g = new Uint8Array(16 + u.length), g.set(u), g.set(k, u.length), d.abrupt("return", g);
                case 19:
                case "end":
                  return d.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "decrypt",
        value: function() {
          var t = dt(De().mark(function r(i, a) {
            var o, s, y, u, l, k, X, g, b, d;
            return De().wrap(function(c) {
              for (; ; ) switch (c.prev = c.next) {
                case 0:
                  return o = a.slice(0, a.length - 16), s = i.additionalData, y = i.iv, u = a.slice(a.length - 16), c.next = 6, this._computeCMAC(y, this._prefixBlock0);
                case 6:
                  return l = c.sent, c.next = 9, this._computeCMAC(s, this._prefixBlock1);
                case 9:
                  return k = c.sent, c.next = 12, this._computeCMAC(o, this._prefixBlock2);
                case 12:
                  for (X = c.sent, g = 0; g < 16; g++) X[g] ^= l[g] ^ k[g];
                  if (X.length === u.length) {
                    c.next = 16;
                    break;
                  }
                  return c.abrupt("return", null);
                case 16:
                  b = 0;
                case 17:
                  if (!(b < u.length)) {
                    c.next = 23;
                    break;
                  }
                  if (X[b] === u[b]) {
                    c.next = 20;
                    break;
                  }
                  return c.abrupt("return", null);
                case 20:
                  b++, c.next = 17;
                  break;
                case 23:
                  return c.next = 25, this._decryptCTR(o, l);
                case 25:
                  return d = c.sent, c.abrupt("return", d);
                case 27:
                case "end":
                  return c.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ], [
      {
        key: "importKey",
        value: function() {
          var t = dt(De().mark(function r(i, a, o, s) {
            var y;
            return De().wrap(function(l) {
              for (; ; ) switch (l.prev = l.next) {
                case 0:
                  return y = new e(), l.next = 3, y._importKey(i);
                case 3:
                  return l.abrupt("return", y);
                case 4:
                case "end":
                  return l.stop();
              }
            }, r);
          }));
          function n(r, i, a, o) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ]);
  }();
  var yr = {};
  Object.defineProperty(yr, "__esModule", {
    value: true
  });
  yr.DESECBCipher = yr.DESCBCCipher = void 0;
  function Ir(e) {
    "@babel/helpers - typeof";
    return Ir = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, Ir(e);
  }
  function mi(e, t) {
    if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
  }
  function Fa(e, t) {
    for (var n = 0; n < t.length; n++) {
      var r = t[n];
      r.enumerable = r.enumerable || false, r.configurable = true, "value" in r && (r.writable = true), Object.defineProperty(e, Dl(r.key), r);
    }
  }
  function wi(e, t, n) {
    return t && Fa(e.prototype, t), n && Fa(e, n), Object.defineProperty(e, "prototype", {
      writable: false
    }), e;
  }
  function Dl(e) {
    var t = Ol(e, "string");
    return Ir(t) == "symbol" ? t : t + "";
  }
  function Ol(e, t) {
    if (Ir(e) != "object" || !e) return e;
    var n = e[Symbol.toPrimitive];
    if (n !== void 0) {
      var r = n.call(e, t);
      if (Ir(r) != "object") return r;
      throw new TypeError("@@toPrimitive must return a primitive value.");
    }
    return String(e);
  }
  var Ca = [
    13,
    16,
    10,
    23,
    0,
    4,
    2,
    27,
    14,
    5,
    20,
    9,
    22,
    18,
    11,
    3,
    25,
    7,
    15,
    6,
    26,
    19,
    12,
    1,
    40,
    51,
    30,
    36,
    46,
    54,
    29,
    39,
    50,
    44,
    32,
    47,
    43,
    48,
    38,
    55,
    33,
    52,
    45,
    41,
    49,
    35,
    28,
    31
  ], Bl = [
    1,
    2,
    4,
    6,
    8,
    10,
    12,
    14,
    15,
    17,
    19,
    21,
    23,
    25,
    27,
    28
  ], P = 0, Q, U, W, N, j, z;
  Q = 65536;
  U = 1 << 24;
  W = Q | U;
  N = 4;
  j = 1024;
  z = N | j;
  var Aa = [
    W | j,
    P | P,
    Q | P,
    W | z,
    W | N,
    Q | z,
    P | N,
    Q | P,
    P | j,
    W | j,
    W | z,
    P | j,
    U | z,
    W | N,
    U | P,
    P | N,
    P | z,
    U | j,
    U | j,
    Q | j,
    Q | j,
    W | P,
    W | P,
    U | z,
    Q | N,
    U | N,
    U | N,
    Q | N,
    P | P,
    P | z,
    Q | z,
    U | P,
    Q | P,
    W | z,
    P | N,
    W | P,
    W | j,
    U | P,
    U | P,
    P | j,
    W | N,
    Q | P,
    Q | j,
    U | N,
    P | j,
    P | N,
    U | z,
    Q | z,
    W | z,
    Q | N,
    W | P,
    U | z,
    U | N,
    P | z,
    Q | z,
    W | j,
    P | z,
    U | j,
    U | j,
    P | P,
    Q | N,
    Q | j,
    P | P,
    W | N
  ];
  Q = 1 << 20;
  U = 1 << 31;
  W = Q | U;
  N = 32;
  j = 32768;
  z = N | j;
  var Pa = [
    W | z,
    U | j,
    P | j,
    Q | z,
    Q | P,
    P | N,
    W | N,
    U | z,
    U | N,
    W | z,
    W | j,
    U | P,
    U | j,
    Q | P,
    P | N,
    W | N,
    Q | j,
    Q | N,
    U | z,
    P | P,
    U | P,
    P | j,
    Q | z,
    W | P,
    Q | N,
    U | N,
    P | P,
    Q | j,
    P | z,
    W | j,
    W | P,
    P | z,
    P | P,
    Q | z,
    W | N,
    Q | P,
    U | z,
    W | P,
    W | j,
    P | j,
    W | P,
    U | j,
    P | N,
    W | z,
    Q | z,
    P | N,
    P | j,
    U | P,
    P | z,
    W | j,
    Q | P,
    U | N,
    Q | N,
    U | z,
    U | N,
    Q | N,
    Q | j,
    P | P,
    U | j,
    P | z,
    U | P,
    W | N,
    W | z,
    Q | j
  ];
  Q = 1 << 17;
  U = 1 << 27;
  W = Q | U;
  N = 8;
  j = 512;
  z = N | j;
  var Ta = [
    P | z,
    W | j,
    P | P,
    W | N,
    U | j,
    P | P,
    Q | z,
    U | j,
    Q | N,
    U | N,
    U | N,
    Q | P,
    W | z,
    Q | N,
    W | P,
    P | z,
    U | P,
    P | N,
    W | j,
    P | j,
    Q | j,
    W | P,
    W | N,
    Q | z,
    U | z,
    Q | j,
    Q | P,
    U | z,
    P | N,
    W | z,
    P | j,
    U | P,
    W | j,
    U | P,
    Q | N,
    P | z,
    Q | P,
    W | j,
    U | j,
    P | P,
    P | j,
    Q | N,
    W | z,
    U | j,
    U | N,
    P | j,
    P | P,
    W | N,
    U | z,
    Q | P,
    U | P,
    W | z,
    P | N,
    Q | z,
    Q | j,
    U | N,
    W | P,
    U | z,
    P | z,
    W | P,
    Q | z,
    P | N,
    W | N,
    Q | j
  ];
  Q = 8192;
  U = 1 << 23;
  W = Q | U;
  N = 1;
  j = 128;
  z = N | j;
  var La = [
    W | N,
    Q | z,
    Q | z,
    P | j,
    W | j,
    U | z,
    U | N,
    Q | N,
    P | P,
    W | P,
    W | P,
    W | z,
    P | z,
    P | P,
    U | j,
    U | N,
    P | N,
    Q | P,
    U | P,
    W | N,
    P | j,
    U | P,
    Q | N,
    Q | j,
    U | z,
    P | N,
    Q | j,
    U | j,
    Q | P,
    W | j,
    W | z,
    P | z,
    U | j,
    U | N,
    W | P,
    W | z,
    P | z,
    P | P,
    P | P,
    W | P,
    Q | j,
    U | j,
    U | z,
    P | N,
    W | N,
    Q | z,
    Q | z,
    P | j,
    W | z,
    P | z,
    P | N,
    Q | P,
    U | N,
    Q | N,
    W | j,
    U | z,
    Q | N,
    Q | j,
    U | P,
    W | N,
    P | j,
    U | P,
    Q | P,
    W | j
  ];
  Q = 1 << 25;
  U = 1 << 30;
  W = Q | U;
  N = 256;
  j = 1 << 19;
  z = N | j;
  var Ra = [
    P | N,
    Q | z,
    Q | j,
    W | N,
    P | j,
    P | N,
    U | P,
    Q | j,
    U | z,
    P | j,
    Q | N,
    U | z,
    W | N,
    W | j,
    P | z,
    U | P,
    Q | P,
    U | j,
    U | j,
    P | P,
    U | N,
    W | z,
    W | z,
    Q | N,
    W | j,
    U | N,
    P | P,
    W | P,
    Q | z,
    Q | P,
    W | P,
    P | z,
    P | j,
    W | N,
    P | N,
    Q | P,
    U | P,
    Q | j,
    W | N,
    U | z,
    Q | N,
    U | P,
    W | j,
    Q | z,
    U | z,
    P | N,
    Q | P,
    W | j,
    W | z,
    P | z,
    W | P,
    W | z,
    Q | j,
    P | P,
    U | j,
    W | P,
    P | z,
    Q | N,
    U | N,
    P | j,
    P | P,
    U | j,
    Q | z,
    U | N
  ];
  Q = 1 << 22;
  U = 1 << 29;
  W = Q | U;
  N = 16;
  j = 16384;
  z = N | j;
  var Ma = [
    U | N,
    W | P,
    P | j,
    W | z,
    W | P,
    P | N,
    W | z,
    Q | P,
    U | j,
    Q | z,
    Q | P,
    U | N,
    Q | N,
    U | j,
    U | P,
    P | z,
    P | P,
    Q | N,
    U | z,
    P | j,
    Q | j,
    U | z,
    P | N,
    W | N,
    W | N,
    P | P,
    Q | z,
    W | j,
    P | z,
    Q | j,
    W | j,
    U | P,
    U | j,
    P | N,
    W | N,
    Q | j,
    W | z,
    Q | P,
    P | z,
    U | N,
    Q | P,
    U | j,
    U | P,
    P | z,
    U | N,
    W | z,
    Q | j,
    W | P,
    Q | z,
    W | j,
    P | P,
    W | N,
    P | N,
    P | j,
    W | P,
    Q | z,
    P | j,
    Q | N,
    U | z,
    P | P,
    W | j,
    U | P,
    Q | N,
    U | z
  ];
  Q = 1 << 21;
  U = 1 << 26;
  W = Q | U;
  N = 2;
  j = 2048;
  z = N | j;
  var Da = [
    Q | P,
    W | N,
    U | z,
    P | P,
    P | j,
    U | z,
    Q | z,
    W | j,
    W | z,
    Q | P,
    P | P,
    U | N,
    P | N,
    U | P,
    W | N,
    P | z,
    U | j,
    Q | z,
    Q | N,
    U | j,
    U | N,
    W | P,
    W | j,
    Q | N,
    W | P,
    P | j,
    P | z,
    W | z,
    Q | j,
    P | N,
    U | P,
    Q | j,
    U | P,
    Q | j,
    Q | P,
    U | z,
    U | z,
    W | N,
    W | N,
    P | N,
    Q | N,
    U | P,
    U | j,
    Q | P,
    W | j,
    P | z,
    Q | z,
    W | j,
    P | z,
    U | N,
    W | z,
    W | P,
    Q | j,
    P | P,
    P | N,
    W | z,
    P | P,
    Q | z,
    W | P,
    P | j,
    U | N,
    U | j,
    P | j,
    Q | N
  ];
  Q = 1 << 18;
  U = 1 << 28;
  W = Q | U;
  N = 64;
  j = 4096;
  z = N | j;
  var Oa = [
    U | z,
    P | j,
    Q | P,
    W | z,
    U | P,
    U | z,
    P | N,
    U | P,
    Q | N,
    W | P,
    W | z,
    Q | j,
    W | j,
    Q | z,
    P | j,
    P | N,
    W | P,
    U | N,
    U | j,
    P | z,
    Q | j,
    Q | N,
    W | N,
    W | j,
    P | z,
    P | P,
    P | P,
    W | N,
    U | N,
    U | j,
    Q | z,
    Q | P,
    Q | z,
    Q | P,
    W | j,
    P | j,
    P | N,
    W | N,
    P | j,
    Q | z,
    U | j,
    P | N,
    U | N,
    W | P,
    W | N,
    U | P,
    Q | P,
    U | z,
    P | P,
    W | z,
    Q | N,
    U | N,
    W | P,
    U | j,
    U | z,
    P | P,
    W | z,
    Q | j,
    Q | j,
    P | z,
    P | z,
    Q | N,
    U | P,
    W | j
  ], us = function() {
    function e(t) {
      mi(this, e), this.keys = [];
      for (var n = [], r = [], i = [], a = 0, o = 56; a < 56; ++a, o -= 8) {
        o += o < -5 ? 65 : o < -3 ? 31 : o < -1 ? 63 : o === 27 ? 35 : 0;
        var s = o & 7;
        n[a] = t[o >>> 3] & 1 << s ? 1 : 0;
      }
      for (var y = 0; y < 16; ++y) {
        var u = y << 1, l = u + 1;
        i[u] = i[l] = 0;
        for (var k = 28; k < 59; k += 28) for (var X = k - 28; X < k; ++X) {
          var g = X + Bl[y];
          r[X] = g < k ? n[g] : n[g - 28];
        }
        for (var b = 0; b < 24; ++b) r[Ca[b]] !== 0 && (i[u] |= 1 << 23 - b), r[Ca[b + 24]] !== 0 && (i[l] |= 1 << 23 - b);
      }
      for (var d = 0, f = 0, c = 0; d < 16; ++d) {
        var h = i[f++], K = i[f++];
        this.keys[c] = (h & 16515072) << 6, this.keys[c] |= (h & 4032) << 10, this.keys[c] |= (K & 16515072) >>> 10, this.keys[c] |= (K & 4032) >>> 6, ++c, this.keys[c] = (h & 258048) << 12, this.keys[c] |= (h & 63) << 16, this.keys[c] |= (K & 258048) >>> 4, this.keys[c] |= K & 63, ++c;
      }
    }
    return wi(e, [
      {
        key: "enc8",
        value: function(n) {
          var r = n.slice(), i = 0, a, o, s;
          a = r[i++] << 24 | r[i++] << 16 | r[i++] << 8 | r[i++], o = r[i++] << 24 | r[i++] << 16 | r[i++] << 8 | r[i++], s = (a >>> 4 ^ o) & 252645135, o ^= s, a ^= s << 4, s = (a >>> 16 ^ o) & 65535, o ^= s, a ^= s << 16, s = (o >>> 2 ^ a) & 858993459, a ^= s, o ^= s << 2, s = (o >>> 8 ^ a) & 16711935, a ^= s, o ^= s << 8, o = o << 1 | o >>> 31 & 1, s = (a ^ o) & 2863311530, a ^= s, o ^= s, a = a << 1 | a >>> 31 & 1;
          for (var y = 0, u = 0; y < 8; ++y) {
            s = o << 28 | o >>> 4, s ^= this.keys[u++];
            var l = Da[s & 63];
            l |= Ra[s >>> 8 & 63], l |= Ta[s >>> 16 & 63], l |= Aa[s >>> 24 & 63], s = o ^ this.keys[u++], l |= Oa[s & 63], l |= Ma[s >>> 8 & 63], l |= La[s >>> 16 & 63], l |= Pa[s >>> 24 & 63], a ^= l, s = a << 28 | a >>> 4, s ^= this.keys[u++], l = Da[s & 63], l |= Ra[s >>> 8 & 63], l |= Ta[s >>> 16 & 63], l |= Aa[s >>> 24 & 63], s = a ^ this.keys[u++], l |= Oa[s & 63], l |= Ma[s >>> 8 & 63], l |= La[s >>> 16 & 63], l |= Pa[s >>> 24 & 63], o ^= l;
          }
          for (o = o << 31 | o >>> 1, s = (a ^ o) & 2863311530, a ^= s, o ^= s, a = a << 31 | a >>> 1, s = (a >>> 8 ^ o) & 16711935, o ^= s, a ^= s << 8, s = (a >>> 2 ^ o) & 858993459, o ^= s, a ^= s << 2, s = (o >>> 16 ^ a) & 65535, a ^= s, o ^= s << 16, s = (o >>> 4 ^ a) & 252645135, a ^= s, o ^= s << 4, s = [
            o,
            a
          ], i = 0; i < 8; i++) r[i] = (s[i >>> 2] >>> 8 * (3 - i % 4)) % 256, r[i] < 0 && (r[i] += 256);
          return r;
        }
      }
    ]);
  }();
  yr.DESECBCipher = function() {
    function e() {
      mi(this, e), this._cipher = null;
    }
    return wi(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "DES-ECB"
          };
        }
      },
      {
        key: "_importKey",
        value: function(n, r, i) {
          this._cipher = new us(n);
        }
      },
      {
        key: "encrypt",
        value: function(n, r) {
          var i = new Uint8Array(r);
          if (i.length % 8 !== 0 || this._cipher === null) return null;
          for (var a = i.length / 8, o = 0; o < a; o++) i.set(this._cipher.enc8(i.slice(o * 8, o * 8 + 8)), o * 8);
          return i;
        }
      }
    ], [
      {
        key: "importKey",
        value: function(n, r, i, a) {
          var o = new e();
          return o._importKey(n), o;
        }
      }
    ]);
  }();
  yr.DESCBCCipher = function() {
    function e() {
      mi(this, e), this._cipher = null;
    }
    return wi(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "DES-CBC"
          };
        }
      },
      {
        key: "_importKey",
        value: function(n) {
          this._cipher = new us(n);
        }
      },
      {
        key: "encrypt",
        value: function(n, r) {
          var i = new Uint8Array(r), a = new Uint8Array(n.iv);
          if (i.length % 8 !== 0 || this._cipher === null) return null;
          for (var o = i.length / 8, s = 0; s < o; s++) {
            for (var y = 0; y < 8; y++) a[y] ^= r[s * 8 + y];
            a = this._cipher.enc8(a), i.set(a, s * 8);
          }
          return i;
        }
      }
    ], [
      {
        key: "importKey",
        value: function(n, r, i, a) {
          var o = new e();
          return o._importKey(n), o;
        }
      }
    ]);
  }();
  var mn = {}, wr = {};
  Object.defineProperty(wr, "__esModule", {
    value: true
  });
  wr.bigIntToU8Array = Ql;
  wr.modPow = Il;
  wr.u8ArrayToBigInt = Ul;
  function Il(e, t, n) {
    var r = 1n;
    for (e = e % n; t > 0n; ) (t & 1n) === 1n && (r = r * e % n), t = t >> 1n, e = e * e % n;
    return r;
  }
  function Ql(e) {
    var t = arguments.length > 1 && arguments[1] !== void 0 ? arguments[1] : 0, n = e.toString(16);
    t === 0 && (t = Math.ceil(n.length / 2)), n = n.padStart(t * 2, "0");
    for (var r = n.length / 2, i = new Uint8Array(r), a = 0; a < r; a++) i[a] = parseInt(n.slice(a * 2, a * 2 + 2), 16);
    return i;
  }
  function Ul(e) {
    for (var t = "0x", n = 0; n < e.length; n++) t += e[n].toString(16).padStart(2, "0");
    return BigInt(t);
  }
  Object.defineProperty(mn, "__esModule", {
    value: true
  });
  mn.RSACipher = void 0;
  var Nl = jl(yn), xt = wr;
  function jl(e) {
    return e && e.__esModule ? e : {
      default: e
    };
  }
  function ir(e) {
    "@babel/helpers - typeof";
    return ir = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, ir(e);
  }
  function tt() {
    tt = function() {
      return t;
    };
    var e, t = {}, n = Object.prototype, r = n.hasOwnProperty, i = Object.defineProperty || function(E, p, m) {
      E[p] = m.value;
    }, a = typeof Symbol == "function" ? Symbol : {}, o = a.iterator || "@@iterator", s = a.asyncIterator || "@@asyncIterator", y = a.toStringTag || "@@toStringTag";
    function u(E, p, m) {
      return Object.defineProperty(E, p, {
        value: m,
        enumerable: true,
        configurable: true,
        writable: true
      }), E[p];
    }
    try {
      u({}, "");
    } catch {
      u = function(m, L, B) {
        return m[L] = B;
      };
    }
    function l(E, p, m, L) {
      var B = p && p.prototype instanceof c ? p : c, M = Object.create(B.prototype), V = new $(L || []);
      return i(M, "_invoke", {
        value: O(E, m, V)
      }), M;
    }
    function k(E, p, m) {
      try {
        return {
          type: "normal",
          arg: E.call(p, m)
        };
      } catch (L) {
        return {
          type: "throw",
          arg: L
        };
      }
    }
    t.wrap = l;
    var X = "suspendedStart", g = "suspendedYield", b = "executing", d = "completed", f = {};
    function c() {
    }
    function h() {
    }
    function K() {
    }
    var x = {};
    u(x, o, function() {
      return this;
    });
    var F = Object.getPrototypeOf, S = F && F(F(ne([])));
    S && S !== n && r.call(S, o) && (x = S);
    var w = K.prototype = c.prototype = Object.create(x);
    function C(E) {
      [
        "next",
        "throw",
        "return"
      ].forEach(function(p) {
        u(E, p, function(m) {
          return this._invoke(p, m);
        });
      });
    }
    function A(E, p) {
      function m(B, M, V, re) {
        var oe = k(E[B], E, M);
        if (oe.type !== "throw") {
          var ce = oe.arg, pe = ce.value;
          return pe && ir(pe) == "object" && r.call(pe, "__await") ? p.resolve(pe.__await).then(function(ye) {
            m("next", ye, V, re);
          }, function(ye) {
            m("throw", ye, V, re);
          }) : p.resolve(pe).then(function(ye) {
            ce.value = ye, V(ce);
          }, function(ye) {
            return m("throw", ye, V, re);
          });
        }
        re(oe.arg);
      }
      var L;
      i(this, "_invoke", {
        value: function(M, V) {
          function re() {
            return new p(function(oe, ce) {
              m(M, V, oe, ce);
            });
          }
          return L = L ? L.then(re, re) : re();
        }
      });
    }
    function O(E, p, m) {
      var L = X;
      return function(B, M) {
        if (L === b) throw Error("Generator is already running");
        if (L === d) {
          if (B === "throw") throw M;
          return {
            value: e,
            done: true
          };
        }
        for (m.method = B, m.arg = M; ; ) {
          var V = m.delegate;
          if (V) {
            var re = I(V, m);
            if (re) {
              if (re === f) continue;
              return re;
            }
          }
          if (m.method === "next") m.sent = m._sent = m.arg;
          else if (m.method === "throw") {
            if (L === X) throw L = d, m.arg;
            m.dispatchException(m.arg);
          } else m.method === "return" && m.abrupt("return", m.arg);
          L = b;
          var oe = k(E, p, m);
          if (oe.type === "normal") {
            if (L = m.done ? d : g, oe.arg === f) continue;
            return {
              value: oe.arg,
              done: m.done
            };
          }
          oe.type === "throw" && (L = d, m.method = "throw", m.arg = oe.arg);
        }
      };
    }
    function I(E, p) {
      var m = p.method, L = E.iterator[m];
      if (L === e) return p.delegate = null, m === "throw" && E.iterator.return && (p.method = "return", p.arg = e, I(E, p), p.method === "throw") || m !== "return" && (p.method = "throw", p.arg = new TypeError("The iterator does not provide a '" + m + "' method")), f;
      var B = k(L, E.iterator, p.arg);
      if (B.type === "throw") return p.method = "throw", p.arg = B.arg, p.delegate = null, f;
      var M = B.arg;
      return M ? M.done ? (p[E.resultName] = M.value, p.next = E.nextLoc, p.method !== "return" && (p.method = "next", p.arg = e), p.delegate = null, f) : M : (p.method = "throw", p.arg = new TypeError("iterator result is not an object"), p.delegate = null, f);
    }
    function Z(E) {
      var p = {
        tryLoc: E[0]
      };
      1 in E && (p.catchLoc = E[1]), 2 in E && (p.finallyLoc = E[2], p.afterLoc = E[3]), this.tryEntries.push(p);
    }
    function q(E) {
      var p = E.completion || {};
      p.type = "normal", delete p.arg, E.completion = p;
    }
    function $(E) {
      this.tryEntries = [
        {
          tryLoc: "root"
        }
      ], E.forEach(Z, this), this.reset(true);
    }
    function ne(E) {
      if (E || E === "") {
        var p = E[o];
        if (p) return p.call(E);
        if (typeof E.next == "function") return E;
        if (!isNaN(E.length)) {
          var m = -1, L = function B() {
            for (; ++m < E.length; ) if (r.call(E, m)) return B.value = E[m], B.done = false, B;
            return B.value = e, B.done = true, B;
          };
          return L.next = L;
        }
      }
      throw new TypeError(ir(E) + " is not iterable");
    }
    return h.prototype = K, i(w, "constructor", {
      value: K,
      configurable: true
    }), i(K, "constructor", {
      value: h,
      configurable: true
    }), h.displayName = u(K, y, "GeneratorFunction"), t.isGeneratorFunction = function(E) {
      var p = typeof E == "function" && E.constructor;
      return !!p && (p === h || (p.displayName || p.name) === "GeneratorFunction");
    }, t.mark = function(E) {
      return Object.setPrototypeOf ? Object.setPrototypeOf(E, K) : (E.__proto__ = K, u(E, y, "GeneratorFunction")), E.prototype = Object.create(w), E;
    }, t.awrap = function(E) {
      return {
        __await: E
      };
    }, C(A.prototype), u(A.prototype, s, function() {
      return this;
    }), t.AsyncIterator = A, t.async = function(E, p, m, L, B) {
      B === void 0 && (B = Promise);
      var M = new A(l(E, p, m, L), B);
      return t.isGeneratorFunction(p) ? M : M.next().then(function(V) {
        return V.done ? V.value : M.next();
      });
    }, C(w), u(w, y, "Generator"), u(w, o, function() {
      return this;
    }), u(w, "toString", function() {
      return "[object Generator]";
    }), t.keys = function(E) {
      var p = Object(E), m = [];
      for (var L in p) m.push(L);
      return m.reverse(), function B() {
        for (; m.length; ) {
          var M = m.pop();
          if (M in p) return B.value = M, B.done = false, B;
        }
        return B.done = true, B;
      };
    }, t.values = ne, $.prototype = {
      constructor: $,
      reset: function(p) {
        if (this.prev = 0, this.next = 0, this.sent = this._sent = e, this.done = false, this.delegate = null, this.method = "next", this.arg = e, this.tryEntries.forEach(q), !p) for (var m in this) m.charAt(0) === "t" && r.call(this, m) && !isNaN(+m.slice(1)) && (this[m] = e);
      },
      stop: function() {
        this.done = true;
        var p = this.tryEntries[0].completion;
        if (p.type === "throw") throw p.arg;
        return this.rval;
      },
      dispatchException: function(p) {
        if (this.done) throw p;
        var m = this;
        function L(ce, pe) {
          return V.type = "throw", V.arg = p, m.next = ce, pe && (m.method = "next", m.arg = e), !!pe;
        }
        for (var B = this.tryEntries.length - 1; B >= 0; --B) {
          var M = this.tryEntries[B], V = M.completion;
          if (M.tryLoc === "root") return L("end");
          if (M.tryLoc <= this.prev) {
            var re = r.call(M, "catchLoc"), oe = r.call(M, "finallyLoc");
            if (re && oe) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            } else if (re) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
            } else {
              if (!oe) throw Error("try statement without catch or finally");
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            }
          }
        }
      },
      abrupt: function(p, m) {
        for (var L = this.tryEntries.length - 1; L >= 0; --L) {
          var B = this.tryEntries[L];
          if (B.tryLoc <= this.prev && r.call(B, "finallyLoc") && this.prev < B.finallyLoc) {
            var M = B;
            break;
          }
        }
        M && (p === "break" || p === "continue") && M.tryLoc <= m && m <= M.finallyLoc && (M = null);
        var V = M ? M.completion : {};
        return V.type = p, V.arg = m, M ? (this.method = "next", this.next = M.finallyLoc, f) : this.complete(V);
      },
      complete: function(p, m) {
        if (p.type === "throw") throw p.arg;
        return p.type === "break" || p.type === "continue" ? this.next = p.arg : p.type === "return" ? (this.rval = this.arg = p.arg, this.method = "return", this.next = "end") : p.type === "normal" && m && (this.next = m), f;
      },
      finish: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.finallyLoc === p) return this.complete(L.completion, L.afterLoc), q(L), f;
        }
      },
      catch: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.tryLoc === p) {
            var B = L.completion;
            if (B.type === "throw") {
              var M = B.arg;
              q(L);
            }
            return M;
          }
        }
        throw Error("illegal catch attempt");
      },
      delegateYield: function(p, m, L) {
        return this.delegate = {
          iterator: ne(p),
          resultName: m,
          nextLoc: L
        }, this.method === "next" && (this.arg = e), f;
      }
    }, t;
  }
  function Ba(e, t, n, r, i, a, o) {
    try {
      var s = e[a](o), y = s.value;
    } catch (u) {
      return void n(u);
    }
    s.done ? t(y) : Promise.resolve(y).then(r, i);
  }
  function Vt(e) {
    return function() {
      var t = this, n = arguments;
      return new Promise(function(r, i) {
        var a = e.apply(t, n);
        function o(y) {
          Ba(a, r, i, o, s, "next", y);
        }
        function s(y) {
          Ba(a, r, i, o, s, "throw", y);
        }
        o(void 0);
      });
    };
  }
  function Hl(e, t) {
    if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
  }
  function Ia(e, t) {
    for (var n = 0; n < t.length; n++) {
      var r = t[n];
      r.enumerable = r.enumerable || false, r.configurable = true, "value" in r && (r.writable = true), Object.defineProperty(e, zl(r.key), r);
    }
  }
  function Wl(e, t, n) {
    return t && Ia(e.prototype, t), n && Ia(e, n), Object.defineProperty(e, "prototype", {
      writable: false
    }), e;
  }
  function zl(e) {
    var t = Gl(e, "string");
    return ir(t) == "symbol" ? t : t + "";
  }
  function Gl(e, t) {
    if (ir(e) != "object" || !e) return e;
    var n = e[Symbol.toPrimitive];
    if (n !== void 0) {
      var r = n.call(e, t);
      if (ir(r) != "object") return r;
      throw new TypeError("@@toPrimitive must return a primitive value.");
    }
    return String(e);
  }
  mn.RSACipher = function() {
    function e() {
      Hl(this, e), this._keyLength = 0, this._keyBytes = 0, this._n = null, this._e = null, this._d = null, this._nBigInt = null, this._eBigInt = null, this._dBigInt = null, this._extractable = false;
    }
    return Wl(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "RSA-PKCS1-v1_5"
          };
        }
      },
      {
        key: "_base64urlDecode",
        value: function(n) {
          return n = n.replace(/-/g, "+").replace(/_/g, "/"), n = n.padEnd(Math.ceil(n.length / 4) * 4, "="), Nl.default.decode(n);
        }
      },
      {
        key: "_padArray",
        value: function(n, r) {
          var i = new Uint8Array(r);
          return i.set(n, r - n.length), i;
        }
      },
      {
        key: "_generateKey",
        value: function() {
          var t = Vt(tt().mark(function r(i, a) {
            var o, s;
            return tt().wrap(function(u) {
              for (; ; ) switch (u.prev = u.next) {
                case 0:
                  return this._keyLength = i.modulusLength, this._keyBytes = Math.ceil(this._keyLength / 8), u.next = 4, window.crypto.subtle.generateKey({
                    name: "RSA-OAEP",
                    modulusLength: i.modulusLength,
                    publicExponent: i.publicExponent,
                    hash: {
                      name: "SHA-256"
                    }
                  }, true, [
                    "encrypt",
                    "decrypt"
                  ]);
                case 4:
                  return o = u.sent, u.next = 7, window.crypto.subtle.exportKey("jwk", o.privateKey);
                case 7:
                  s = u.sent, this._n = this._padArray(this._base64urlDecode(s.n), this._keyBytes), this._nBigInt = (0, xt.u8ArrayToBigInt)(this._n), this._e = this._padArray(this._base64urlDecode(s.e), this._keyBytes), this._eBigInt = (0, xt.u8ArrayToBigInt)(this._e), this._d = this._padArray(this._base64urlDecode(s.d), this._keyBytes), this._dBigInt = (0, xt.u8ArrayToBigInt)(this._d), this._extractable = a;
                case 15:
                case "end":
                  return u.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "_importKey",
        value: function() {
          var t = Vt(tt().mark(function r(i, a) {
            var o, s;
            return tt().wrap(function(u) {
              for (; ; ) switch (u.prev = u.next) {
                case 0:
                  if (o = i.n, s = i.e, o.length === s.length) {
                    u.next = 4;
                    break;
                  }
                  throw new Error("the sizes of modulus and public exponent do not match");
                case 4:
                  this._keyBytes = o.length, this._keyLength = this._keyBytes * 8, this._n = new Uint8Array(this._keyBytes), this._e = new Uint8Array(this._keyBytes), this._n.set(o), this._e.set(s), this._nBigInt = (0, xt.u8ArrayToBigInt)(this._n), this._eBigInt = (0, xt.u8ArrayToBigInt)(this._e), this._extractable = a;
                case 13:
                case "end":
                  return u.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "encrypt",
        value: function() {
          var t = Vt(tt().mark(function r(i, a) {
            var o, s, y, u, l;
            return tt().wrap(function(X) {
              for (; ; ) switch (X.prev = X.next) {
                case 0:
                  if (!(a.length > this._keyBytes - 11)) {
                    X.next = 2;
                    break;
                  }
                  return X.abrupt("return", null);
                case 2:
                  for (o = new Uint8Array(this._keyBytes - a.length - 3), window.crypto.getRandomValues(o), s = 0; s < o.length; s++) o[s] = Math.floor(o[s] * 254 / 255 + 1);
                  return y = new Uint8Array(this._keyBytes), y[1] = 2, y.set(o, 2), y.set(a, o.length + 3), u = (0, xt.u8ArrayToBigInt)(y), l = (0, xt.modPow)(u, this._eBigInt, this._nBigInt), X.abrupt("return", (0, xt.bigIntToU8Array)(l, this._keyBytes));
                case 12:
                case "end":
                  return X.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "decrypt",
        value: function() {
          var t = Vt(tt().mark(function r(i, a) {
            var o, s, y, u;
            return tt().wrap(function(k) {
              for (; ; ) switch (k.prev = k.next) {
                case 0:
                  if (a.length === this._keyBytes) {
                    k.next = 2;
                    break;
                  }
                  return k.abrupt("return", null);
                case 2:
                  if (o = (0, xt.u8ArrayToBigInt)(a), s = (0, xt.modPow)(o, this._dBigInt, this._nBigInt), y = (0, xt.bigIntToU8Array)(s, this._keyBytes), !(y[0] !== 0 || y[1] !== 2)) {
                    k.next = 7;
                    break;
                  }
                  return k.abrupt("return", null);
                case 7:
                  u = 2;
                case 8:
                  if (!(u < y.length)) {
                    k.next = 14;
                    break;
                  }
                  if (y[u] !== 0) {
                    k.next = 11;
                    break;
                  }
                  return k.abrupt("break", 14);
                case 11:
                  u++, k.next = 8;
                  break;
                case 14:
                  if (u !== y.length) {
                    k.next = 16;
                    break;
                  }
                  return k.abrupt("return", null);
                case 16:
                  return k.abrupt("return", y.slice(u + 1, y.length));
                case 17:
                case "end":
                  return k.stop();
              }
            }, r, this);
          }));
          function n(r, i) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "exportKey",
        value: function() {
          var t = Vt(tt().mark(function r() {
            return tt().wrap(function(a) {
              for (; ; ) switch (a.prev = a.next) {
                case 0:
                  if (this._extractable) {
                    a.next = 2;
                    break;
                  }
                  throw new Error("key is not extractable");
                case 2:
                  return a.abrupt("return", {
                    n: this._n,
                    e: this._e,
                    d: this._d
                  });
                case 3:
                case "end":
                  return a.stop();
              }
            }, r, this);
          }));
          function n() {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ], [
      {
        key: "generateKey",
        value: function() {
          var t = Vt(tt().mark(function r(i, a, o) {
            var s;
            return tt().wrap(function(u) {
              for (; ; ) switch (u.prev = u.next) {
                case 0:
                  return s = new e(), u.next = 3, s._generateKey(i, a);
                case 3:
                  return u.abrupt("return", {
                    privateKey: s
                  });
                case 4:
                case "end":
                  return u.stop();
              }
            }, r);
          }));
          function n(r, i, a) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      },
      {
        key: "importKey",
        value: function() {
          var t = Vt(tt().mark(function r(i, a, o, s) {
            var y;
            return tt().wrap(function(l) {
              for (; ; ) switch (l.prev = l.next) {
                case 0:
                  if (!(s.length !== 1 || s[0] !== "encrypt")) {
                    l.next = 2;
                    break;
                  }
                  throw new Error("only support importing RSA public key");
                case 2:
                  return y = new e(), l.next = 5, y._importKey(i, o);
                case 5:
                  return l.abrupt("return", y);
                case 6:
                case "end":
                  return l.stop();
              }
            }, r);
          }));
          function n(r, i, a, o) {
            return t.apply(this, arguments);
          }
          return n;
        }()
      }
    ]);
  }();
  var wn = {};
  Object.defineProperty(wn, "__esModule", {
    value: true
  });
  wn.DHCipher = void 0;
  var Mt = wr;
  function Qr(e) {
    "@babel/helpers - typeof";
    return Qr = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, Qr(e);
  }
  function ls(e, t) {
    if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
  }
  function Qa(e, t) {
    for (var n = 0; n < t.length; n++) {
      var r = t[n];
      r.enumerable = r.enumerable || false, r.configurable = true, "value" in r && (r.writable = true), Object.defineProperty(e, Vl(r.key), r);
    }
  }
  function fs(e, t, n) {
    return t && Qa(e.prototype, t), n && Qa(e, n), Object.defineProperty(e, "prototype", {
      writable: false
    }), e;
  }
  function Vl(e) {
    var t = Zl(e, "string");
    return Qr(t) == "symbol" ? t : t + "";
  }
  function Zl(e, t) {
    if (Qr(e) != "object" || !e) return e;
    var n = e[Symbol.toPrimitive];
    if (n !== void 0) {
      var r = n.call(e, t);
      if (Qr(r) != "object") return r;
      throw new TypeError("@@toPrimitive must return a primitive value.");
    }
    return String(e);
  }
  var ql = function() {
    function e(t) {
      ls(this, e), this._key = t;
    }
    return fs(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "DH"
          };
        }
      },
      {
        key: "exportKey",
        value: function() {
          return this._key;
        }
      }
    ]);
  }();
  wn.DHCipher = function() {
    function e() {
      ls(this, e), this._g = null, this._p = null, this._gBigInt = null, this._pBigInt = null, this._privateKey = null;
    }
    return fs(e, [
      {
        key: "algorithm",
        get: function() {
          return {
            name: "DH"
          };
        }
      },
      {
        key: "_generateKey",
        value: function(n) {
          var r = n.g, i = n.p;
          this._keyBytes = i.length, this._gBigInt = (0, Mt.u8ArrayToBigInt)(r), this._pBigInt = (0, Mt.u8ArrayToBigInt)(i), this._privateKey = window.crypto.getRandomValues(new Uint8Array(this._keyBytes)), this._privateKeyBigInt = (0, Mt.u8ArrayToBigInt)(this._privateKey), this._publicKey = (0, Mt.bigIntToU8Array)((0, Mt.modPow)(this._gBigInt, this._privateKeyBigInt, this._pBigInt), this._keyBytes);
        }
      },
      {
        key: "deriveBits",
        value: function(n, r) {
          var i = Math.ceil(r / 8), a = new Uint8Array(n.public), o = i > this._keyBytes ? i : this._keyBytes, s = (0, Mt.modPow)((0, Mt.u8ArrayToBigInt)(a), this._privateKeyBigInt, this._pBigInt);
          return (0, Mt.bigIntToU8Array)(s, o).slice(0, o);
        }
      }
    ], [
      {
        key: "generateKey",
        value: function(n, r) {
          var i = new e();
          return i._generateKey(n), {
            privateKey: i,
            publicKey: new ql(i._publicKey)
          };
        }
      }
    ]);
  }();
  var ki = {};
  Object.defineProperty(ki, "__esModule", {
    value: true
  });
  ki.MD5 = $l;
  function pn(e) {
    "@babel/helpers - typeof";
    return pn = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(t) {
      return typeof t;
    } : function(t) {
      return t && typeof Symbol == "function" && t.constructor === Symbol && t !== Symbol.prototype ? "symbol" : typeof t;
    }, pn(e);
  }
  function ni() {
    ni = function() {
      return t;
    };
    var e, t = {}, n = Object.prototype, r = n.hasOwnProperty, i = Object.defineProperty || function(E, p, m) {
      E[p] = m.value;
    }, a = typeof Symbol == "function" ? Symbol : {}, o = a.iterator || "@@iterator", s = a.asyncIterator || "@@asyncIterator", y = a.toStringTag || "@@toStringTag";
    function u(E, p, m) {
      return Object.defineProperty(E, p, {
        value: m,
        enumerable: true,
        configurable: true,
        writable: true
      }), E[p];
    }
    try {
      u({}, "");
    } catch {
      u = function(m, L, B) {
        return m[L] = B;
      };
    }
    function l(E, p, m, L) {
      var B = p && p.prototype instanceof c ? p : c, M = Object.create(B.prototype), V = new $(L || []);
      return i(M, "_invoke", {
        value: O(E, m, V)
      }), M;
    }
    function k(E, p, m) {
      try {
        return {
          type: "normal",
          arg: E.call(p, m)
        };
      } catch (L) {
        return {
          type: "throw",
          arg: L
        };
      }
    }
    t.wrap = l;
    var X = "suspendedStart", g = "suspendedYield", b = "executing", d = "completed", f = {};
    function c() {
    }
    function h() {
    }
    function K() {
    }
    var x = {};
    u(x, o, function() {
      return this;
    });
    var F = Object.getPrototypeOf, S = F && F(F(ne([])));
    S && S !== n && r.call(S, o) && (x = S);
    var w = K.prototype = c.prototype = Object.create(x);
    function C(E) {
      [
        "next",
        "throw",
        "return"
      ].forEach(function(p) {
        u(E, p, function(m) {
          return this._invoke(p, m);
        });
      });
    }
    function A(E, p) {
      function m(B, M, V, re) {
        var oe = k(E[B], E, M);
        if (oe.type !== "throw") {
          var ce = oe.arg, pe = ce.value;
          return pe && pn(pe) == "object" && r.call(pe, "__await") ? p.resolve(pe.__await).then(function(ye) {
            m("next", ye, V, re);
          }, function(ye) {
            m("throw", ye, V, re);
          }) : p.resolve(pe).then(function(ye) {
            ce.value = ye, V(ce);
          }, function(ye) {
            return m("throw", ye, V, re);
          });
        }
        re(oe.arg);
      }
      var L;
      i(this, "_invoke", {
        value: function(M, V) {
          function re() {
            return new p(function(oe, ce) {
              m(M, V, oe, ce);
            });
          }
          return L = L ? L.then(re, re) : re();
        }
      });
    }
    function O(E, p, m) {
      var L = X;
      return function(B, M) {
        if (L === b) throw Error("Generator is already running");
        if (L === d) {
          if (B === "throw") throw M;
          return {
            value: e,
            done: true
          };
        }
        for (m.method = B, m.arg = M; ; ) {
          var V = m.delegate;
          if (V) {
            var re = I(V, m);
            if (re) {
              if (re === f) continue;
              return re;
            }
          }
          if (m.method === "next") m.sent = m._sent = m.arg;
          else if (m.method === "throw") {
            if (L === X) throw L = d, m.arg;
            m.dispatchException(m.arg);
          } else m.method === "return" && m.abrupt("return", m.arg);
          L = b;
          var oe = k(E, p, m);
          if (oe.type === "normal") {
            if (L = m.done ? d : g, oe.arg === f) continue;
            return {
              value: oe.arg,
              done: m.done
            };
          }
          oe.type === "throw" && (L = d, m.method = "throw", m.arg = oe.arg);
        }
      };
    }
    function I(E, p) {
      var m = p.method, L = E.iterator[m];
      if (L === e) return p.delegate = null, m === "throw" && E.iterator.return && (p.method = "return", p.arg = e, I(E, p), p.method === "throw") || m !== "return" && (p.method = "throw", p.arg = new TypeError("The iterator does not provide a '" + m + "' method")), f;
      var B = k(L, E.iterator, p.arg);
      if (B.type === "throw") return p.method = "throw", p.arg = B.arg, p.delegate = null, f;
      var M = B.arg;
      return M ? M.done ? (p[E.resultName] = M.value, p.next = E.nextLoc, p.method !== "return" && (p.method = "next", p.arg = e), p.delegate = null, f) : M : (p.method = "throw", p.arg = new TypeError("iterator result is not an object"), p.delegate = null, f);
    }
    function Z(E) {
      var p = {
        tryLoc: E[0]
      };
      1 in E && (p.catchLoc = E[1]), 2 in E && (p.finallyLoc = E[2], p.afterLoc = E[3]), this.tryEntries.push(p);
    }
    function q(E) {
      var p = E.completion || {};
      p.type = "normal", delete p.arg, E.completion = p;
    }
    function $(E) {
      this.tryEntries = [
        {
          tryLoc: "root"
        }
      ], E.forEach(Z, this), this.reset(true);
    }
    function ne(E) {
      if (E || E === "") {
        var p = E[o];
        if (p) return p.call(E);
        if (typeof E.next == "function") return E;
        if (!isNaN(E.length)) {
          var m = -1, L = function B() {
            for (; ++m < E.length; ) if (r.call(E, m)) return B.value = E[m], B.done = false, B;
            return B.value = e, B.done = true, B;
          };
          return L.next = L;
        }
      }
      throw new TypeError(pn(E) + " is not iterable");
    }
    return h.prototype = K, i(w, "constructor", {
      value: K,
      configurable: true
    }), i(K, "constructor", {
      value: h,
      configurable: true
    }), h.displayName = u(K, y, "GeneratorFunction"), t.isGeneratorFunction = function(E) {
      var p = typeof E == "function" && E.constructor;
      return !!p && (p === h || (p.displayName || p.name) === "GeneratorFunction");
    }, t.mark = function(E) {
      return Object.setPrototypeOf ? Object.setPrototypeOf(E, K) : (E.__proto__ = K, u(E, y, "GeneratorFunction")), E.prototype = Object.create(w), E;
    }, t.awrap = function(E) {
      return {
        __await: E
      };
    }, C(A.prototype), u(A.prototype, s, function() {
      return this;
    }), t.AsyncIterator = A, t.async = function(E, p, m, L, B) {
      B === void 0 && (B = Promise);
      var M = new A(l(E, p, m, L), B);
      return t.isGeneratorFunction(p) ? M : M.next().then(function(V) {
        return V.done ? V.value : M.next();
      });
    }, C(w), u(w, y, "Generator"), u(w, o, function() {
      return this;
    }), u(w, "toString", function() {
      return "[object Generator]";
    }), t.keys = function(E) {
      var p = Object(E), m = [];
      for (var L in p) m.push(L);
      return m.reverse(), function B() {
        for (; m.length; ) {
          var M = m.pop();
          if (M in p) return B.value = M, B.done = false, B;
        }
        return B.done = true, B;
      };
    }, t.values = ne, $.prototype = {
      constructor: $,
      reset: function(p) {
        if (this.prev = 0, this.next = 0, this.sent = this._sent = e, this.done = false, this.delegate = null, this.method = "next", this.arg = e, this.tryEntries.forEach(q), !p) for (var m in this) m.charAt(0) === "t" && r.call(this, m) && !isNaN(+m.slice(1)) && (this[m] = e);
      },
      stop: function() {
        this.done = true;
        var p = this.tryEntries[0].completion;
        if (p.type === "throw") throw p.arg;
        return this.rval;
      },
      dispatchException: function(p) {
        if (this.done) throw p;
        var m = this;
        function L(ce, pe) {
          return V.type = "throw", V.arg = p, m.next = ce, pe && (m.method = "next", m.arg = e), !!pe;
        }
        for (var B = this.tryEntries.length - 1; B >= 0; --B) {
          var M = this.tryEntries[B], V = M.completion;
          if (M.tryLoc === "root") return L("end");
          if (M.tryLoc <= this.prev) {
            var re = r.call(M, "catchLoc"), oe = r.call(M, "finallyLoc");
            if (re && oe) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            } else if (re) {
              if (this.prev < M.catchLoc) return L(M.catchLoc, true);
            } else {
              if (!oe) throw Error("try statement without catch or finally");
              if (this.prev < M.finallyLoc) return L(M.finallyLoc);
            }
          }
        }
      },
      abrupt: function(p, m) {
        for (var L = this.tryEntries.length - 1; L >= 0; --L) {
          var B = this.tryEntries[L];
          if (B.tryLoc <= this.prev && r.call(B, "finallyLoc") && this.prev < B.finallyLoc) {
            var M = B;
            break;
          }
        }
        M && (p === "break" || p === "continue") && M.tryLoc <= m && m <= M.finallyLoc && (M = null);
        var V = M ? M.completion : {};
        return V.type = p, V.arg = m, M ? (this.method = "next", this.next = M.finallyLoc, f) : this.complete(V);
      },
      complete: function(p, m) {
        if (p.type === "throw") throw p.arg;
        return p.type === "break" || p.type === "continue" ? this.next = p.arg : p.type === "return" ? (this.rval = this.arg = p.arg, this.method = "return", this.next = "end") : p.type === "normal" && m && (this.next = m), f;
      },
      finish: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.finallyLoc === p) return this.complete(L.completion, L.afterLoc), q(L), f;
        }
      },
      catch: function(p) {
        for (var m = this.tryEntries.length - 1; m >= 0; --m) {
          var L = this.tryEntries[m];
          if (L.tryLoc === p) {
            var B = L.completion;
            if (B.type === "throw") {
              var M = B.arg;
              q(L);
            }
            return M;
          }
        }
        throw Error("illegal catch attempt");
      },
      delegateYield: function(p, m, L) {
        return this.delegate = {
          iterator: ne(p),
          resultName: m,
          nextLoc: L
        }, this.method === "next" && (this.arg = e), f;
      }
    }, t;
  }
  function Ua(e, t, n, r, i, a, o) {
    try {
      var s = e[a](o), y = s.value;
    } catch (u) {
      return void n(u);
    }
    s.done ? t(y) : Promise.resolve(y).then(r, i);
  }
  function Yl(e) {
    return function() {
      var t = this, n = arguments;
      return new Promise(function(r, i) {
        var a = e.apply(t, n);
        function o(y) {
          Ua(a, r, i, o, s, "next", y);
        }
        function s(y) {
          Ua(a, r, i, o, s, "throw", y);
        }
        o(void 0);
      });
    };
  }
  function $l(e) {
    return ii.apply(this, arguments);
  }
  function ii() {
    return ii = Yl(ni().mark(function e(t) {
      var n, r;
      return ni().wrap(function(a) {
        for (; ; ) switch (a.prev = a.next) {
          case 0:
            for (n = "", r = 0; r < t.length; r++) n += String.fromCharCode(t[r]);
            return a.abrupt("return", Jl(tf(rf(ef(n), 8 * n.length))));
          case 3:
          case "end":
            return a.stop();
        }
      }, e);
    })), ii.apply(this, arguments);
  }
  function Jl(e) {
    for (var t = new Uint8Array(e.length), n = 0; n < e.length; n++) t[n] = e.charCodeAt(n);
    return t;
  }
  function ef(e) {
    for (var t = Array(e.length >> 2), n = 0; n < t.length; n++) t[n] = 0;
    for (var r = 0; r < 8 * e.length; r += 8) t[r >> 5] |= (255 & e.charCodeAt(r / 8)) << r % 32;
    return t;
  }
  function tf(e) {
    for (var t = "", n = 0; n < 32 * e.length; n += 8) t += String.fromCharCode(e[n >> 5] >>> n % 32 & 255);
    return t;
  }
  function rf(e, t) {
    e[t >> 5] |= 128 << t % 32, e[14 + (t + 64 >>> 9 << 4)] = t;
    for (var n = 1732584193, r = -271733879, i = -1732584194, a = 271733878, o = 0; o < e.length; o += 16) {
      var s = n, y = r, u = i, l = a;
      r = $e(r = $e(r = $e(r = $e(r = Ye(r = Ye(r = Ye(r = Ye(r = qe(r = qe(r = qe(r = qe(r = Ze(r = Ze(r = Ze(r = Ze(r, i = Ze(i, a = Ze(a, n = Ze(n, r, i, a, e[o + 0], 7, -680876936), r, i, e[o + 1], 12, -389564586), n, r, e[o + 2], 17, 606105819), a, n, e[o + 3], 22, -1044525330), i = Ze(i, a = Ze(a, n = Ze(n, r, i, a, e[o + 4], 7, -176418897), r, i, e[o + 5], 12, 1200080426), n, r, e[o + 6], 17, -1473231341), a, n, e[o + 7], 22, -45705983), i = Ze(i, a = Ze(a, n = Ze(n, r, i, a, e[o + 8], 7, 1770035416), r, i, e[o + 9], 12, -1958414417), n, r, e[o + 10], 17, -42063), a, n, e[o + 11], 22, -1990404162), i = Ze(i, a = Ze(a, n = Ze(n, r, i, a, e[o + 12], 7, 1804603682), r, i, e[o + 13], 12, -40341101), n, r, e[o + 14], 17, -1502002290), a, n, e[o + 15], 22, 1236535329), i = qe(i, a = qe(a, n = qe(n, r, i, a, e[o + 1], 5, -165796510), r, i, e[o + 6], 9, -1069501632), n, r, e[o + 11], 14, 643717713), a, n, e[o + 0], 20, -373897302), i = qe(i, a = qe(a, n = qe(n, r, i, a, e[o + 5], 5, -701558691), r, i, e[o + 10], 9, 38016083), n, r, e[o + 15], 14, -660478335), a, n, e[o + 4], 20, -405537848), i = qe(i, a = qe(a, n = qe(n, r, i, a, e[o + 9], 5, 568446438), r, i, e[o + 14], 9, -1019803690), n, r, e[o + 3], 14, -187363961), a, n, e[o + 8], 20, 1163531501), i = qe(i, a = qe(a, n = qe(n, r, i, a, e[o + 13], 5, -1444681467), r, i, e[o + 2], 9, -51403784), n, r, e[o + 7], 14, 1735328473), a, n, e[o + 12], 20, -1926607734), i = Ye(i, a = Ye(a, n = Ye(n, r, i, a, e[o + 5], 4, -378558), r, i, e[o + 8], 11, -2022574463), n, r, e[o + 11], 16, 1839030562), a, n, e[o + 14], 23, -35309556), i = Ye(i, a = Ye(a, n = Ye(n, r, i, a, e[o + 1], 4, -1530992060), r, i, e[o + 4], 11, 1272893353), n, r, e[o + 7], 16, -155497632), a, n, e[o + 10], 23, -1094730640), i = Ye(i, a = Ye(a, n = Ye(n, r, i, a, e[o + 13], 4, 681279174), r, i, e[o + 0], 11, -358537222), n, r, e[o + 3], 16, -722521979), a, n, e[o + 6], 23, 76029189), i = Ye(i, a = Ye(a, n = Ye(n, r, i, a, e[o + 9], 4, -640364487), r, i, e[o + 12], 11, -421815835), n, r, e[o + 15], 16, 530742520), a, n, e[o + 2], 23, -995338651), i = $e(i, a = $e(a, n = $e(n, r, i, a, e[o + 0], 6, -198630844), r, i, e[o + 7], 10, 1126891415), n, r, e[o + 14], 15, -1416354905), a, n, e[o + 5], 21, -57434055), i = $e(i, a = $e(a, n = $e(n, r, i, a, e[o + 12], 6, 1700485571), r, i, e[o + 3], 10, -1894986606), n, r, e[o + 10], 15, -1051523), a, n, e[o + 1], 21, -2054922799), i = $e(i, a = $e(a, n = $e(n, r, i, a, e[o + 8], 6, 1873313359), r, i, e[o + 15], 10, -30611744), n, r, e[o + 6], 15, -1560198380), a, n, e[o + 13], 21, 1309151649), i = $e(i, a = $e(a, n = $e(n, r, i, a, e[o + 4], 6, -145523070), r, i, e[o + 11], 10, -1120210379), n, r, e[o + 2], 15, 718787259), a, n, e[o + 9], 21, -343485551), n = Ut(n, s), r = Ut(r, y), i = Ut(i, u), a = Ut(a, l);
    }
    return Array(n, r, i, a);
  }
  function kn(e, t, n, r, i, a) {
    return Ut(nf(Ut(Ut(t, e), Ut(r, a)), i), n);
  }
  function Ze(e, t, n, r, i, a, o) {
    return kn(t & n | ~t & r, e, t, i, a, o);
  }
  function qe(e, t, n, r, i, a, o) {
    return kn(t & r | n & ~r, e, t, i, a, o);
  }
  function Ye(e, t, n, r, i, a, o) {
    return kn(t ^ n ^ r, e, t, i, a, o);
  }
  function $e(e, t, n, r, i, a, o) {
    return kn(n ^ (t | ~r), e, t, i, a, o);
  }
  function Ut(e, t) {
    var n = (65535 & e) + (65535 & t);
    return (e >> 16) + (t >> 16) + (n >> 16) << 16 | 65535 & n;
  }
  function nf(e, t) {
    return e << t | e >>> 32 - t;
  }
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = vr, n = yr, r = mn, i = wn, a = ki;
    function o(g) {
      "@babel/helpers - typeof";
      return o = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(b) {
        return typeof b;
      } : function(b) {
        return b && typeof Symbol == "function" && b.constructor === Symbol && b !== Symbol.prototype ? "symbol" : typeof b;
      }, o(g);
    }
    function s(g, b) {
      if (!(g instanceof b)) throw new TypeError("Cannot call a class as a function");
    }
    function y(g, b) {
      for (var d = 0; d < b.length; d++) {
        var f = b[d];
        f.enumerable = f.enumerable || false, f.configurable = true, "value" in f && (f.writable = true), Object.defineProperty(g, l(f.key), f);
      }
    }
    function u(g, b, d) {
      return b && y(g.prototype, b), Object.defineProperty(g, "prototype", {
        writable: false
      }), g;
    }
    function l(g) {
      var b = k(g, "string");
      return o(b) == "symbol" ? b : b + "";
    }
    function k(g, b) {
      if (o(g) != "object" || !g) return g;
      var d = g[Symbol.toPrimitive];
      if (d !== void 0) {
        var f = d.call(g, b);
        if (o(f) != "object") return f;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(g);
    }
    var X = function() {
      function g() {
        s(this, g), this._algorithms = {
          "AES-ECB": t.AESECBCipher,
          "AES-EAX": t.AESEAXCipher,
          "DES-ECB": n.DESECBCipher,
          "DES-CBC": n.DESCBCCipher,
          "RSA-PKCS1-v1_5": r.RSACipher,
          DH: i.DHCipher,
          MD5: a.MD5
        };
      }
      return u(g, [
        {
          key: "encrypt",
          value: function(d, f, c) {
            if (f.algorithm.name !== d.name) throw new Error("algorithm does not match");
            if (typeof f.encrypt != "function") throw new Error("key does not support encryption");
            return f.encrypt(d, c);
          }
        },
        {
          key: "decrypt",
          value: function(d, f, c) {
            if (f.algorithm.name !== d.name) throw new Error("algorithm does not match");
            if (typeof f.decrypt != "function") throw new Error("key does not support encryption");
            return f.decrypt(d, c);
          }
        },
        {
          key: "importKey",
          value: function(d, f, c, h, K) {
            if (d !== "raw") throw new Error("key format is not supported");
            var x = this._algorithms[c.name];
            if (typeof x > "u" || typeof x.importKey != "function") throw new Error("algorithm is not supported");
            return x.importKey(f, c, h, K);
          }
        },
        {
          key: "generateKey",
          value: function(d, f, c) {
            var h = this._algorithms[d.name];
            if (typeof h > "u" || typeof h.generateKey != "function") throw new Error("algorithm is not supported");
            return h.generateKey(d, f, c);
          }
        },
        {
          key: "exportKey",
          value: function(d, f) {
            if (d !== "raw") throw new Error("key format is not supported");
            if (typeof f.exportKey != "function") throw new Error("key does not support exportKey");
            return f.exportKey();
          }
        },
        {
          key: "digest",
          value: function(d, f) {
            var c = this._algorithms[d];
            if (typeof c != "function") throw new Error("algorithm is not supported");
            return c(f);
          }
        },
        {
          key: "deriveBits",
          value: function(d, f, c) {
            if (f.algorithm.name !== d.name) throw new Error("algorithm does not match");
            if (typeof f.deriveBits != "function") throw new Error("key does not support deriveBits");
            return f.deriveBits(d, c);
          }
        }
      ]);
    }();
    e.default = new X();
  })(bi);
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = jr, n = i(ci), r = i(bi);
    function i(S) {
      return S && S.__esModule ? S : {
        default: S
      };
    }
    function a(S, w, C) {
      return w = u(w), o(S, y() ? Reflect.construct(w, [], u(S).constructor) : w.apply(S, C));
    }
    function o(S, w) {
      if (w && (X(w) == "object" || typeof w == "function")) return w;
      if (w !== void 0) throw new TypeError("Derived constructors may only return object or undefined");
      return s(S);
    }
    function s(S) {
      if (S === void 0) throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
      return S;
    }
    function y() {
      try {
        var S = !Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function() {
        }));
      } catch {
      }
      return (y = function() {
        return !!S;
      })();
    }
    function u(S) {
      return u = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function(w) {
        return w.__proto__ || Object.getPrototypeOf(w);
      }, u(S);
    }
    function l(S, w) {
      if (typeof w != "function" && w !== null) throw new TypeError("Super expression must either be null or a function");
      S.prototype = Object.create(w && w.prototype, {
        constructor: {
          value: S,
          writable: true,
          configurable: true
        }
      }), Object.defineProperty(S, "prototype", {
        writable: false
      }), w && k(S, w);
    }
    function k(S, w) {
      return k = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function(C, A) {
        return C.__proto__ = A, C;
      }, k(S, w);
    }
    function X(S) {
      "@babel/helpers - typeof";
      return X = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(w) {
        return typeof w;
      } : function(w) {
        return w && typeof Symbol == "function" && w.constructor === Symbol && w !== Symbol.prototype ? "symbol" : typeof w;
      }, X(S);
    }
    function g() {
      g = function() {
        return w;
      };
      var S, w = {}, C = Object.prototype, A = C.hasOwnProperty, O = Object.defineProperty || function(se, Y, ie) {
        se[Y] = ie.value;
      }, I = typeof Symbol == "function" ? Symbol : {}, Z = I.iterator || "@@iterator", q = I.asyncIterator || "@@asyncIterator", $ = I.toStringTag || "@@toStringTag";
      function ne(se, Y, ie) {
        return Object.defineProperty(se, Y, {
          value: ie,
          enumerable: true,
          configurable: true,
          writable: true
        }), se[Y];
      }
      try {
        ne({}, "");
      } catch {
        ne = function(ie, he, ve) {
          return ie[he] = ve;
        };
      }
      function E(se, Y, ie, he) {
        var ve = Y && Y.prototype instanceof re ? Y : re, de = Object.create(ve.prototype), Pe = new Je(he || []);
        return O(de, "_invoke", {
          value: He(se, ie, Pe)
        }), de;
      }
      function p(se, Y, ie) {
        try {
          return {
            type: "normal",
            arg: se.call(Y, ie)
          };
        } catch (he) {
          return {
            type: "throw",
            arg: he
          };
        }
      }
      w.wrap = E;
      var m = "suspendedStart", L = "suspendedYield", B = "executing", M = "completed", V = {};
      function re() {
      }
      function oe() {
      }
      function ce() {
      }
      var pe = {};
      ne(pe, Z, function() {
        return this;
      });
      var ye = Object.getPrototypeOf, Ne = ye && ye(ye(ht([])));
      Ne && Ne !== C && A.call(Ne, Z) && (pe = Ne);
      var je = ce.prototype = re.prototype = Object.create(pe);
      function ut(se) {
        [
          "next",
          "throw",
          "return"
        ].forEach(function(Y) {
          ne(se, Y, function(ie) {
            return this._invoke(Y, ie);
          });
        });
      }
      function Ue(se, Y) {
        function ie(ve, de, Pe, Me) {
          var Oe = p(se[ve], se, de);
          if (Oe.type !== "throw") {
            var le = Oe.arg, bt = le.value;
            return bt && X(bt) == "object" && A.call(bt, "__await") ? Y.resolve(bt.__await).then(function(mt) {
              ie("next", mt, Pe, Me);
            }, function(mt) {
              ie("throw", mt, Pe, Me);
            }) : Y.resolve(bt).then(function(mt) {
              le.value = mt, Pe(le);
            }, function(mt) {
              return ie("throw", mt, Pe, Me);
            });
          }
          Me(Oe.arg);
        }
        var he;
        O(this, "_invoke", {
          value: function(de, Pe) {
            function Me() {
              return new Y(function(Oe, le) {
                ie(de, Pe, Oe, le);
              });
            }
            return he = he ? he.then(Me, Me) : Me();
          }
        });
      }
      function He(se, Y, ie) {
        var he = m;
        return function(ve, de) {
          if (he === B) throw Error("Generator is already running");
          if (he === M) {
            if (ve === "throw") throw de;
            return {
              value: S,
              done: true
            };
          }
          for (ie.method = ve, ie.arg = de; ; ) {
            var Pe = ie.delegate;
            if (Pe) {
              var Me = nt(Pe, ie);
              if (Me) {
                if (Me === V) continue;
                return Me;
              }
            }
            if (ie.method === "next") ie.sent = ie._sent = ie.arg;
            else if (ie.method === "throw") {
              if (he === m) throw he = M, ie.arg;
              ie.dispatchException(ie.arg);
            } else ie.method === "return" && ie.abrupt("return", ie.arg);
            he = B;
            var Oe = p(se, Y, ie);
            if (Oe.type === "normal") {
              if (he = ie.done ? M : L, Oe.arg === V) continue;
              return {
                value: Oe.arg,
                done: ie.done
              };
            }
            Oe.type === "throw" && (he = M, ie.method = "throw", ie.arg = Oe.arg);
          }
        };
      }
      function nt(se, Y) {
        var ie = Y.method, he = se.iterator[ie];
        if (he === S) return Y.delegate = null, ie === "throw" && se.iterator.return && (Y.method = "return", Y.arg = S, nt(se, Y), Y.method === "throw") || ie !== "return" && (Y.method = "throw", Y.arg = new TypeError("The iterator does not provide a '" + ie + "' method")), V;
        var ve = p(he, se.iterator, Y.arg);
        if (ve.type === "throw") return Y.method = "throw", Y.arg = ve.arg, Y.delegate = null, V;
        var de = ve.arg;
        return de ? de.done ? (Y[se.resultName] = de.value, Y.next = se.nextLoc, Y.method !== "return" && (Y.method = "next", Y.arg = S), Y.delegate = null, V) : de : (Y.method = "throw", Y.arg = new TypeError("iterator result is not an object"), Y.delegate = null, V);
      }
      function Lt(se) {
        var Y = {
          tryLoc: se[0]
        };
        1 in se && (Y.catchLoc = se[1]), 2 in se && (Y.finallyLoc = se[2], Y.afterLoc = se[3]), this.tryEntries.push(Y);
      }
      function it(se) {
        var Y = se.completion || {};
        Y.type = "normal", delete Y.arg, se.completion = Y;
      }
      function Je(se) {
        this.tryEntries = [
          {
            tryLoc: "root"
          }
        ], se.forEach(Lt, this), this.reset(true);
      }
      function ht(se) {
        if (se || se === "") {
          var Y = se[Z];
          if (Y) return Y.call(se);
          if (typeof se.next == "function") return se;
          if (!isNaN(se.length)) {
            var ie = -1, he = function ve() {
              for (; ++ie < se.length; ) if (A.call(se, ie)) return ve.value = se[ie], ve.done = false, ve;
              return ve.value = S, ve.done = true, ve;
            };
            return he.next = he;
          }
        }
        throw new TypeError(X(se) + " is not iterable");
      }
      return oe.prototype = ce, O(je, "constructor", {
        value: ce,
        configurable: true
      }), O(ce, "constructor", {
        value: oe,
        configurable: true
      }), oe.displayName = ne(ce, $, "GeneratorFunction"), w.isGeneratorFunction = function(se) {
        var Y = typeof se == "function" && se.constructor;
        return !!Y && (Y === oe || (Y.displayName || Y.name) === "GeneratorFunction");
      }, w.mark = function(se) {
        return Object.setPrototypeOf ? Object.setPrototypeOf(se, ce) : (se.__proto__ = ce, ne(se, $, "GeneratorFunction")), se.prototype = Object.create(je), se;
      }, w.awrap = function(se) {
        return {
          __await: se
        };
      }, ut(Ue.prototype), ne(Ue.prototype, q, function() {
        return this;
      }), w.AsyncIterator = Ue, w.async = function(se, Y, ie, he, ve) {
        ve === void 0 && (ve = Promise);
        var de = new Ue(E(se, Y, ie, he), ve);
        return w.isGeneratorFunction(Y) ? de : de.next().then(function(Pe) {
          return Pe.done ? Pe.value : de.next();
        });
      }, ut(je), ne(je, $, "Generator"), ne(je, Z, function() {
        return this;
      }), ne(je, "toString", function() {
        return "[object Generator]";
      }), w.keys = function(se) {
        var Y = Object(se), ie = [];
        for (var he in Y) ie.push(he);
        return ie.reverse(), function ve() {
          for (; ie.length; ) {
            var de = ie.pop();
            if (de in Y) return ve.value = de, ve.done = false, ve;
          }
          return ve.done = true, ve;
        };
      }, w.values = ht, Je.prototype = {
        constructor: Je,
        reset: function(Y) {
          if (this.prev = 0, this.next = 0, this.sent = this._sent = S, this.done = false, this.delegate = null, this.method = "next", this.arg = S, this.tryEntries.forEach(it), !Y) for (var ie in this) ie.charAt(0) === "t" && A.call(this, ie) && !isNaN(+ie.slice(1)) && (this[ie] = S);
        },
        stop: function() {
          this.done = true;
          var Y = this.tryEntries[0].completion;
          if (Y.type === "throw") throw Y.arg;
          return this.rval;
        },
        dispatchException: function(Y) {
          if (this.done) throw Y;
          var ie = this;
          function he(le, bt) {
            return Pe.type = "throw", Pe.arg = Y, ie.next = le, bt && (ie.method = "next", ie.arg = S), !!bt;
          }
          for (var ve = this.tryEntries.length - 1; ve >= 0; --ve) {
            var de = this.tryEntries[ve], Pe = de.completion;
            if (de.tryLoc === "root") return he("end");
            if (de.tryLoc <= this.prev) {
              var Me = A.call(de, "catchLoc"), Oe = A.call(de, "finallyLoc");
              if (Me && Oe) {
                if (this.prev < de.catchLoc) return he(de.catchLoc, true);
                if (this.prev < de.finallyLoc) return he(de.finallyLoc);
              } else if (Me) {
                if (this.prev < de.catchLoc) return he(de.catchLoc, true);
              } else {
                if (!Oe) throw Error("try statement without catch or finally");
                if (this.prev < de.finallyLoc) return he(de.finallyLoc);
              }
            }
          }
        },
        abrupt: function(Y, ie) {
          for (var he = this.tryEntries.length - 1; he >= 0; --he) {
            var ve = this.tryEntries[he];
            if (ve.tryLoc <= this.prev && A.call(ve, "finallyLoc") && this.prev < ve.finallyLoc) {
              var de = ve;
              break;
            }
          }
          de && (Y === "break" || Y === "continue") && de.tryLoc <= ie && ie <= de.finallyLoc && (de = null);
          var Pe = de ? de.completion : {};
          return Pe.type = Y, Pe.arg = ie, de ? (this.method = "next", this.next = de.finallyLoc, V) : this.complete(Pe);
        },
        complete: function(Y, ie) {
          if (Y.type === "throw") throw Y.arg;
          return Y.type === "break" || Y.type === "continue" ? this.next = Y.arg : Y.type === "return" ? (this.rval = this.arg = Y.arg, this.method = "return", this.next = "end") : Y.type === "normal" && ie && (this.next = ie), V;
        },
        finish: function(Y) {
          for (var ie = this.tryEntries.length - 1; ie >= 0; --ie) {
            var he = this.tryEntries[ie];
            if (he.finallyLoc === Y) return this.complete(he.completion, he.afterLoc), it(he), V;
          }
        },
        catch: function(Y) {
          for (var ie = this.tryEntries.length - 1; ie >= 0; --ie) {
            var he = this.tryEntries[ie];
            if (he.tryLoc === Y) {
              var ve = he.completion;
              if (ve.type === "throw") {
                var de = ve.arg;
                it(he);
              }
              return de;
            }
          }
          throw Error("illegal catch attempt");
        },
        delegateYield: function(Y, ie, he) {
          return this.delegate = {
            iterator: ht(Y),
            resultName: ie,
            nextLoc: he
          }, this.method === "next" && (this.arg = S), V;
        }
      }, w;
    }
    function b(S, w, C, A, O, I, Z) {
      try {
        var q = S[I](Z), $ = q.value;
      } catch (ne) {
        return void C(ne);
      }
      q.done ? w($) : Promise.resolve($).then(A, O);
    }
    function d(S) {
      return function() {
        var w = this, C = arguments;
        return new Promise(function(A, O) {
          var I = S.apply(w, C);
          function Z($) {
            b(I, A, O, Z, q, "next", $);
          }
          function q($) {
            b(I, A, O, Z, q, "throw", $);
          }
          Z(void 0);
        });
      };
    }
    function f(S, w) {
      if (!(S instanceof w)) throw new TypeError("Cannot call a class as a function");
    }
    function c(S, w) {
      for (var C = 0; C < w.length; C++) {
        var A = w[C];
        A.enumerable = A.enumerable || false, A.configurable = true, "value" in A && (A.writable = true), Object.defineProperty(S, K(A.key), A);
      }
    }
    function h(S, w, C) {
      return w && c(S.prototype, w), Object.defineProperty(S, "prototype", {
        writable: false
      }), S;
    }
    function K(S) {
      var w = x(S, "string");
      return X(w) == "symbol" ? w : w + "";
    }
    function x(S, w) {
      if (X(S) != "object" || !S) return S;
      var C = S[Symbol.toPrimitive];
      if (C !== void 0) {
        var A = C.call(S, w);
        if (X(A) != "object") return A;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(S);
    }
    var F = function() {
      function S() {
        f(this, S), this._cipher = null, this._counter = new Uint8Array(16);
      }
      return h(S, [
        {
          key: "setKey",
          value: function() {
            var w = d(g().mark(function A(O) {
              return g().wrap(function(Z) {
                for (; ; ) switch (Z.prev = Z.next) {
                  case 0:
                    return Z.next = 2, r.default.importKey("raw", O, {
                      name: "AES-EAX"
                    }, false, [
                      "encrypt, decrypt"
                    ]);
                  case 2:
                    this._cipher = Z.sent;
                  case 3:
                  case "end":
                    return Z.stop();
                }
              }, A, this);
            }));
            function C(A) {
              return w.apply(this, arguments);
            }
            return C;
          }()
        },
        {
          key: "makeMessage",
          value: function() {
            var w = d(g().mark(function A(O) {
              var I, Z, q, $;
              return g().wrap(function(E) {
                for (; ; ) switch (E.prev = E.next) {
                  case 0:
                    return I = new Uint8Array([
                      (O.length & 65280) >>> 8,
                      O.length & 255
                    ]), E.next = 3, r.default.encrypt({
                      name: "AES-EAX",
                      iv: this._counter,
                      additionalData: I
                    }, this._cipher, O);
                  case 3:
                    for (Z = E.sent, q = 0; q < 16 && this._counter[q]++ === 255; q++) ;
                    return $ = new Uint8Array(O.length + 2 + 16), $.set(I), $.set(Z, 2), E.abrupt("return", $);
                  case 9:
                  case "end":
                    return E.stop();
                }
              }, A, this);
            }));
            function C(A) {
              return w.apply(this, arguments);
            }
            return C;
          }()
        },
        {
          key: "receiveMessage",
          value: function() {
            var w = d(g().mark(function A(O, I) {
              var Z, q, $;
              return g().wrap(function(E) {
                for (; ; ) switch (E.prev = E.next) {
                  case 0:
                    return Z = new Uint8Array([
                      (O & 65280) >>> 8,
                      O & 255
                    ]), E.next = 3, r.default.decrypt({
                      name: "AES-EAX",
                      iv: this._counter,
                      additionalData: Z
                    }, this._cipher, I);
                  case 3:
                    for (q = E.sent, $ = 0; $ < 16 && this._counter[$]++ === 255; $++) ;
                    return E.abrupt("return", q);
                  case 6:
                  case "end":
                    return E.stop();
                }
              }, A, this);
            }));
            function C(A, O) {
              return w.apply(this, arguments);
            }
            return C;
          }()
        }
      ]);
    }();
    e.default = function(S) {
      function w(C, A) {
        var O;
        return f(this, w), O = a(this, w), O._hasStarted = false, O._checkSock = null, O._checkCredentials = null, O._approveServerResolve = null, O._sockReject = null, O._credentialsReject = null, O._approveServerReject = null, O._sock = C, O._getCredentials = A, O;
      }
      return l(w, S), h(w, [
        {
          key: "_waitSockAsync",
          value: function(A) {
            var O = this;
            return new Promise(function(I, Z) {
              var q = function() {
                return !O._sock.rQwait("RA2", A);
              };
              q() ? I() : (O._checkSock = function() {
                q() && (I(), O._checkSock = null, O._sockReject = null);
              }, O._sockReject = Z);
            });
          }
        },
        {
          key: "_waitApproveKeyAsync",
          value: function() {
            var A = this;
            return new Promise(function(O, I) {
              A._approveServerResolve = O, A._approveServerReject = I;
            });
          }
        },
        {
          key: "_waitCredentialsAsync",
          value: function(A) {
            var O = this, I = function() {
              return A === 1 && O._getCredentials().username !== void 0 && O._getCredentials().password !== void 0 ? true : A === 2 && O._getCredentials().password !== void 0;
            };
            return new Promise(function(Z, q) {
              I() ? Z() : (O._checkCredentials = function() {
                I() && (Z(), O._checkCredentials = null, O._credentialsReject = null);
              }, O._credentialsReject = q);
            });
          }
        },
        {
          key: "checkInternalEvents",
          value: function() {
            this._checkSock !== null && this._checkSock(), this._checkCredentials !== null && this._checkCredentials();
          }
        },
        {
          key: "approveServer",
          value: function() {
            this._approveServerResolve !== null && (this._approveServerResolve(), this._approveServerResolve = null);
          }
        },
        {
          key: "disconnect",
          value: function() {
            this._sockReject !== null && (this._sockReject(new Error("disconnect normally")), this._sockReject = null), this._credentialsReject !== null && (this._credentialsReject(new Error("disconnect normally")), this._credentialsReject = null), this._approveServerReject !== null && (this._approveServerReject(new Error("disconnect normally")), this._approveServerReject = null);
          }
        },
        {
          key: "negotiateRA2neAuthAsync",
          value: function() {
            var C = d(g().mark(function O() {
              var I, Z, q, $, ne, E, p, m, L, B, M, V, re, oe, ce, pe, ye, Ne, je, ut, Ue, He, nt, Lt, it, Je, ht, se, Y, ie, he, ve, de, Pe, Me;
              return g().wrap(function(le) {
                for (; ; ) switch (le.prev = le.next) {
                  case 0:
                    return this._hasStarted = true, le.next = 3, this._waitSockAsync(4);
                  case 3:
                    if (I = this._sock.rQpeekBytes(4), Z = this._sock.rQshift32(), !(Z < 1024)) {
                      le.next = 9;
                      break;
                    }
                    throw new Error("RA2: server public key is too short: " + Z);
                  case 9:
                    if (!(Z > 8192)) {
                      le.next = 11;
                      break;
                    }
                    throw new Error("RA2: server public key is too long: " + Z);
                  case 11:
                    return q = Math.ceil(Z / 8), le.next = 14, this._waitSockAsync(q * 2);
                  case 14:
                    return $ = this._sock.rQshiftBytes(q), ne = this._sock.rQshiftBytes(q), le.next = 18, r.default.importKey("raw", {
                      n: $,
                      e: ne
                    }, {
                      name: "RSA-PKCS1-v1_5"
                    }, false, [
                      "encrypt"
                    ]);
                  case 18:
                    return E = le.sent, p = new Uint8Array(4 + q * 2), p.set(I), p.set($, 4), p.set(ne, 4 + q), m = this._waitApproveKeyAsync(), this.dispatchEvent(new CustomEvent("serververification", {
                      detail: {
                        type: "RSA",
                        publickey: p
                      }
                    })), le.next = 27, m;
                  case 27:
                    return L = 2048, B = Math.ceil(L / 8), le.next = 31, r.default.generateKey({
                      name: "RSA-PKCS1-v1_5",
                      modulusLength: L,
                      publicExponent: new Uint8Array([
                        1,
                        0,
                        1
                      ])
                    }, true, [
                      "encrypt"
                    ]);
                  case 31:
                    return M = le.sent.privateKey, le.next = 34, r.default.exportKey("raw", M);
                  case 34:
                    return V = le.sent, re = V.n, oe = V.e, ce = new Uint8Array(4 + B * 2), ce[0] = (L & 4278190080) >>> 24, ce[1] = (L & 16711680) >>> 16, ce[2] = (L & 65280) >>> 8, ce[3] = L & 255, ce.set(re, 4), ce.set(oe, 4 + B), this._sock.sQpushBytes(ce), this._sock.flush(), pe = new Uint8Array(16), window.crypto.getRandomValues(pe), le.next = 50, r.default.encrypt({
                      name: "RSA-PKCS1-v1_5"
                    }, E, pe);
                  case 50:
                    return ye = le.sent, Ne = new Uint8Array(2 + q), Ne[0] = (q & 65280) >>> 8, Ne[1] = q & 255, Ne.set(ye, 2), this._sock.sQpushBytes(Ne), this._sock.flush(), le.next = 59, this._waitSockAsync(2);
                  case 59:
                    if (this._sock.rQshift16() === B) {
                      le.next = 61;
                      break;
                    }
                    throw new Error("RA2: wrong encrypted message length");
                  case 61:
                    return je = this._sock.rQshiftBytes(B), le.next = 64, r.default.decrypt({
                      name: "RSA-PKCS1-v1_5"
                    }, M, je);
                  case 64:
                    if (ut = le.sent, !(ut === null || ut.length !== 16)) {
                      le.next = 67;
                      break;
                    }
                    throw new Error("RA2: corrupted server encrypted random");
                  case 67:
                    return Ue = new Uint8Array(32), He = new Uint8Array(32), Ue.set(ut), Ue.set(pe, 16), He.set(pe), He.set(ut, 16), le.next = 75, window.crypto.subtle.digest("SHA-1", Ue);
                  case 75:
                    return Ue = le.sent, Ue = new Uint8Array(Ue).slice(0, 16), le.next = 79, window.crypto.subtle.digest("SHA-1", He);
                  case 79:
                    return He = le.sent, He = new Uint8Array(He).slice(0, 16), nt = new F(), le.next = 84, nt.setKey(Ue);
                  case 84:
                    return Lt = new F(), le.next = 87, Lt.setKey(He);
                  case 87:
                    return it = new Uint8Array(8 + q * 2 + B * 2), Je = new Uint8Array(8 + q * 2 + B * 2), it.set(p), it.set(ce, 4 + q * 2), Je.set(ce), Je.set(p, 4 + B * 2), le.next = 95, window.crypto.subtle.digest("SHA-1", it);
                  case 95:
                    return it = le.sent, le.next = 98, window.crypto.subtle.digest("SHA-1", Je);
                  case 98:
                    return Je = le.sent, it = new Uint8Array(it), Je = new Uint8Array(Je), le.t0 = this._sock, le.next = 104, nt.makeMessage(Je);
                  case 104:
                    return le.t1 = le.sent, le.t0.sQpushBytes.call(le.t0, le.t1), this._sock.flush(), le.next = 109, this._waitSockAsync(38);
                  case 109:
                    if (this._sock.rQshift16() === 20) {
                      le.next = 111;
                      break;
                    }
                    throw new Error("RA2: wrong server hash");
                  case 111:
                    return le.next = 113, Lt.receiveMessage(20, this._sock.rQshiftBytes(36));
                  case 113:
                    if (ht = le.sent, ht !== null) {
                      le.next = 116;
                      break;
                    }
                    throw new Error("RA2: failed to authenticate the message");
                  case 116:
                    se = 0;
                  case 117:
                    if (!(se < 20)) {
                      le.next = 123;
                      break;
                    }
                    if (ht[se] === it[se]) {
                      le.next = 120;
                      break;
                    }
                    throw new Error("RA2: wrong server hash");
                  case 120:
                    se++, le.next = 117;
                    break;
                  case 123:
                    return le.next = 125, this._waitSockAsync(19);
                  case 125:
                    if (this._sock.rQshift16() === 1) {
                      le.next = 127;
                      break;
                    }
                    throw new Error("RA2: wrong subtype");
                  case 127:
                    return le.next = 129, Lt.receiveMessage(1, this._sock.rQshiftBytes(17));
                  case 129:
                    if (Y = le.sent, Y !== null) {
                      le.next = 132;
                      break;
                    }
                    throw new Error("RA2: failed to authenticate the message");
                  case 132:
                    if (Y = Y[0], ie = this._waitCredentialsAsync(Y), Y !== 1) {
                      le.next = 138;
                      break;
                    }
                    (this._getCredentials().username === void 0 || this._getCredentials().password === void 0) && this.dispatchEvent(new CustomEvent("credentialsrequired", {
                      detail: {
                        types: [
                          "username",
                          "password"
                        ]
                      }
                    })), le.next = 143;
                    break;
                  case 138:
                    if (Y !== 2) {
                      le.next = 142;
                      break;
                    }
                    this._getCredentials().password === void 0 && this.dispatchEvent(new CustomEvent("credentialsrequired", {
                      detail: {
                        types: [
                          "password"
                        ]
                      }
                    })), le.next = 143;
                    break;
                  case 142:
                    throw new Error("RA2: wrong subtype");
                  case 143:
                    return le.next = 145, ie;
                  case 145:
                    for (Y === 1 ? he = (0, t.encodeUTF8)(this._getCredentials().username).slice(0, 255) : he = "", ve = (0, t.encodeUTF8)(this._getCredentials().password).slice(0, 255), de = new Uint8Array(he.length + ve.length + 2), de[0] = he.length, de[he.length + 1] = ve.length, Pe = 0; Pe < he.length; Pe++) de[Pe + 1] = he.charCodeAt(Pe);
                    for (Me = 0; Me < ve.length; Me++) de[he.length + 2 + Me] = ve.charCodeAt(Me);
                    return le.t2 = this._sock, le.next = 155, nt.makeMessage(de);
                  case 155:
                    le.t3 = le.sent, le.t2.sQpushBytes.call(le.t2, le.t3), this._sock.flush();
                  case 158:
                  case "end":
                    return le.stop();
                }
              }, O, this);
            }));
            function A() {
              return C.apply(this, arguments);
            }
            return A;
          }()
        },
        {
          key: "hasStarted",
          get: function() {
            return this._hasStarted;
          },
          set: function(A) {
            this._hasStarted = A;
          }
        }
      ]);
    }(n.default);
  })(as);
  var cs = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(s) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(y) {
        return typeof y;
      } : function(y) {
        return y && typeof Symbol == "function" && y.constructor === Symbol && y !== Symbol.prototype ? "symbol" : typeof y;
      }, t(s);
    }
    function n(s, y) {
      if (!(s instanceof y)) throw new TypeError("Cannot call a class as a function");
    }
    function r(s, y) {
      for (var u = 0; u < y.length; u++) {
        var l = y[u];
        l.enumerable = l.enumerable || false, l.configurable = true, "value" in l && (l.writable = true), Object.defineProperty(s, a(l.key), l);
      }
    }
    function i(s, y, u) {
      return y && r(s.prototype, y), Object.defineProperty(s, "prototype", {
        writable: false
      }), s;
    }
    function a(s) {
      var y = o(s, "string");
      return t(y) == "symbol" ? y : y + "";
    }
    function o(s, y) {
      if (t(s) != "object" || !s) return s;
      var u = s[Symbol.toPrimitive];
      if (u !== void 0) {
        var l = u.call(s, y);
        if (t(l) != "object") return l;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(s);
    }
    e.default = function() {
      function s() {
        n(this, s), this._lines = 0;
      }
      return i(s, [
        {
          key: "decodeRect",
          value: function(u, l, k, X, g, b, d) {
            if (k === 0 || X === 0) return true;
            this._lines === 0 && (this._lines = X);
            for (var f = d == 8 ? 1 : 4, c = k * f; this._lines > 0; ) {
              if (g.rQwait("RAW", c)) return false;
              var h = l + (X - this._lines), K = g.rQshiftBytes(c, false);
              if (d == 8) {
                for (var x = new Uint8Array(k * 4), F = 0; F < k; F++) x[F * 4 + 0] = (K[F] >> 0 & 3) * 255 / 3, x[F * 4 + 1] = (K[F] >> 2 & 3) * 255 / 3, x[F * 4 + 2] = (K[F] >> 4 & 3) * 255 / 3, x[F * 4 + 3] = 255;
                K = x;
              }
              for (var S = 0; S < k; S++) K[S * 4 + 3] = 255;
              b.blitImage(u, h, k, 1, K, 0), this._lines--;
            }
            return true;
          }
        }
      ]);
    }();
  })(cs);
  var hs = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(s) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(y) {
        return typeof y;
      } : function(y) {
        return y && typeof Symbol == "function" && y.constructor === Symbol && y !== Symbol.prototype ? "symbol" : typeof y;
      }, t(s);
    }
    function n(s, y) {
      if (!(s instanceof y)) throw new TypeError("Cannot call a class as a function");
    }
    function r(s, y) {
      for (var u = 0; u < y.length; u++) {
        var l = y[u];
        l.enumerable = l.enumerable || false, l.configurable = true, "value" in l && (l.writable = true), Object.defineProperty(s, a(l.key), l);
      }
    }
    function i(s, y, u) {
      return y && r(s.prototype, y), Object.defineProperty(s, "prototype", {
        writable: false
      }), s;
    }
    function a(s) {
      var y = o(s, "string");
      return t(y) == "symbol" ? y : y + "";
    }
    function o(s, y) {
      if (t(s) != "object" || !s) return s;
      var u = s[Symbol.toPrimitive];
      if (u !== void 0) {
        var l = u.call(s, y);
        if (t(l) != "object") return l;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(s);
    }
    e.default = function() {
      function s() {
        n(this, s);
      }
      return i(s, [
        {
          key: "decodeRect",
          value: function(u, l, k, X, g, b, d) {
            if (g.rQwait("COPYRECT", 4)) return false;
            var f = g.rQshift16(), c = g.rQshift16();
            return k === 0 || X === 0 || b.copyImage(f, c, u, l, k, X), true;
          }
        }
      ]);
    }();
  })(hs);
  var ds = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(s) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(y) {
        return typeof y;
      } : function(y) {
        return y && typeof Symbol == "function" && y.constructor === Symbol && y !== Symbol.prototype ? "symbol" : typeof y;
      }, t(s);
    }
    function n(s, y) {
      if (!(s instanceof y)) throw new TypeError("Cannot call a class as a function");
    }
    function r(s, y) {
      for (var u = 0; u < y.length; u++) {
        var l = y[u];
        l.enumerable = l.enumerable || false, l.configurable = true, "value" in l && (l.writable = true), Object.defineProperty(s, a(l.key), l);
      }
    }
    function i(s, y, u) {
      return y && r(s.prototype, y), Object.defineProperty(s, "prototype", {
        writable: false
      }), s;
    }
    function a(s) {
      var y = o(s, "string");
      return t(y) == "symbol" ? y : y + "";
    }
    function o(s, y) {
      if (t(s) != "object" || !s) return s;
      var u = s[Symbol.toPrimitive];
      if (u !== void 0) {
        var l = u.call(s, y);
        if (t(l) != "object") return l;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(s);
    }
    e.default = function() {
      function s() {
        n(this, s), this._subrects = 0;
      }
      return i(s, [
        {
          key: "decodeRect",
          value: function(u, l, k, X, g, b, d) {
            if (this._subrects === 0) {
              if (g.rQwait("RRE", 8)) return false;
              this._subrects = g.rQshift32();
              var f = g.rQshiftBytes(4);
              b.fillRect(u, l, k, X, f);
            }
            for (; this._subrects > 0; ) {
              if (g.rQwait("RRE", 12)) return false;
              var c = g.rQshiftBytes(4), h = g.rQshift16(), K = g.rQshift16(), x = g.rQshift16(), F = g.rQshift16();
              b.fillRect(u + h, l + K, x, F, c), this._subrects--;
            }
            return true;
          }
        }
      ]);
    }();
  })(ds);
  var _s = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = r(Re);
    function n(l) {
      if (typeof WeakMap != "function") return null;
      var k = /* @__PURE__ */ new WeakMap(), X = /* @__PURE__ */ new WeakMap();
      return (n = function(b) {
        return b ? X : k;
      })(l);
    }
    function r(l, k) {
      if (l && l.__esModule) return l;
      if (l === null || i(l) != "object" && typeof l != "function") return {
        default: l
      };
      var X = n(k);
      if (X && X.has(l)) return X.get(l);
      var g = {
        __proto__: null
      }, b = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var d in l) if (d !== "default" && {}.hasOwnProperty.call(l, d)) {
        var f = b ? Object.getOwnPropertyDescriptor(l, d) : null;
        f && (f.get || f.set) ? Object.defineProperty(g, d, f) : g[d] = l[d];
      }
      return g.default = l, X && X.set(l, g), g;
    }
    function i(l) {
      "@babel/helpers - typeof";
      return i = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(k) {
        return typeof k;
      } : function(k) {
        return k && typeof Symbol == "function" && k.constructor === Symbol && k !== Symbol.prototype ? "symbol" : typeof k;
      }, i(l);
    }
    function a(l, k) {
      if (!(l instanceof k)) throw new TypeError("Cannot call a class as a function");
    }
    function o(l, k) {
      for (var X = 0; X < k.length; X++) {
        var g = k[X];
        g.enumerable = g.enumerable || false, g.configurable = true, "value" in g && (g.writable = true), Object.defineProperty(l, y(g.key), g);
      }
    }
    function s(l, k, X) {
      return k && o(l.prototype, k), Object.defineProperty(l, "prototype", {
        writable: false
      }), l;
    }
    function y(l) {
      var k = u(l, "string");
      return i(k) == "symbol" ? k : k + "";
    }
    function u(l, k) {
      if (i(l) != "object" || !l) return l;
      var X = l[Symbol.toPrimitive];
      if (X !== void 0) {
        var g = X.call(l, k);
        if (i(g) != "object") return g;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(l);
    }
    e.default = function() {
      function l() {
        a(this, l), this._tiles = 0, this._lastsubencoding = 0, this._tileBuffer = new Uint8Array(16 * 16 * 4);
      }
      return s(l, [
        {
          key: "decodeRect",
          value: function(X, g, b, d, f, c, h) {
            for (this._tiles === 0 && (this._tilesX = Math.ceil(b / 16), this._tilesY = Math.ceil(d / 16), this._totalTiles = this._tilesX * this._tilesY, this._tiles = this._totalTiles); this._tiles > 0; ) {
              var K = 1;
              if (f.rQwait("HEXTILE", K)) return false;
              var x = f.rQpeek8();
              if (x > 30) throw new Error("Illegal hextile subencoding (subencoding: " + x + ")");
              var F = this._totalTiles - this._tiles, S = F % this._tilesX, w = Math.floor(F / this._tilesX), C = X + S * 16, A = g + w * 16, O = Math.min(16, X + b - C), I = Math.min(16, g + d - A);
              if (x & 1) K += O * I * 4;
              else if (x & 2 && (K += 4), x & 4 && (K += 4), x & 8) {
                if (K++, f.rQwait("HEXTILE", K)) return false;
                var Z = f.rQpeekBytes(K).at(-1);
                x & 16 ? K += Z * 6 : K += Z * 2;
              }
              if (f.rQwait("HEXTILE", K)) return false;
              if (f.rQshift8(), x === 0) this._lastsubencoding & 1 ? t.Debug("     Ignoring blank after RAW") : c.fillRect(C, A, O, I, this._background);
              else if (x & 1) {
                for (var q = O * I, $ = f.rQshiftBytes(q * 4, false), ne = 0; ne < q; ne++) $[ne * 4 + 3] = 255;
                c.blitImage(C, A, O, I, $, 0);
              } else {
                if (x & 2 && (this._background = new Uint8Array(f.rQshiftBytes(4))), x & 4 && (this._foreground = new Uint8Array(f.rQshiftBytes(4))), this._startTile(C, A, O, I, this._background), x & 8) for (var E = f.rQshift8(), p = 0; p < E; p++) {
                  var m = void 0;
                  x & 16 ? m = f.rQshiftBytes(4) : m = this._foreground;
                  var L = f.rQshift8(), B = L >> 4, M = L & 15, V = f.rQshift8(), re = (V >> 4) + 1, oe = (V & 15) + 1;
                  this._subTile(B, M, re, oe, m);
                }
                this._finishTile(c);
              }
              this._lastsubencoding = x, this._tiles--;
            }
            return true;
          }
        },
        {
          key: "_startTile",
          value: function(X, g, b, d, f) {
            this._tileX = X, this._tileY = g, this._tileW = b, this._tileH = d;
            for (var c = f[0], h = f[1], K = f[2], x = this._tileBuffer, F = 0; F < b * d * 4; F += 4) x[F] = c, x[F + 1] = h, x[F + 2] = K, x[F + 3] = 255;
          }
        },
        {
          key: "_subTile",
          value: function(X, g, b, d, f) {
            for (var c = f[0], h = f[1], K = f[2], x = X + b, F = g + d, S = this._tileBuffer, w = this._tileW, C = g; C < F; C++) for (var A = X; A < x; A++) {
              var O = (A + C * w) * 4;
              S[O] = c, S[O + 1] = h, S[O + 2] = K, S[O + 3] = 255;
            }
          }
        },
        {
          key: "_finishTile",
          value: function(X) {
            X.blitImage(this._tileX, this._tileY, this._tileW, this._tileH, this._tileBuffer, 0);
          }
        }
      ]);
    }();
  })(_s);
  var ps = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = n(Hr);
    function n(u) {
      return u && u.__esModule ? u : {
        default: u
      };
    }
    function r(u) {
      "@babel/helpers - typeof";
      return r = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(l) {
        return typeof l;
      } : function(l) {
        return l && typeof Symbol == "function" && l.constructor === Symbol && l !== Symbol.prototype ? "symbol" : typeof l;
      }, r(u);
    }
    function i(u, l) {
      if (!(u instanceof l)) throw new TypeError("Cannot call a class as a function");
    }
    function a(u, l) {
      for (var k = 0; k < l.length; k++) {
        var X = l[k];
        X.enumerable = X.enumerable || false, X.configurable = true, "value" in X && (X.writable = true), Object.defineProperty(u, s(X.key), X);
      }
    }
    function o(u, l, k) {
      return l && a(u.prototype, l), Object.defineProperty(u, "prototype", {
        writable: false
      }), u;
    }
    function s(u) {
      var l = y(u, "string");
      return r(l) == "symbol" ? l : l + "";
    }
    function y(u, l) {
      if (r(u) != "object" || !u) return u;
      var k = u[Symbol.toPrimitive];
      if (k !== void 0) {
        var X = k.call(u, l);
        if (r(X) != "object") return X;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(u);
    }
    e.default = function() {
      function u() {
        i(this, u), this._zlib = new t.default(), this._length = 0;
      }
      return o(u, [
        {
          key: "decodeRect",
          value: function(k, X, g, b, d, f, c) {
            if (g === 0 || b === 0) return true;
            if (this._length === 0) {
              if (d.rQwait("ZLIB", 4)) return false;
              this._length = d.rQshift32();
            }
            if (d.rQwait("ZLIB", this._length)) return false;
            var h = new Uint8Array(d.rQshiftBytes(this._length, false));
            this._length = 0, this._zlib.setInput(h), h = this._zlib.inflate(g * b * 4), this._zlib.setInput(null);
            for (var K = 0; K < g * b; K++) h[K * 4 + 3] = 255;
            return f.blitImage(k, X, g, b, h, 0), true;
          }
        }
      ]);
    }();
  })(ps);
  var Si = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = a(Re), n = r(Hr);
    function r(X) {
      return X && X.__esModule ? X : {
        default: X
      };
    }
    function i(X) {
      if (typeof WeakMap != "function") return null;
      var g = /* @__PURE__ */ new WeakMap(), b = /* @__PURE__ */ new WeakMap();
      return (i = function(f) {
        return f ? b : g;
      })(X);
    }
    function a(X, g) {
      if (X && X.__esModule) return X;
      if (X === null || o(X) != "object" && typeof X != "function") return {
        default: X
      };
      var b = i(g);
      if (b && b.has(X)) return b.get(X);
      var d = {
        __proto__: null
      }, f = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var c in X) if (c !== "default" && {}.hasOwnProperty.call(X, c)) {
        var h = f ? Object.getOwnPropertyDescriptor(X, c) : null;
        h && (h.get || h.set) ? Object.defineProperty(d, c, h) : d[c] = X[c];
      }
      return d.default = X, b && b.set(X, d), d;
    }
    function o(X) {
      "@babel/helpers - typeof";
      return o = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(g) {
        return typeof g;
      } : function(g) {
        return g && typeof Symbol == "function" && g.constructor === Symbol && g !== Symbol.prototype ? "symbol" : typeof g;
      }, o(X);
    }
    function s(X, g) {
      if (!(X instanceof g)) throw new TypeError("Cannot call a class as a function");
    }
    function y(X, g) {
      for (var b = 0; b < g.length; b++) {
        var d = g[b];
        d.enumerable = d.enumerable || false, d.configurable = true, "value" in d && (d.writable = true), Object.defineProperty(X, l(d.key), d);
      }
    }
    function u(X, g, b) {
      return g && y(X.prototype, g), Object.defineProperty(X, "prototype", {
        writable: false
      }), X;
    }
    function l(X) {
      var g = k(X, "string");
      return o(g) == "symbol" ? g : g + "";
    }
    function k(X, g) {
      if (o(X) != "object" || !X) return X;
      var b = X[Symbol.toPrimitive];
      if (b !== void 0) {
        var d = b.call(X, g);
        if (o(d) != "object") return d;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(X);
    }
    e.default = function() {
      function X() {
        s(this, X), this._ctl = null, this._filter = null, this._numColors = 0, this._palette = new Uint8Array(1024), this._len = 0, this._zlibs = [];
        for (var g = 0; g < 4; g++) this._zlibs[g] = new n.default();
      }
      return u(X, [
        {
          key: "decodeRect",
          value: function(b, d, f, c, h, K, x) {
            if (this._ctl === null) {
              if (h.rQwait("TIGHT compression-control", 1)) return false;
              this._ctl = h.rQshift8();
              for (var F = 0; F < 4; F++) this._ctl >> F & 1 && (this._zlibs[F].reset(), t.Info("Reset zlib stream " + F));
              this._ctl = this._ctl >> 4;
            }
            var S;
            if (this._ctl === 8) S = this._fillRect(b, d, f, c, h, K, x);
            else if (this._ctl === 9) S = this._jpegRect(b, d, f, c, h, K, x);
            else if (this._ctl === 10) S = this._pngRect(b, d, f, c, h, K, x);
            else if (!(this._ctl & 8)) S = this._basicRect(this._ctl, b, d, f, c, h, K, x);
            else throw new Error("Illegal tight compression received (ctl: " + this._ctl + ")");
            return S && (this._ctl = null), S;
          }
        },
        {
          key: "_fillRect",
          value: function(b, d, f, c, h, K, x) {
            if (h.rQwait("TIGHT", 3)) return false;
            var F = h.rQshiftBytes(3);
            return K.fillRect(b, d, f, c, F, false), true;
          }
        },
        {
          key: "_jpegRect",
          value: function(b, d, f, c, h, K, x) {
            var F = this._readData(h);
            return F === null ? false : (K.imageRect(b, d, f, c, "image/jpeg", F), true);
          }
        },
        {
          key: "_pngRect",
          value: function(b, d, f, c, h, K, x) {
            throw new Error("PNG received in standard Tight rect");
          }
        },
        {
          key: "_basicRect",
          value: function(b, d, f, c, h, K, x, F) {
            if (this._filter === null) if (b & 4) {
              if (K.rQwait("TIGHT", 1)) return false;
              this._filter = K.rQshift8();
            } else this._filter = 0;
            var S = b & 3, w;
            switch (this._filter) {
              case 0:
                w = this._copyFilter(S, d, f, c, h, K, x, F);
                break;
              case 1:
                w = this._paletteFilter(S, d, f, c, h, K, x, F);
                break;
              case 2:
                w = this._gradientFilter(S, d, f, c, h, K, x, F);
                break;
              default:
                throw new Error("Illegal tight filter received (ctl: " + this._filter + ")");
            }
            return w && (this._filter = null), w;
          }
        },
        {
          key: "_copyFilter",
          value: function(b, d, f, c, h, K, x, F) {
            var S = c * h * 3, w;
            if (S === 0) return true;
            if (S < 12) {
              if (K.rQwait("TIGHT", S)) return false;
              w = K.rQshiftBytes(S);
            } else {
              if (w = this._readData(K), w === null) return false;
              this._zlibs[b].setInput(w), w = this._zlibs[b].inflate(S), this._zlibs[b].setInput(null);
            }
            for (var C = new Uint8Array(c * h * 4), A = 0, O = 0; A < c * h * 4; A += 4, O += 3) C[A] = w[O], C[A + 1] = w[O + 1], C[A + 2] = w[O + 2], C[A + 3] = 255;
            return x.blitImage(d, f, c, h, C, 0, false), true;
          }
        },
        {
          key: "_paletteFilter",
          value: function(b, d, f, c, h, K, x, F) {
            if (this._numColors === 0) {
              if (K.rQwait("TIGHT palette", 1)) return false;
              var S = K.rQpeek8() + 1, w = S * 3;
              if (K.rQwait("TIGHT palette", 1 + w)) return false;
              this._numColors = S, K.rQskipBytes(1), K.rQshiftTo(this._palette, w);
            }
            var C = this._numColors <= 2 ? 1 : 8, A = Math.floor((c * C + 7) / 8), O = A * h, I;
            if (O === 0) return true;
            if (O < 12) {
              if (K.rQwait("TIGHT", O)) return false;
              I = K.rQshiftBytes(O);
            } else {
              if (I = this._readData(K), I === null) return false;
              this._zlibs[b].setInput(I), I = this._zlibs[b].inflate(O), this._zlibs[b].setInput(null);
            }
            return this._numColors == 2 ? this._monoRect(d, f, c, h, I, this._palette, x) : this._paletteRect(d, f, c, h, I, this._palette, x), this._numColors = 0, true;
          }
        },
        {
          key: "_monoRect",
          value: function(b, d, f, c, h, K, x) {
            for (var F = this._getScratchBuffer(f * c * 4), S = Math.floor((f + 7) / 8), w = Math.floor(f / 8), C = 0; C < c; C++) {
              var A = void 0, O = void 0, I = void 0;
              for (I = 0; I < w; I++) for (var Z = 7; Z >= 0; Z--) A = (C * f + I * 8 + 7 - Z) * 4, O = (h[C * S + I] >> Z & 1) * 3, F[A] = K[O], F[A + 1] = K[O + 1], F[A + 2] = K[O + 2], F[A + 3] = 255;
              for (var q = 7; q >= 8 - f % 8; q--) A = (C * f + I * 8 + 7 - q) * 4, O = (h[C * S + I] >> q & 1) * 3, F[A] = K[O], F[A + 1] = K[O + 1], F[A + 2] = K[O + 2], F[A + 3] = 255;
            }
            x.blitImage(b, d, f, c, F, 0, false);
          }
        },
        {
          key: "_paletteRect",
          value: function(b, d, f, c, h, K, x) {
            for (var F = this._getScratchBuffer(f * c * 4), S = f * c * 4, w = 0, C = 0; w < S; w += 4, C++) {
              var A = h[C] * 3;
              F[w] = K[A], F[w + 1] = K[A + 1], F[w + 2] = K[A + 2], F[w + 3] = 255;
            }
            x.blitImage(b, d, f, c, F, 0, false);
          }
        },
        {
          key: "_gradientFilter",
          value: function(b, d, f, c, h, K, x, F) {
            var S = c * h * 3, w;
            if (S === 0) return true;
            if (S < 12) {
              if (K.rQwait("TIGHT", S)) return false;
              w = K.rQshiftBytes(S);
            } else {
              if (w = this._readData(K), w === null) return false;
              this._zlibs[b].setInput(w), w = this._zlibs[b].inflate(S), this._zlibs[b].setInput(null);
            }
            for (var C = new Uint8Array(4 * c * h), A = 0, O = 0, I = new Uint8Array(3), Z = 0; Z < c; Z++) {
              for (var q = 0; q < 3; q++) {
                var $ = I[q], ne = w[O++] + $;
                C[A++] = ne, I[q] = ne;
              }
              C[A++] = 255;
            }
            for (var E = 0, p = new Uint8Array(3), m = new Uint8Array(3), L = 1; L < h; L++) {
              I.fill(0), m.fill(0);
              for (var B = 0; B < c; B++) {
                for (var M = 0; M < 3; M++) {
                  p[M] = C[E++];
                  var V = I[M] + p[M] - m[M];
                  V < 0 ? V = 0 : V > 255 && (V = 255);
                  var re = w[O++] + V;
                  C[A++] = re, m[M] = p[M], I[M] = re;
                }
                C[A++] = 255, E++;
              }
            }
            return x.blitImage(d, f, c, h, C, 0, false), true;
          }
        },
        {
          key: "_readData",
          value: function(b) {
            if (this._len === 0) {
              if (b.rQwait("TIGHT", 3)) return null;
              var d;
              d = b.rQshift8(), this._len = d & 127, d & 128 && (d = b.rQshift8(), this._len |= (d & 127) << 7, d & 128 && (d = b.rQshift8(), this._len |= d << 14));
            }
            if (b.rQwait("TIGHT", this._len)) return null;
            var f = b.rQshiftBytes(this._len, false);
            return this._len = 0, f;
          }
        },
        {
          key: "_getScratchBuffer",
          value: function(b) {
            return (!this._scratchBuffer || this._scratchBuffer.length < b) && (this._scratchBuffer = new Uint8Array(b)), this._scratchBuffer;
          }
        }
      ]);
    }();
  })(Si);
  var vs = {};
  (function(e) {
    function t(f) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(c) {
        return typeof c;
      } : function(c) {
        return c && typeof Symbol == "function" && c.constructor === Symbol && c !== Symbol.prototype ? "symbol" : typeof c;
      }, t(f);
    }
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var n = r(Si);
    function r(f) {
      return f && f.__esModule ? f : {
        default: f
      };
    }
    function i(f, c) {
      if (!(f instanceof c)) throw new TypeError("Cannot call a class as a function");
    }
    function a(f, c) {
      for (var h = 0; h < c.length; h++) {
        var K = c[h];
        K.enumerable = K.enumerable || false, K.configurable = true, "value" in K && (K.writable = true), Object.defineProperty(f, s(K.key), K);
      }
    }
    function o(f, c, h) {
      return c && a(f.prototype, c), Object.defineProperty(f, "prototype", {
        writable: false
      }), f;
    }
    function s(f) {
      var c = y(f, "string");
      return t(c) == "symbol" ? c : c + "";
    }
    function y(f, c) {
      if (t(f) != "object" || !f) return f;
      var h = f[Symbol.toPrimitive];
      if (h !== void 0) {
        var K = h.call(f, c);
        if (t(K) != "object") return K;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(f);
    }
    function u(f, c, h) {
      return c = g(c), l(f, X() ? Reflect.construct(c, h || [], g(f).constructor) : c.apply(f, h));
    }
    function l(f, c) {
      if (c && (t(c) == "object" || typeof c == "function")) return c;
      if (c !== void 0) throw new TypeError("Derived constructors may only return object or undefined");
      return k(f);
    }
    function k(f) {
      if (f === void 0) throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
      return f;
    }
    function X() {
      try {
        var f = !Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function() {
        }));
      } catch {
      }
      return (X = function() {
        return !!f;
      })();
    }
    function g(f) {
      return g = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function(c) {
        return c.__proto__ || Object.getPrototypeOf(c);
      }, g(f);
    }
    function b(f, c) {
      if (typeof c != "function" && c !== null) throw new TypeError("Super expression must either be null or a function");
      f.prototype = Object.create(c && c.prototype, {
        constructor: {
          value: f,
          writable: true,
          configurable: true
        }
      }), Object.defineProperty(f, "prototype", {
        writable: false
      }), c && d(f, c);
    }
    function d(f, c) {
      return d = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function(h, K) {
        return h.__proto__ = K, h;
      }, d(f, c);
    }
    e.default = function(f) {
      function c() {
        return i(this, c), u(this, c, arguments);
      }
      return b(c, f), o(c, [
        {
          key: "_pngRect",
          value: function(K, x, F, S, w, C, A) {
            var O = this._readData(w);
            return O === null ? false : (C.imageRect(K, x, F, S, "image/png", O), true);
          }
        },
        {
          key: "_basicRect",
          value: function(K, x, F, S, w, C, A, O) {
            throw new Error("BasicCompression received in TightPNG rect");
          }
        }
      ]);
    }(n.default);
  })(vs);
  var ys = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var t = n(Hr);
    function n(k) {
      return k && k.__esModule ? k : {
        default: k
      };
    }
    function r(k) {
      "@babel/helpers - typeof";
      return r = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(X) {
        return typeof X;
      } : function(X) {
        return X && typeof Symbol == "function" && X.constructor === Symbol && X !== Symbol.prototype ? "symbol" : typeof X;
      }, r(k);
    }
    function i(k, X) {
      if (!(k instanceof X)) throw new TypeError("Cannot call a class as a function");
    }
    function a(k, X) {
      for (var g = 0; g < X.length; g++) {
        var b = X[g];
        b.enumerable = b.enumerable || false, b.configurable = true, "value" in b && (b.writable = true), Object.defineProperty(k, s(b.key), b);
      }
    }
    function o(k, X, g) {
      return X && a(k.prototype, X), Object.defineProperty(k, "prototype", {
        writable: false
      }), k;
    }
    function s(k) {
      var X = y(k, "string");
      return r(X) == "symbol" ? X : X + "";
    }
    function y(k, X) {
      if (r(k) != "object" || !k) return k;
      var g = k[Symbol.toPrimitive];
      if (g !== void 0) {
        var b = g.call(k, X);
        if (r(b) != "object") return b;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(k);
    }
    var u = 64, l = 64;
    e.default = function() {
      function k() {
        i(this, k), this._length = 0, this._inflator = new t.default(), this._pixelBuffer = new Uint8Array(u * l * 4), this._tileBuffer = new Uint8Array(u * l * 4);
      }
      return o(k, [
        {
          key: "decodeRect",
          value: function(g, b, d, f, c, h, K) {
            if (this._length === 0) {
              if (c.rQwait("ZLib data length", 4)) return false;
              this._length = c.rQshift32();
            }
            if (c.rQwait("Zlib data", this._length)) return false;
            var x = c.rQshiftBytes(this._length, false);
            this._inflator.setInput(x);
            for (var F = b; F < b + f; F += l) for (var S = Math.min(l, b + f - F), w = g; w < g + d; w += u) {
              var C = Math.min(u, g + d - w), A = C * S, O = this._inflator.inflate(1)[0];
              if (O === 0) {
                var I = this._readPixels(A);
                h.blitImage(w, F, C, S, I, 0, false);
              } else if (O === 1) {
                var Z = this._readPixels(1);
                h.fillRect(w, F, C, S, [
                  Z[0],
                  Z[1],
                  Z[2]
                ]);
              } else if (O >= 2 && O <= 16) {
                var q = this._decodePaletteTile(O, A, C, S);
                h.blitImage(w, F, C, S, q, 0, false);
              } else if (O === 128) {
                var $ = this._decodeRLETile(A);
                h.blitImage(w, F, C, S, $, 0, false);
              } else if (O >= 130 && O <= 255) {
                var ne = this._decodeRLEPaletteTile(O - 128, A);
                h.blitImage(w, F, C, S, ne, 0, false);
              } else throw new Error("Unknown subencoding: " + O);
            }
            return this._length = 0, true;
          }
        },
        {
          key: "_getBitsPerPixelInPalette",
          value: function(g) {
            if (g <= 2) return 1;
            if (g <= 4) return 2;
            if (g <= 16) return 4;
          }
        },
        {
          key: "_readPixels",
          value: function(g) {
            for (var b = this._pixelBuffer, d = this._inflator.inflate(3 * g), f = 0, c = 0; f < g * 4; f += 4, c += 3) b[f] = d[c], b[f + 1] = d[c + 1], b[f + 2] = d[c + 2], b[f + 3] = 255;
            return b;
          }
        },
        {
          key: "_decodePaletteTile",
          value: function(g, b, d, f) {
            for (var c = this._tileBuffer, h = this._readPixels(g), K = this._getBitsPerPixelInPalette(g), x = (1 << K) - 1, F = 0, S = this._inflator.inflate(1)[0], w = 0; w < f; w++) {
              for (var C = 8 - K, A = 0; A < d; A++) {
                C < 0 && (C = 8 - K, S = this._inflator.inflate(1)[0]);
                var O = S >> C & x;
                c[F] = h[O * 4], c[F + 1] = h[O * 4 + 1], c[F + 2] = h[O * 4 + 2], c[F + 3] = h[O * 4 + 3], F += 4, C -= K;
              }
              C < 8 - K && w < f - 1 && (S = this._inflator.inflate(1)[0]);
            }
            return c;
          }
        },
        {
          key: "_decodeRLETile",
          value: function(g) {
            for (var b = this._tileBuffer, d = 0; d < g; ) for (var f = this._readPixels(1), c = this._readRLELength(), h = 0; h < c; h++) b[d * 4] = f[0], b[d * 4 + 1] = f[1], b[d * 4 + 2] = f[2], b[d * 4 + 3] = f[3], d++;
            return b;
          }
        },
        {
          key: "_decodeRLEPaletteTile",
          value: function(g, b) {
            for (var d = this._tileBuffer, f = this._readPixels(g), c = 0; c < b; ) {
              var h = this._inflator.inflate(1)[0], K = 1;
              if (h >= 128 && (h -= 128, K = this._readRLELength()), h > g) throw new Error("Too big index in palette: " + h + ", palette size: " + g);
              if (c + K > b) throw new Error("Too big rle length in palette mode: " + K + ", allowed length is: " + (b - c));
              for (var x = 0; x < K; x++) d[c * 4] = f[h * 4], d[c * 4 + 1] = f[h * 4 + 1], d[c * 4 + 2] = f[h * 4 + 2], d[c * 4 + 3] = f[h * 4 + 3], c++;
            }
            return d;
          }
        },
        {
          key: "_readRLELength",
          value: function() {
            var g = 0, b = 0;
            do
              b = this._inflator.inflate(1)[0], g += b;
            while (b === 255);
            return g + 1;
          }
        }
      ]);
    }();
  })(ys);
  var xs = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    function t(b) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(d) {
        return typeof d;
      } : function(d) {
        return d && typeof Symbol == "function" && d.constructor === Symbol && d !== Symbol.prototype ? "symbol" : typeof d;
      }, t(b);
    }
    function n(b) {
      return a(b) || i(b) || s(b) || r();
    }
    function r() {
      throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
    }
    function i(b) {
      if (typeof Symbol < "u" && b[Symbol.iterator] != null || b["@@iterator"] != null) return Array.from(b);
    }
    function a(b) {
      if (Array.isArray(b)) return y(b);
    }
    function o(b, d) {
      var f = typeof Symbol < "u" && b[Symbol.iterator] || b["@@iterator"];
      if (!f) {
        if (Array.isArray(b) || (f = s(b)) || d) {
          f && (b = f);
          var c = 0, h = function() {
          };
          return {
            s: h,
            n: function() {
              return c >= b.length ? {
                done: true
              } : {
                done: false,
                value: b[c++]
              };
            },
            e: function(w) {
              throw w;
            },
            f: h
          };
        }
        throw new TypeError(`Invalid attempt to iterate non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
      }
      var K, x = true, F = false;
      return {
        s: function() {
          f = f.call(b);
        },
        n: function() {
          var w = f.next();
          return x = w.done, w;
        },
        e: function(w) {
          F = true, K = w;
        },
        f: function() {
          try {
            x || f.return == null || f.return();
          } finally {
            if (F) throw K;
          }
        }
      };
    }
    function s(b, d) {
      if (b) {
        if (typeof b == "string") return y(b, d);
        var f = {}.toString.call(b).slice(8, -1);
        return f === "Object" && b.constructor && (f = b.constructor.name), f === "Map" || f === "Set" ? Array.from(b) : f === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(f) ? y(b, d) : void 0;
      }
    }
    function y(b, d) {
      (d == null || d > b.length) && (d = b.length);
      for (var f = 0, c = Array(d); f < d; f++) c[f] = b[f];
      return c;
    }
    function u(b, d) {
      if (!(b instanceof d)) throw new TypeError("Cannot call a class as a function");
    }
    function l(b, d) {
      for (var f = 0; f < d.length; f++) {
        var c = d[f];
        c.enumerable = c.enumerable || false, c.configurable = true, "value" in c && (c.writable = true), Object.defineProperty(b, X(c.key), c);
      }
    }
    function k(b, d, f) {
      return d && l(b.prototype, d), Object.defineProperty(b, "prototype", {
        writable: false
      }), b;
    }
    function X(b) {
      var d = g(b, "string");
      return t(d) == "symbol" ? d : d + "";
    }
    function g(b, d) {
      if (t(b) != "object" || !b) return b;
      var f = b[Symbol.toPrimitive];
      if (f !== void 0) {
        var c = f.call(b, d);
        if (t(c) != "object") return c;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(b);
    }
    e.default = function() {
      function b() {
        u(this, b), this._cachedQuantTables = [], this._cachedHuffmanTables = [], this._segments = [];
      }
      return k(b, [
        {
          key: "decodeRect",
          value: function(f, c, h, K, x, F, S) {
            for (; ; ) {
              var w = this._readSegment(x);
              if (w === null) return false;
              if (this._segments.push(w), w[1] === 217) break;
            }
            var C = [], A = [], O = o(this._segments), I;
            try {
              for (O.s(); !(I = O.n()).done; ) {
                var Z = I.value, q = Z[1];
                q === 196 ? C.push(Z) : q === 219 && A.push(Z);
              }
            } catch (ce) {
              O.e(ce);
            } finally {
              O.f();
            }
            var $ = this._segments.findIndex(function(ce) {
              return ce[1] == 192 || ce[1] == 194;
            });
            if ($ == -1) throw new Error("Illegal JPEG image without SOF");
            if (A.length === 0) {
              var ne;
              (ne = this._segments).splice.apply(ne, [
                $ + 1,
                0
              ].concat(n(this._cachedQuantTables)));
            }
            if (C.length === 0) {
              var E;
              (E = this._segments).splice.apply(E, [
                $ + 1,
                0
              ].concat(n(this._cachedHuffmanTables)));
            }
            var p = 0, m = o(this._segments), L;
            try {
              for (m.s(); !(L = m.n()).done; ) {
                var B = L.value;
                p += B.length;
              }
            } catch (ce) {
              m.e(ce);
            } finally {
              m.f();
            }
            var M = new Uint8Array(p);
            p = 0;
            var V = o(this._segments), re;
            try {
              for (V.s(); !(re = V.n()).done; ) {
                var oe = re.value;
                M.set(oe, p), p += oe.length;
              }
            } catch (ce) {
              V.e(ce);
            } finally {
              V.f();
            }
            return F.imageRect(f, c, h, K, "image/jpeg", M), C.length !== 0 && (this._cachedHuffmanTables = C), A.length !== 0 && (this._cachedQuantTables = A), this._segments = [], true;
          }
        },
        {
          key: "_readSegment",
          value: function(f) {
            if (f.rQwait("JPEG", 2)) return null;
            var c = f.rQshift8();
            if (c != 255) throw new Error("Illegal JPEG marker received (byte: " + c + ")");
            var h = f.rQshift8();
            if (h >= 208 && h <= 217 || h == 1) return new Uint8Array([
              c,
              h
            ]);
            if (f.rQwait("JPEG", 2, 2)) return null;
            var K = f.rQshift16();
            if (K < 2) throw new Error("Illegal JPEG length received (length: " + K + ")");
            if (f.rQwait("JPEG", K - 2, 4)) return null;
            var x = 0;
            if (h === 218) for (x += 2; ; ) {
              if (f.rQwait("JPEG", K - 2 + x, 4)) return null;
              var F = f.rQpeekBytes(K - 2 + x, false);
              if (F.at(-2) === 255 && F.at(-1) !== 0 && !(F.at(-1) >= 208 && F.at(-1) <= 215)) {
                x -= 2;
                break;
              }
              x++;
            }
            var S = new Uint8Array(2 + K + x);
            return S[0] = c, S[1] = h, S[2] = K >> 8, S[3] = K, S.set(f.rQshiftBytes(K - 2 + x, false), 4), S;
          }
        }
      ]);
    }();
  })(xs);
  var gs = {};
  (function(e) {
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = e.H264Parser = e.H264Context = void 0;
    var t = r(Re);
    function n(h) {
      if (typeof WeakMap != "function") return null;
      var K = /* @__PURE__ */ new WeakMap(), x = /* @__PURE__ */ new WeakMap();
      return (n = function(S) {
        return S ? x : K;
      })(h);
    }
    function r(h, K) {
      if (h && h.__esModule) return h;
      if (h === null || i(h) != "object" && typeof h != "function") return {
        default: h
      };
      var x = n(K);
      if (x && x.has(h)) return x.get(h);
      var F = {
        __proto__: null
      }, S = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var w in h) if (w !== "default" && {}.hasOwnProperty.call(h, w)) {
        var C = S ? Object.getOwnPropertyDescriptor(h, w) : null;
        C && (C.get || C.set) ? Object.defineProperty(F, w, C) : F[w] = h[w];
      }
      return F.default = h, x && x.set(h, F), F;
    }
    function i(h) {
      "@babel/helpers - typeof";
      return i = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(K) {
        return typeof K;
      } : function(K) {
        return K && typeof Symbol == "function" && K.constructor === Symbol && K !== Symbol.prototype ? "symbol" : typeof K;
      }, i(h);
    }
    function a(h, K) {
      return l(h) || u(h, K) || s(h, K) || o();
    }
    function o() {
      throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
    }
    function s(h, K) {
      if (h) {
        if (typeof h == "string") return y(h, K);
        var x = {}.toString.call(h).slice(8, -1);
        return x === "Object" && h.constructor && (x = h.constructor.name), x === "Map" || x === "Set" ? Array.from(h) : x === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(x) ? y(h, K) : void 0;
      }
    }
    function y(h, K) {
      (K == null || K > h.length) && (K = h.length);
      for (var x = 0, F = Array(K); x < K; x++) F[x] = h[x];
      return F;
    }
    function u(h, K) {
      var x = h == null ? null : typeof Symbol < "u" && h[Symbol.iterator] || h["@@iterator"];
      if (x != null) {
        var F, S, w, C, A = [], O = true, I = false;
        try {
          if (w = (x = x.call(h)).next, K !== 0) for (; !(O = (F = w.call(x)).done) && (A.push(F.value), A.length !== K); O = true) ;
        } catch (Z) {
          I = true, S = Z;
        } finally {
          try {
            if (!O && x.return != null && (C = x.return(), Object(C) !== C)) return;
          } finally {
            if (I) throw S;
          }
        }
        return A;
      }
    }
    function l(h) {
      if (Array.isArray(h)) return h;
    }
    function k(h, K) {
      if (!(h instanceof K)) throw new TypeError("Cannot call a class as a function");
    }
    function X(h, K) {
      for (var x = 0; x < K.length; x++) {
        var F = K[x];
        F.enumerable = F.enumerable || false, F.configurable = true, "value" in F && (F.writable = true), Object.defineProperty(h, b(F.key), F);
      }
    }
    function g(h, K, x) {
      return K && X(h.prototype, K), Object.defineProperty(h, "prototype", {
        writable: false
      }), h;
    }
    function b(h) {
      var K = d(h, "string");
      return i(K) == "symbol" ? K : K + "";
    }
    function d(h, K) {
      if (i(h) != "object" || !h) return h;
      var x = h[Symbol.toPrimitive];
      if (x !== void 0) {
        var F = x.call(h, K);
        if (i(F) != "object") return F;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(h);
    }
    var f = e.H264Parser = function() {
      function h(K) {
        k(this, h), this._data = K, this._index = 0, this.profileIdc = null, this.constraintSet = null, this.levelIdc = null;
      }
      return g(h, [
        {
          key: "_getStartSequenceLen",
          value: function(x) {
            var F = this._data;
            return F[x + 0] == 0 && F[x + 1] == 0 && F[x + 2] == 0 && F[x + 3] == 1 ? 4 : F[x + 0] == 0 && F[x + 1] == 0 && F[x + 2] == 1 ? 3 : 0;
          }
        },
        {
          key: "_indexOfNextNalUnit",
          value: function(x) {
            for (var F = this._data, S = x; S < F.length; ++S) if (this._getStartSequenceLen(S) != 0) return S;
            return -1;
          }
        },
        {
          key: "_parseSps",
          value: function(x) {
            this.profileIdc = this._data[x], this.constraintSet = this._data[x + 1], this.levelIdc = this._data[x + 2];
          }
        },
        {
          key: "_parseNalUnit",
          value: function(x) {
            var F = this._data[x];
            if (F & 128) throw new Error("H264 parsing sanity check failed, forbidden zero bit is set");
            var S = F & 31;
            switch (S) {
              case 1:
                return {
                  slice: true
                };
              case 5:
                return {
                  slice: true,
                  key: true
                };
              case 6:
                return {};
              case 7:
                return this._parseSps(x + 1), {};
              case 8:
                return {};
              default:
                t.Warn("Unhandled unit type: ", S);
                break;
            }
            return {};
          }
        },
        {
          key: "parse",
          value: function() {
            for (var x = this._index, F = false; this._index < this._data.length; ) {
              var S = this._getStartSequenceLen(this._index);
              if (S == 0) throw new Error("Invalid start sequence in bit stream");
              var w = this._parseNalUnit(this._index + S), C = w.slice, A = w.key, O = this._indexOfNextNalUnit(this._index + S);
              if (O == -1 ? this._index = this._data.length : this._index = O, A && (F = true), C) break;
            }
            return x === this._index ? null : {
              frame: this._data.subarray(x, this._index),
              key: F
            };
          }
        }
      ]);
    }(), c = e.H264Context = function() {
      function h(K, x) {
        k(this, h), this.lastUsed = 0, this._width = K, this._height = x, this._profileIdc = null, this._constraintSet = null, this._levelIdc = null, this._decoder = null, this._pendingFrames = [];
      }
      return g(h, [
        {
          key: "_handleFrame",
          value: function(x) {
            var F = this._pendingFrames.shift();
            if (F === void 0) throw new Error("Pending frame queue empty when receiving frame from decoder");
            if (F.timestamp != x.timestamp) throw new Error("Video frame timestamp mismatch. Expected " + x.timestamp + " but but got " + F.timestamp);
            F.frame = x, F.ready = true, F.resolve(), F.keep || x.close();
          }
        },
        {
          key: "_handleError",
          value: function(x) {
            throw new Error("Failed to decode frame: " + x.message);
          }
        },
        {
          key: "_configureDecoder",
          value: function(x, F, S) {
            var w = this;
            (this._decoder === null || this._decoder.state === "closed") && (this._decoder = new VideoDecoder({
              output: function(O) {
                return w._handleFrame(O);
              },
              error: function(O) {
                return w._handleError(O);
              }
            }));
            var C = "avc1." + x.toString(16).padStart(2, "0") + F.toString(16).padStart(2, "0") + S.toString(16).padStart(2, "0");
            this._decoder.configure({
              codec: C,
              codedWidth: this._width,
              codedHeight: this._height,
              optimizeForLatency: true
            });
          }
        },
        {
          key: "_preparePendingFrame",
          value: function(x) {
            var F = {
              timestamp: x,
              promise: null,
              resolve: null,
              frame: null,
              ready: false,
              keep: false
            };
            return F.promise = new Promise(function(S) {
              F.resolve = S;
            }), this._pendingFrames.push(F), F;
          }
        },
        {
          key: "decode",
          value: function(x) {
            for (var F = new f(x), S = null, w = Math.round(window.performance.now() * 1e3); ; ) {
              var C = F.parse();
              if (C === null) break;
              if (F.profileIdc !== null && (self._profileIdc = F.profileIdc, self._constraintSet = F.constraintSet, self._levelIdc = F.levelIdc), this._decoder === null || this._decoder.state !== "configured") {
                if (!C.key) {
                  t.Warn("Missing key frame. Can't decode until one arrives");
                  continue;
                }
                if (self._profileIdc === null) {
                  t.Warn("Cannot config decoder. Have not received SPS and PPS yet.");
                  continue;
                }
                this._configureDecoder(self._profileIdc, self._constraintSet, self._levelIdc);
              }
              S = this._preparePendingFrame(w);
              var A = new EncodedVideoChunk({
                timestamp: w,
                type: C.key ? "key" : "delta",
                data: C.frame
              });
              try {
                this._decoder.decode(A);
              } catch (O) {
                t.Warn("Failed to decode:", O);
              }
            }
            return S !== null && (S.keep = true), S;
          }
        }
      ]);
    }();
    e.default = function() {
      function h() {
        k(this, h), this._tick = 0, this._contexts = {};
      }
      return g(h, [
        {
          key: "_contextId",
          value: function(x, F, S, w) {
            return [
              x,
              F,
              S,
              w
            ].join(",");
          }
        },
        {
          key: "_findOldestContextId",
          value: function() {
            for (var x = Number.MAX_VALUE, F = void 0, S = 0, w = Object.entries(this._contexts); S < w.length; S++) {
              var C = a(w[S], 2), A = C[0], O = C[1];
              O.lastUsed < x && (x = O.lastUsed, F = A);
            }
            return F;
          }
        },
        {
          key: "_createContext",
          value: function(x, F, S, w) {
            var C = 64;
            if (Object.keys(this._contexts).length >= C) {
              var A = this._findOldestContextId();
              delete this._contexts[A];
            }
            var O = new c(S, w);
            return this._contexts[this._contextId(x, F, S, w)] = O, O;
          }
        },
        {
          key: "_getContext",
          value: function(x, F, S, w) {
            var C = this._contexts[this._contextId(x, F, S, w)];
            return C !== void 0 ? C : this._createContext(x, F, S, w);
          }
        },
        {
          key: "_resetContext",
          value: function(x, F, S, w) {
            delete this._contexts[this._contextId(x, F, S, w)];
          }
        },
        {
          key: "_resetAllContexts",
          value: function() {
            this._contexts = {};
          }
        },
        {
          key: "decodeRect",
          value: function(x, F, S, w, C, A, O) {
            var I = 1, Z = 2;
            if (C.rQwait("h264 header", 8)) return false;
            var q = C.rQshift32(), $ = C.rQshift32();
            if (C.rQwait("h264 payload", q, 8)) return false;
            $ & Z ? this._resetAllContexts() : $ & I && this._resetContext(x, F, S, w);
            var ne = this._getContext(x, F, S, w);
            if (ne.lastUsed = this._tick++, q !== 0) {
              var E = C.rQshiftBytes(q, false), p = ne.decode(E);
              p !== null && A.videoFrame(x, F, S, w, p);
            }
            return true;
          }
        }
      ]);
    }();
  })(gs);
  (function(e) {
    function t(G) {
      "@babel/helpers - typeof";
      return t = typeof Symbol == "function" && typeof Symbol.iterator == "symbol" ? function(R) {
        return typeof R;
      } : function(R) {
        return R && typeof Symbol == "function" && R.constructor === Symbol && R !== Symbol.prototype ? "symbol" : typeof R;
      }, t(G);
    }
    Object.defineProperty(e, "__esModule", {
      value: true
    }), e.default = void 0;
    var n = Nr, r = p(Re), i = jr, a = Ae, o = li, s = ar, y = ne(ci), u = ne(oo), l = ne(Hr), k = ne(wo), X = ne(Go), g = ne(ts), b = ne(rs), d = ne(ns), f = ne(Vr), c = ne(is), h = qr, K = ne(as), x = ne(bi), F = ne(cs), S = ne(hs), w = ne(ds), C = ne(_s), A = ne(ps), O = ne(Si), I = ne(vs), Z = ne(ys), q = ne(xs), $ = ne(gs);
    function ne(G) {
      return G && G.__esModule ? G : {
        default: G
      };
    }
    function E(G) {
      if (typeof WeakMap != "function") return null;
      var R = /* @__PURE__ */ new WeakMap(), D = /* @__PURE__ */ new WeakMap();
      return (E = function(T) {
        return T ? D : R;
      })(G);
    }
    function p(G, R) {
      if (G && G.__esModule) return G;
      if (G === null || t(G) != "object" && typeof G != "function") return {
        default: G
      };
      var D = E(R);
      if (D && D.has(G)) return D.get(G);
      var _ = {
        __proto__: null
      }, T = Object.defineProperty && Object.getOwnPropertyDescriptor;
      for (var v in G) if (v !== "default" && {}.hasOwnProperty.call(G, v)) {
        var H = T ? Object.getOwnPropertyDescriptor(G, v) : null;
        H && (H.get || H.set) ? Object.defineProperty(_, v, H) : _[v] = G[v];
      }
      return _.default = G, D && D.set(G, _), _;
    }
    function m() {
      m = function() {
        return R;
      };
      var G, R = {}, D = Object.prototype, _ = D.hasOwnProperty, T = Object.defineProperty || function(fe, ee, ue) {
        fe[ee] = ue.value;
      }, v = typeof Symbol == "function" ? Symbol : {}, H = v.iterator || "@@iterator", J = v.asyncIterator || "@@asyncIterator", te = v.toStringTag || "@@toStringTag";
      function ae(fe, ee, ue) {
        return Object.defineProperty(fe, ee, {
          value: ue,
          enumerable: true,
          configurable: true,
          writable: true
        }), fe[ee];
      }
      try {
        ae({}, "");
      } catch {
        ae = function(ue, xe, me) {
          return ue[xe] = me;
        };
      }
      function we(fe, ee, ue, xe) {
        var me = ee && ee.prototype instanceof We ? ee : We, be = Object.create(me.prototype), Ie = new Kn(xe || []);
        return T(be, "_invoke", {
          value: bs(fe, ue, Ie)
        }), be;
      }
      function Ce(fe, ee, ue) {
        try {
          return {
            type: "normal",
            arg: fe.call(ee, ue)
          };
        } catch (xe) {
          return {
            type: "throw",
            arg: xe
          };
        }
      }
      R.wrap = we;
      var Xe = "suspendedStart", Se = "suspendedYield", Te = "executing", _e = "completed", ke = {};
      function We() {
      }
      function lt() {
      }
      function Le() {
      }
      var ze = {};
      ae(ze, H, function() {
        return this;
      });
      var St = Object.getPrototypeOf, Ht = St && St(St(Xn([])));
      Ht && Ht !== D && _.call(Ht, H) && (ze = Ht);
      var Et = Le.prototype = We.prototype = Object.create(ze);
      function Ri(fe) {
        [
          "next",
          "throw",
          "return"
        ].forEach(function(ee) {
          ae(fe, ee, function(ue) {
            return this._invoke(ee, ue);
          });
        });
      }
      function en(fe, ee) {
        function ue(me, be, Ie, et) {
          var at = Ce(fe[me], fe, be);
          if (at.type !== "throw") {
            var Wt = at.arg, Rt = Wt.value;
            return Rt && t(Rt) == "object" && _.call(Rt, "__await") ? ee.resolve(Rt.__await).then(function(zt) {
              ue("next", zt, Ie, et);
            }, function(zt) {
              ue("throw", zt, Ie, et);
            }) : ee.resolve(Rt).then(function(zt) {
              Wt.value = zt, Ie(Wt);
            }, function(zt) {
              return ue("throw", zt, Ie, et);
            });
          }
          et(at.arg);
        }
        var xe;
        T(this, "_invoke", {
          value: function(be, Ie) {
            function et() {
              return new ee(function(at, Wt) {
                ue(be, Ie, at, Wt);
              });
            }
            return xe = xe ? xe.then(et, et) : et();
          }
        });
      }
      function bs(fe, ee, ue) {
        var xe = Xe;
        return function(me, be) {
          if (xe === Te) throw Error("Generator is already running");
          if (xe === _e) {
            if (me === "throw") throw be;
            return {
              value: G,
              done: true
            };
          }
          for (ue.method = me, ue.arg = be; ; ) {
            var Ie = ue.delegate;
            if (Ie) {
              var et = Mi(Ie, ue);
              if (et) {
                if (et === ke) continue;
                return et;
              }
            }
            if (ue.method === "next") ue.sent = ue._sent = ue.arg;
            else if (ue.method === "throw") {
              if (xe === Xe) throw xe = _e, ue.arg;
              ue.dispatchException(ue.arg);
            } else ue.method === "return" && ue.abrupt("return", ue.arg);
            xe = Te;
            var at = Ce(fe, ee, ue);
            if (at.type === "normal") {
              if (xe = ue.done ? _e : Se, at.arg === ke) continue;
              return {
                value: at.arg,
                done: ue.done
              };
            }
            at.type === "throw" && (xe = _e, ue.method = "throw", ue.arg = at.arg);
          }
        };
      }
      function Mi(fe, ee) {
        var ue = ee.method, xe = fe.iterator[ue];
        if (xe === G) return ee.delegate = null, ue === "throw" && fe.iterator.return && (ee.method = "return", ee.arg = G, Mi(fe, ee), ee.method === "throw") || ue !== "return" && (ee.method = "throw", ee.arg = new TypeError("The iterator does not provide a '" + ue + "' method")), ke;
        var me = Ce(xe, fe.iterator, ee.arg);
        if (me.type === "throw") return ee.method = "throw", ee.arg = me.arg, ee.delegate = null, ke;
        var be = me.arg;
        return be ? be.done ? (ee[fe.resultName] = be.value, ee.next = fe.nextLoc, ee.method !== "return" && (ee.method = "next", ee.arg = G), ee.delegate = null, ke) : be : (ee.method = "throw", ee.arg = new TypeError("iterator result is not an object"), ee.delegate = null, ke);
      }
      function ms(fe) {
        var ee = {
          tryLoc: fe[0]
        };
        1 in fe && (ee.catchLoc = fe[1]), 2 in fe && (ee.finallyLoc = fe[2], ee.afterLoc = fe[3]), this.tryEntries.push(ee);
      }
      function En(fe) {
        var ee = fe.completion || {};
        ee.type = "normal", delete ee.arg, fe.completion = ee;
      }
      function Kn(fe) {
        this.tryEntries = [
          {
            tryLoc: "root"
          }
        ], fe.forEach(ms, this), this.reset(true);
      }
      function Xn(fe) {
        if (fe || fe === "") {
          var ee = fe[H];
          if (ee) return ee.call(fe);
          if (typeof fe.next == "function") return fe;
          if (!isNaN(fe.length)) {
            var ue = -1, xe = function me() {
              for (; ++ue < fe.length; ) if (_.call(fe, ue)) return me.value = fe[ue], me.done = false, me;
              return me.value = G, me.done = true, me;
            };
            return xe.next = xe;
          }
        }
        throw new TypeError(t(fe) + " is not iterable");
      }
      return lt.prototype = Le, T(Et, "constructor", {
        value: Le,
        configurable: true
      }), T(Le, "constructor", {
        value: lt,
        configurable: true
      }), lt.displayName = ae(Le, te, "GeneratorFunction"), R.isGeneratorFunction = function(fe) {
        var ee = typeof fe == "function" && fe.constructor;
        return !!ee && (ee === lt || (ee.displayName || ee.name) === "GeneratorFunction");
      }, R.mark = function(fe) {
        return Object.setPrototypeOf ? Object.setPrototypeOf(fe, Le) : (fe.__proto__ = Le, ae(fe, te, "GeneratorFunction")), fe.prototype = Object.create(Et), fe;
      }, R.awrap = function(fe) {
        return {
          __await: fe
        };
      }, Ri(en.prototype), ae(en.prototype, J, function() {
        return this;
      }), R.AsyncIterator = en, R.async = function(fe, ee, ue, xe, me) {
        me === void 0 && (me = Promise);
        var be = new en(we(fe, ee, ue, xe), me);
        return R.isGeneratorFunction(ee) ? be : be.next().then(function(Ie) {
          return Ie.done ? Ie.value : be.next();
        });
      }, Ri(Et), ae(Et, te, "Generator"), ae(Et, H, function() {
        return this;
      }), ae(Et, "toString", function() {
        return "[object Generator]";
      }), R.keys = function(fe) {
        var ee = Object(fe), ue = [];
        for (var xe in ee) ue.push(xe);
        return ue.reverse(), function me() {
          for (; ue.length; ) {
            var be = ue.pop();
            if (be in ee) return me.value = be, me.done = false, me;
          }
          return me.done = true, me;
        };
      }, R.values = Xn, Kn.prototype = {
        constructor: Kn,
        reset: function(ee) {
          if (this.prev = 0, this.next = 0, this.sent = this._sent = G, this.done = false, this.delegate = null, this.method = "next", this.arg = G, this.tryEntries.forEach(En), !ee) for (var ue in this) ue.charAt(0) === "t" && _.call(this, ue) && !isNaN(+ue.slice(1)) && (this[ue] = G);
        },
        stop: function() {
          this.done = true;
          var ee = this.tryEntries[0].completion;
          if (ee.type === "throw") throw ee.arg;
          return this.rval;
        },
        dispatchException: function(ee) {
          if (this.done) throw ee;
          var ue = this;
          function xe(Wt, Rt) {
            return Ie.type = "throw", Ie.arg = ee, ue.next = Wt, Rt && (ue.method = "next", ue.arg = G), !!Rt;
          }
          for (var me = this.tryEntries.length - 1; me >= 0; --me) {
            var be = this.tryEntries[me], Ie = be.completion;
            if (be.tryLoc === "root") return xe("end");
            if (be.tryLoc <= this.prev) {
              var et = _.call(be, "catchLoc"), at = _.call(be, "finallyLoc");
              if (et && at) {
                if (this.prev < be.catchLoc) return xe(be.catchLoc, true);
                if (this.prev < be.finallyLoc) return xe(be.finallyLoc);
              } else if (et) {
                if (this.prev < be.catchLoc) return xe(be.catchLoc, true);
              } else {
                if (!at) throw Error("try statement without catch or finally");
                if (this.prev < be.finallyLoc) return xe(be.finallyLoc);
              }
            }
          }
        },
        abrupt: function(ee, ue) {
          for (var xe = this.tryEntries.length - 1; xe >= 0; --xe) {
            var me = this.tryEntries[xe];
            if (me.tryLoc <= this.prev && _.call(me, "finallyLoc") && this.prev < me.finallyLoc) {
              var be = me;
              break;
            }
          }
          be && (ee === "break" || ee === "continue") && be.tryLoc <= ue && ue <= be.finallyLoc && (be = null);
          var Ie = be ? be.completion : {};
          return Ie.type = ee, Ie.arg = ue, be ? (this.method = "next", this.next = be.finallyLoc, ke) : this.complete(Ie);
        },
        complete: function(ee, ue) {
          if (ee.type === "throw") throw ee.arg;
          return ee.type === "break" || ee.type === "continue" ? this.next = ee.arg : ee.type === "return" ? (this.rval = this.arg = ee.arg, this.method = "return", this.next = "end") : ee.type === "normal" && ue && (this.next = ue), ke;
        },
        finish: function(ee) {
          for (var ue = this.tryEntries.length - 1; ue >= 0; --ue) {
            var xe = this.tryEntries[ue];
            if (xe.finallyLoc === ee) return this.complete(xe.completion, xe.afterLoc), En(xe), ke;
          }
        },
        catch: function(ee) {
          for (var ue = this.tryEntries.length - 1; ue >= 0; --ue) {
            var xe = this.tryEntries[ue];
            if (xe.tryLoc === ee) {
              var me = xe.completion;
              if (me.type === "throw") {
                var be = me.arg;
                En(xe);
              }
              return be;
            }
          }
          throw Error("illegal catch attempt");
        },
        delegateYield: function(ee, ue, xe) {
          return this.delegate = {
            iterator: Xn(ee),
            resultName: ue,
            nextLoc: xe
          }, this.method === "next" && (this.arg = G), ke;
        }
      }, R;
    }
    function L(G, R, D, _, T, v, H) {
      try {
        var J = G[v](H), te = J.value;
      } catch (ae) {
        return void D(ae);
      }
      J.done ? R(te) : Promise.resolve(te).then(_, T);
    }
    function B(G) {
      return function() {
        var R = this, D = arguments;
        return new Promise(function(_, T) {
          var v = G.apply(R, D);
          function H(te) {
            L(v, _, T, H, J, "next", te);
          }
          function J(te) {
            L(v, _, T, H, J, "throw", te);
          }
          H(void 0);
        });
      };
    }
    function M(G, R) {
      return oe(G) || re(G, R) || pe(G, R) || V();
    }
    function V() {
      throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
    }
    function re(G, R) {
      var D = G == null ? null : typeof Symbol < "u" && G[Symbol.iterator] || G["@@iterator"];
      if (D != null) {
        var _, T, v, H, J = [], te = true, ae = false;
        try {
          if (v = (D = D.call(G)).next, R !== 0) for (; !(te = (_ = v.call(D)).done) && (J.push(_.value), J.length !== R); te = true) ;
        } catch (we) {
          ae = true, T = we;
        } finally {
          try {
            if (!te && D.return != null && (H = D.return(), Object(H) !== H)) return;
          } finally {
            if (ae) throw T;
          }
        }
        return J;
      }
    }
    function oe(G) {
      if (Array.isArray(G)) return G;
    }
    function ce(G, R) {
      var D = typeof Symbol < "u" && G[Symbol.iterator] || G["@@iterator"];
      if (!D) {
        if (Array.isArray(G) || (D = pe(G)) || R) {
          D && (G = D);
          var _ = 0, T = function() {
          };
          return {
            s: T,
            n: function() {
              return _ >= G.length ? {
                done: true
              } : {
                done: false,
                value: G[_++]
              };
            },
            e: function(ae) {
              throw ae;
            },
            f: T
          };
        }
        throw new TypeError(`Invalid attempt to iterate non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`);
      }
      var v, H = true, J = false;
      return {
        s: function() {
          D = D.call(G);
        },
        n: function() {
          var ae = D.next();
          return H = ae.done, ae;
        },
        e: function(ae) {
          J = true, v = ae;
        },
        f: function() {
          try {
            H || D.return == null || D.return();
          } finally {
            if (J) throw v;
          }
        }
      };
    }
    function pe(G, R) {
      if (G) {
        if (typeof G == "string") return ye(G, R);
        var D = {}.toString.call(G).slice(8, -1);
        return D === "Object" && G.constructor && (D = G.constructor.name), D === "Map" || D === "Set" ? Array.from(G) : D === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(D) ? ye(G, R) : void 0;
      }
    }
    function ye(G, R) {
      (R == null || R > G.length) && (R = G.length);
      for (var D = 0, _ = Array(R); D < R; D++) _[D] = G[D];
      return _;
    }
    function Ne(G, R) {
      if (!(G instanceof R)) throw new TypeError("Cannot call a class as a function");
    }
    function je(G, R) {
      for (var D = 0; D < R.length; D++) {
        var _ = R[D];
        _.enumerable = _.enumerable || false, _.configurable = true, "value" in _ && (_.writable = true), Object.defineProperty(G, Ue(_.key), _);
      }
    }
    function ut(G, R, D) {
      return R && je(G.prototype, R), D && je(G, D), Object.defineProperty(G, "prototype", {
        writable: false
      }), G;
    }
    function Ue(G) {
      var R = He(G, "string");
      return t(R) == "symbol" ? R : R + "";
    }
    function He(G, R) {
      if (t(G) != "object" || !G) return G;
      var D = G[Symbol.toPrimitive];
      if (D !== void 0) {
        var _ = D.call(G, R);
        if (t(_) != "object") return _;
        throw new TypeError("@@toPrimitive must return a primitive value.");
      }
      return String(G);
    }
    function nt(G, R, D) {
      return R = ht(R), Lt(G, Je() ? Reflect.construct(R, [], ht(G).constructor) : R.apply(G, D));
    }
    function Lt(G, R) {
      if (R && (t(R) == "object" || typeof R == "function")) return R;
      if (R !== void 0) throw new TypeError("Derived constructors may only return object or undefined");
      return it(G);
    }
    function it(G) {
      if (G === void 0) throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
      return G;
    }
    function Je() {
      try {
        var G = !Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function() {
        }));
      } catch {
      }
      return (Je = function() {
        return !!G;
      })();
    }
    function ht(G) {
      return ht = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function(R) {
        return R.__proto__ || Object.getPrototypeOf(R);
      }, ht(G);
    }
    function se(G, R) {
      if (typeof R != "function" && R !== null) throw new TypeError("Super expression must either be null or a function");
      G.prototype = Object.create(R && R.prototype, {
        constructor: {
          value: G,
          writable: true,
          configurable: true
        }
      }), Object.defineProperty(G, "prototype", {
        writable: false
      }), R && Y(G, R);
    }
    function Y(G, R) {
      return Y = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function(D, _) {
        return D.__proto__ = _, D;
      }, Y(G, R);
    }
    var ie = 3, he = "rgb(40, 40, 40)", ve = 17, de = 50, Pe = 19, Me = 75, Oe = 50, le = 1e3, bt = 50, mt = 1, Yr = 2, Ei = 6, Ki = 16, Sn = 19, Xi = 22, Fi = 30, Ci = 113, Ai = 129, Pi = 256, wt = 1, Ti = 1 << 24, $r = 1 << 25, Li = 1 << 26, kr = 1 << 27, Jr = 1 << 28, kt = e.default = function(G) {
      function R(D, _, T) {
        var v;
        if (Ne(this, R), !D) throw new Error("Must specify target");
        if (!_) throw new Error("Must specify URL, WebSocket or RTCDataChannel");
        window.isSecureContext || r.Error("noVNC requires a secure context (TLS). Expect crashes!"), v = nt(this, R), v._target = D, typeof _ == "string" ? v._url = _ : (v._url = null, v._rawChannel = _), T = T || {}, v._rfbCredentials = T.credentials || {}, v._shared = "shared" in T ? !!T.shared : true, v._repeaterID = T.repeaterID || "", v._wsProtocols = T.wsProtocols || [], v._rfbConnectionState = "", v._rfbInitState = "", v._rfbAuthScheme = -1, v._rfbCleanDisconnect = true, v._rfbRSAAESAuthenticationState = null, v._rfbVersion = 0, v._rfbMaxVersion = 3.8, v._rfbTightVNC = false, v._rfbVeNCryptState = 0, v._rfbXvpVer = 0, v._fbWidth = 0, v._fbHeight = 0, v._fbName = "", v._capabilities = {
          power: false
        }, v._supportsFence = false, v._supportsContinuousUpdates = false, v._enabledContinuousUpdates = false, v._supportsSetDesktopSize = false, v._screenID = 0, v._screenFlags = 0, v._pendingRemoteResize = false, v._lastResize = 0, v._qemuExtKeyEventSupported = false, v._extendedPointerEventSupported = false, v._clipboardText = null, v._clipboardServerCapabilitiesActions = {}, v._clipboardServerCapabilitiesFormats = {}, v._sock = null, v._display = null, v._flushing = false, v._keyboard = null, v._gestures = null, v._resizeObserver = null, v._disconnTimer = null, v._resizeTimeout = null, v._mouseMoveTimer = null, v._decoders = {}, v._FBU = {
          rects: 0,
          x: 0,
          y: 0,
          width: 0,
          height: 0,
          encoding: null
        }, v._mousePos = {}, v._mouseButtonMask = 0, v._mouseLastMoveTime = 0, v._viewportDragging = false, v._viewportDragPos = {}, v._viewportHasMoved = false, v._accumulatedWheelDeltaX = 0, v._accumulatedWheelDeltaY = 0, v._gestureLastTapTime = null, v._gestureFirstDoubleTapEv = null, v._gestureLastMagnitudeX = 0, v._gestureLastMagnitudeY = 0, v._eventHandlers = {
          focusCanvas: v._focusCanvas.bind(v),
          handleResize: v._handleResize.bind(v),
          handleMouse: v._handleMouse.bind(v),
          handleWheel: v._handleWheel.bind(v),
          handleGesture: v._handleGesture.bind(v),
          handleRSAAESCredentialsRequired: v._handleRSAAESCredentialsRequired.bind(v),
          handleRSAAESServerVerification: v._handleRSAAESServerVerification.bind(v)
        }, r.Debug(">> RFB.constructor"), v._screen = document.createElement("div"), v._screen.style.display = "flex", v._screen.style.width = "100%", v._screen.style.height = "100%", v._screen.style.overflow = "auto", v._screen.style.background = he, v._canvas = document.createElement("canvas"), v._canvas.style.margin = "auto", v._canvas.style.outline = "none", v._canvas.width = 0, v._canvas.height = 0, v._canvas.tabIndex = -1, v._screen.appendChild(v._canvas), v._cursor = new b.default(), v._cursorImage = R.cursors.none, v._decoders[h.encodings.encodingRaw] = new F.default(), v._decoders[h.encodings.encodingCopyRect] = new S.default(), v._decoders[h.encodings.encodingRRE] = new w.default(), v._decoders[h.encodings.encodingHextile] = new C.default(), v._decoders[h.encodings.encodingZlib] = new A.default(), v._decoders[h.encodings.encodingTight] = new O.default(), v._decoders[h.encodings.encodingTightPNG] = new I.default(), v._decoders[h.encodings.encodingZRLE] = new Z.default(), v._decoders[h.encodings.encodingJPEG] = new q.default(), v._decoders[h.encodings.encodingH264] = new $.default();
        try {
          v._display = new u.default(v._canvas);
        } catch (H) {
          throw r.Error("Display exception: " + H), H;
        }
        return v._keyboard = new X.default(v._canvas), v._keyboard.onkeyevent = v._handleKeyEvent.bind(v), v._remoteCapsLock = null, v._remoteNumLock = null, v._gestures = new g.default(), v._sock = new d.default(), v._sock.on("open", v._socketOpen.bind(v)), v._sock.on("close", v._socketClose.bind(v)), v._sock.on("message", v._handleMessage.bind(v)), v._sock.on("error", v._socketError.bind(v)), v._expectedClientWidth = null, v._expectedClientHeight = null, v._resizeObserver = new ResizeObserver(v._eventHandlers.handleResize), v._updateConnectionState("connecting"), r.Debug("<< RFB.constructor"), v.dragViewport = false, v.focusOnClick = true, v._viewOnly = false, v._clipViewport = false, v._clippingViewport = false, v._scaleViewport = false, v._resizeSession = false, v._showDotCursor = false, T.showDotCursor !== void 0 && (r.Warn("Specifying showDotCursor as a RFB constructor argument is deprecated"), v._showDotCursor = T.showDotCursor), v._qualityLevel = 6, v._compressionLevel = 2, v;
      }
      return se(R, G), ut(R, [
        {
          key: "viewOnly",
          get: function() {
            return this._viewOnly;
          },
          set: function(_) {
            this._viewOnly = _, (this._rfbConnectionState === "connecting" || this._rfbConnectionState === "connected") && (_ ? this._keyboard.ungrab() : this._keyboard.grab());
          }
        },
        {
          key: "capabilities",
          get: function() {
            return this._capabilities;
          }
        },
        {
          key: "clippingViewport",
          get: function() {
            return this._clippingViewport;
          }
        },
        {
          key: "_setClippingViewport",
          value: function(_) {
            _ !== this._clippingViewport && (this._clippingViewport = _, this.dispatchEvent(new CustomEvent("clippingviewport", {
              detail: this._clippingViewport
            })));
          }
        },
        {
          key: "touchButton",
          get: function() {
            return 0;
          },
          set: function(_) {
            r.Warn("Using old API!");
          }
        },
        {
          key: "clipViewport",
          get: function() {
            return this._clipViewport;
          },
          set: function(_) {
            this._clipViewport = _, this._updateClip();
          }
        },
        {
          key: "scaleViewport",
          get: function() {
            return this._scaleViewport;
          },
          set: function(_) {
            this._scaleViewport = _, _ && this._clipViewport && this._updateClip(), this._updateScale(), !_ && this._clipViewport && this._updateClip();
          }
        },
        {
          key: "resizeSession",
          get: function() {
            return this._resizeSession;
          },
          set: function(_) {
            this._resizeSession = _, _ && this._requestRemoteResize();
          }
        },
        {
          key: "showDotCursor",
          get: function() {
            return this._showDotCursor;
          },
          set: function(_) {
            this._showDotCursor = _, this._refreshCursor();
          }
        },
        {
          key: "background",
          get: function() {
            return this._screen.style.background;
          },
          set: function(_) {
            this._screen.style.background = _;
          }
        },
        {
          key: "qualityLevel",
          get: function() {
            return this._qualityLevel;
          },
          set: function(_) {
            if (!Number.isInteger(_) || _ < 0 || _ > 9) {
              r.Error("qualityLevel must be an integer between 0 and 9");
              return;
            }
            this._qualityLevel !== _ && (this._qualityLevel = _, this._rfbConnectionState === "connected" && this._sendEncodings());
          }
        },
        {
          key: "compressionLevel",
          get: function() {
            return this._compressionLevel;
          },
          set: function(_) {
            if (!Number.isInteger(_) || _ < 0 || _ > 9) {
              r.Error("compressionLevel must be an integer between 0 and 9");
              return;
            }
            this._compressionLevel !== _ && (this._compressionLevel = _, this._rfbConnectionState === "connected" && this._sendEncodings());
          }
        },
        {
          key: "disconnect",
          value: function() {
            this._updateConnectionState("disconnecting"), this._sock.off("error"), this._sock.off("message"), this._sock.off("open"), this._rfbRSAAESAuthenticationState !== null && this._rfbRSAAESAuthenticationState.disconnect();
          }
        },
        {
          key: "approveServer",
          value: function() {
            this._rfbRSAAESAuthenticationState !== null && this._rfbRSAAESAuthenticationState.approveServer();
          }
        },
        {
          key: "sendCredentials",
          value: function(_) {
            this._rfbCredentials = _, this._resumeAuthentication();
          }
        },
        {
          key: "sendCtrlAltDel",
          value: function() {
            this._rfbConnectionState !== "connected" || this._viewOnly || (r.Info("Sending Ctrl-Alt-Del"), this.sendKey(f.default.XK_Control_L, "ControlLeft", true), this.sendKey(f.default.XK_Alt_L, "AltLeft", true), this.sendKey(f.default.XK_Delete, "Delete", true), this.sendKey(f.default.XK_Delete, "Delete", false), this.sendKey(f.default.XK_Alt_L, "AltLeft", false), this.sendKey(f.default.XK_Control_L, "ControlLeft", false));
          }
        },
        {
          key: "machineShutdown",
          value: function() {
            this._xvpOp(1, 2);
          }
        },
        {
          key: "machineReboot",
          value: function() {
            this._xvpOp(1, 3);
          }
        },
        {
          key: "machineReset",
          value: function() {
            this._xvpOp(1, 4);
          }
        },
        {
          key: "sendKey",
          value: function(_, T, v) {
            if (!(this._rfbConnectionState !== "connected" || this._viewOnly)) {
              if (v === void 0) {
                this.sendKey(_, T, true), this.sendKey(_, T, false);
                return;
              }
              var H = c.default[T];
              if (this._qemuExtKeyEventSupported && H) _ = _ || 0, r.Info("Sending key (" + (v ? "down" : "up") + "): keysym " + _ + ", scancode " + H), R.messages.QEMUExtendedKeyEvent(this._sock, _, v, H);
              else {
                if (!_) return;
                r.Info("Sending keysym (" + (v ? "down" : "up") + "): " + _), R.messages.keyEvent(this._sock, _, v ? 1 : 0);
              }
            }
          }
        },
        {
          key: "focus",
          value: function(_) {
            this._canvas.focus(_);
          }
        },
        {
          key: "blur",
          value: function() {
            this._canvas.blur();
          }
        },
        {
          key: "clipboardPasteFrom",
          value: function(_) {
            if (!(this._rfbConnectionState !== "connected" || this._viewOnly)) if (this._clipboardServerCapabilitiesFormats[wt] && this._clipboardServerCapabilitiesActions[kr]) this._clipboardText = _, R.messages.extendedClipboardNotify(this._sock, [
              wt
            ]);
            else {
              var T, v, H;
              T = 0;
              var J = ce(_), te;
              try {
                for (J.s(); !(te = J.n()).done; ) {
                  var ae = te.value;
                  T++;
                }
              } catch (Te) {
                J.e(Te);
              } finally {
                J.f();
              }
              H = new Uint8Array(T), v = 0;
              var we = ce(_), Ce;
              try {
                for (we.s(); !(Ce = we.n()).done; ) {
                  var Xe = Ce.value, Se = Xe.codePointAt(0);
                  Se > 255 && (Se = 63), H[v++] = Se;
                }
              } catch (Te) {
                we.e(Te);
              } finally {
                we.f();
              }
              R.messages.clientCutText(this._sock, H);
            }
          }
        },
        {
          key: "getImageData",
          value: function() {
            return this._display.getImageData();
          }
        },
        {
          key: "toDataURL",
          value: function(_, T) {
            return this._display.toDataURL(_, T);
          }
        },
        {
          key: "toBlob",
          value: function(_, T, v) {
            return this._display.toBlob(_, T, v);
          }
        },
        {
          key: "_connect",
          value: function() {
            if (r.Debug(">> RFB.connect"), this._url) r.Info("connecting to ".concat(this._url)), this._sock.open(this._url, this._wsProtocols);
            else {
              if (r.Info("attaching ".concat(this._rawChannel, " to Websock")), this._sock.attach(this._rawChannel), this._sock.readyState === "closed") throw Error("Cannot use already closed WebSocket/RTCDataChannel");
              this._sock.readyState === "open" && this._socketOpen();
            }
            this._target.appendChild(this._screen), this._gestures.attach(this._canvas), this._cursor.attach(this._canvas), this._refreshCursor(), this._resizeObserver.observe(this._screen), this._canvas.addEventListener("mousedown", this._eventHandlers.focusCanvas), this._canvas.addEventListener("touchstart", this._eventHandlers.focusCanvas), this._canvas.addEventListener("mousedown", this._eventHandlers.handleMouse), this._canvas.addEventListener("mouseup", this._eventHandlers.handleMouse), this._canvas.addEventListener("mousemove", this._eventHandlers.handleMouse), this._canvas.addEventListener("click", this._eventHandlers.handleMouse), this._canvas.addEventListener("contextmenu", this._eventHandlers.handleMouse), this._canvas.addEventListener("wheel", this._eventHandlers.handleWheel), this._canvas.addEventListener("gesturestart", this._eventHandlers.handleGesture), this._canvas.addEventListener("gesturemove", this._eventHandlers.handleGesture), this._canvas.addEventListener("gestureend", this._eventHandlers.handleGesture), r.Debug("<< RFB.connect");
          }
        },
        {
          key: "_disconnect",
          value: function() {
            r.Debug(">> RFB.disconnect"), this._cursor.detach(), this._canvas.removeEventListener("gesturestart", this._eventHandlers.handleGesture), this._canvas.removeEventListener("gesturemove", this._eventHandlers.handleGesture), this._canvas.removeEventListener("gestureend", this._eventHandlers.handleGesture), this._canvas.removeEventListener("wheel", this._eventHandlers.handleWheel), this._canvas.removeEventListener("mousedown", this._eventHandlers.handleMouse), this._canvas.removeEventListener("mouseup", this._eventHandlers.handleMouse), this._canvas.removeEventListener("mousemove", this._eventHandlers.handleMouse), this._canvas.removeEventListener("click", this._eventHandlers.handleMouse), this._canvas.removeEventListener("contextmenu", this._eventHandlers.handleMouse), this._canvas.removeEventListener("mousedown", this._eventHandlers.focusCanvas), this._canvas.removeEventListener("touchstart", this._eventHandlers.focusCanvas), this._resizeObserver.disconnect(), this._keyboard.ungrab(), this._gestures.detach(), this._sock.close();
            try {
              this._target.removeChild(this._screen);
            } catch (_) {
              if (_.name !== "NotFoundError") throw _;
            }
            clearTimeout(this._resizeTimeout), clearTimeout(this._mouseMoveTimer), r.Debug("<< RFB.disconnect");
          }
        },
        {
          key: "_socketOpen",
          value: function() {
            this._rfbConnectionState === "connecting" && this._rfbInitState === "" ? (this._rfbInitState = "ProtocolVersion", r.Debug("Starting VNC handshake")) : this._fail("Unexpected server connection while " + this._rfbConnectionState);
          }
        },
        {
          key: "_socketClose",
          value: function(_) {
            r.Debug("WebSocket on-close event");
            var T = "";
            switch (_.code && (T = "(code: " + _.code, _.reason && (T += ", reason: " + _.reason), T += ")"), this._rfbConnectionState) {
              case "connecting":
                this._fail("Connection closed " + T);
                break;
              case "connected":
                this._updateConnectionState("disconnecting"), this._updateConnectionState("disconnected");
                break;
              case "disconnecting":
                this._updateConnectionState("disconnected");
                break;
              case "disconnected":
                this._fail("Unexpected server disconnect when already disconnected " + T);
                break;
              default:
                this._fail("Unexpected server disconnect before connecting " + T);
                break;
            }
            this._sock.off("close"), this._rawChannel = null;
          }
        },
        {
          key: "_socketError",
          value: function(_) {
            r.Warn("WebSocket on-error event");
          }
        },
        {
          key: "_focusCanvas",
          value: function(_) {
            this.focusOnClick && this.focus({
              preventScroll: true
            });
          }
        },
        {
          key: "_setDesktopName",
          value: function(_) {
            this._fbName = _, this.dispatchEvent(new CustomEvent("desktopname", {
              detail: {
                name: this._fbName
              }
            }));
          }
        },
        {
          key: "_saveExpectedClientSize",
          value: function() {
            this._expectedClientWidth = this._screen.clientWidth, this._expectedClientHeight = this._screen.clientHeight;
          }
        },
        {
          key: "_currentClientSize",
          value: function() {
            return [
              this._screen.clientWidth,
              this._screen.clientHeight
            ];
          }
        },
        {
          key: "_clientHasExpectedSize",
          value: function() {
            var _ = this._currentClientSize(), T = M(_, 2), v = T[0], H = T[1];
            return v == this._expectedClientWidth && H == this._expectedClientHeight;
          }
        },
        {
          key: "_handleResize",
          value: function() {
            var _ = this;
            this._clientHasExpectedSize() || (window.requestAnimationFrame(function() {
              _._updateClip(), _._updateScale(), _._saveExpectedClientSize();
            }), this._requestRemoteResize());
          }
        },
        {
          key: "_updateClip",
          value: function() {
            var _ = this._display.clipViewport, T = this._clipViewport;
            if (this._scaleViewport && (T = false), _ !== T && (this._display.clipViewport = T), T) {
              var v = this._screenSize();
              this._display.viewportChangeSize(v.w, v.h), this._fixScrollbars(), this._setClippingViewport(v.w < this._display.width || v.h < this._display.height);
            } else this._setClippingViewport(false);
            _ !== T && this._saveExpectedClientSize();
          }
        },
        {
          key: "_updateScale",
          value: function() {
            if (!this._scaleViewport) this._display.scale = 1;
            else {
              var _ = this._screenSize();
              this._display.autoscale(_.w, _.h);
            }
            this._fixScrollbars();
          }
        },
        {
          key: "_requestRemoteResize",
          value: function() {
            if (this._resizeSession && !this._viewOnly && this._supportsSetDesktopSize && !this._pendingRemoteResize) {
              if (Date.now() - this._lastResize < 100) {
                clearTimeout(this._resizeTimeout), this._resizeTimeout = setTimeout(this._requestRemoteResize.bind(this), 100 - (Date.now() - this._lastResize));
                return;
              }
              this._resizeTimeout = null;
              var _ = this._screenSize();
              _.w === this._fbWidth && _.h === this._fbHeight || (this._pendingRemoteResize = true, this._lastResize = Date.now(), R.messages.setDesktopSize(this._sock, Math.floor(_.w), Math.floor(_.h), this._screenID, this._screenFlags), r.Debug("Requested new desktop size: " + _.w + "x" + _.h));
            }
          }
        },
        {
          key: "_screenSize",
          value: function() {
            var _ = this._screen.getBoundingClientRect();
            return {
              w: _.width,
              h: _.height
            };
          }
        },
        {
          key: "_fixScrollbars",
          value: function() {
            var _ = this._screen.style.overflow;
            this._screen.style.overflow = "hidden", this._screen.getBoundingClientRect(), this._screen.style.overflow = _;
          }
        },
        {
          key: "_updateConnectionState",
          value: function(_) {
            var T = this, v = this._rfbConnectionState;
            if (_ === v) {
              r.Debug("Already in state '" + _ + "', ignoring");
              return;
            }
            if (v === "disconnected") {
              r.Error("Tried changing state of a disconnected RFB object");
              return;
            }
            switch (_) {
              case "connected":
                if (v !== "connecting") {
                  r.Error("Bad transition to connected state, previous connection state: " + v);
                  return;
                }
                break;
              case "disconnected":
                if (v !== "disconnecting") {
                  r.Error("Bad transition to disconnected state, previous connection state: " + v);
                  return;
                }
                break;
              case "connecting":
                if (v !== "") {
                  r.Error("Bad transition to connecting state, previous connection state: " + v);
                  return;
                }
                break;
              case "disconnecting":
                if (v !== "connected" && v !== "connecting") {
                  r.Error("Bad transition to disconnecting state, previous connection state: " + v);
                  return;
                }
                break;
              default:
                r.Error("Unknown connection state: " + _);
                return;
            }
            switch (this._rfbConnectionState = _, r.Debug("New state '" + _ + "', was '" + v + "'."), this._disconnTimer && _ !== "disconnecting" && (r.Debug("Clearing disconnect timer"), clearTimeout(this._disconnTimer), this._disconnTimer = null, this._sock.off("close")), _) {
              case "connecting":
                this._connect();
                break;
              case "connected":
                this.dispatchEvent(new CustomEvent("connect", {
                  detail: {}
                }));
                break;
              case "disconnecting":
                this._disconnect(), this._disconnTimer = setTimeout(function() {
                  r.Error("Disconnection timed out."), T._updateConnectionState("disconnected");
                }, ie * 1e3);
                break;
              case "disconnected":
                this.dispatchEvent(new CustomEvent("disconnect", {
                  detail: {
                    clean: this._rfbCleanDisconnect
                  }
                }));
                break;
            }
          }
        },
        {
          key: "_fail",
          value: function(_) {
            switch (this._rfbConnectionState) {
              case "disconnecting":
                r.Error("Failed when disconnecting: " + _);
                break;
              case "connected":
                r.Error("Failed while connected: " + _);
                break;
              case "connecting":
                r.Error("Failed when connecting: " + _);
                break;
              default:
                r.Error("RFB failure: " + _);
                break;
            }
            return this._rfbCleanDisconnect = false, this._updateConnectionState("disconnecting"), this._updateConnectionState("disconnected"), false;
          }
        },
        {
          key: "_setCapability",
          value: function(_, T) {
            this._capabilities[_] = T, this.dispatchEvent(new CustomEvent("capabilities", {
              detail: {
                capabilities: this._capabilities
              }
            }));
          }
        },
        {
          key: "_handleMessage",
          value: function() {
            if (this._sock.rQwait("message", 1)) {
              r.Warn("handleMessage called on an empty receive queue");
              return;
            }
            switch (this._rfbConnectionState) {
              case "disconnected":
                r.Error("Got data while disconnected");
                break;
              case "connected":
                for (; !(this._flushing || !this._normalMsg() || this._sock.rQwait("message", 1)); ) ;
                break;
              case "connecting":
                for (; this._rfbConnectionState === "connecting" && this._initMsg(); ) ;
                break;
              default:
                r.Error("Got data while in an invalid state");
                break;
            }
          }
        },
        {
          key: "_handleKeyEvent",
          value: function(_, T, v, H, J) {
            T == "CapsLock" && v && (this._remoteCapsLock = null), this._remoteCapsLock !== null && J !== null && this._remoteCapsLock !== J && v && (r.Debug("Fixing remote caps lock"), this.sendKey(f.default.XK_Caps_Lock, "CapsLock", true), this.sendKey(f.default.XK_Caps_Lock, "CapsLock", false), this._remoteCapsLock = null), T == "NumLock" && v && (this._remoteNumLock = null), this._remoteNumLock !== null && H !== null && this._remoteNumLock !== H && v && (r.Debug("Fixing remote num lock"), this.sendKey(f.default.XK_Num_Lock, "NumLock", true), this.sendKey(f.default.XK_Num_Lock, "NumLock", false), this._remoteNumLock = null), this.sendKey(_, T, v);
          }
        },
        {
          key: "_handleMouse",
          value: function(_) {
            if (!(_.type === "click" && _.target !== this._canvas) && (_.stopPropagation(), _.preventDefault(), !(_.type === "click" || _.type === "contextmenu"))) {
              var T = (0, o.clientToElement)(_.clientX, _.clientY, this._canvas), v = R._convertButtonMask(_.buttons), H = _.type == "mousedown";
              switch (_.type) {
                case "mousedown":
                case "mouseup":
                  if (this.dragViewport) if (H && !this._viewportDragging) {
                    this._viewportDragging = true, this._viewportDragPos = {
                      x: T.x,
                      y: T.y
                    }, this._viewportHasMoved = false, this._flushMouseMoveTimer(T.x, T.y), this._mouseButtonMask = v;
                    break;
                  } else {
                    if (this._viewportDragging = false, this._viewportHasMoved) {
                      this._mouseButtonMask = v;
                      break;
                    }
                    this._sendMouse(T.x, T.y, this._mouseButtonMask);
                  }
                  H && (0, s.setCapture)(this._canvas), this._handleMouseButton(T.x, T.y, v);
                  break;
                case "mousemove":
                  if (this._viewportDragging) {
                    var J = this._viewportDragPos.x - T.x, te = this._viewportDragPos.y - T.y;
                    (this._viewportHasMoved || Math.abs(J) > a.dragThreshold || Math.abs(te) > a.dragThreshold) && (this._viewportHasMoved = true, this._viewportDragPos = {
                      x: T.x,
                      y: T.y
                    }, this._display.viewportChangePos(J, te));
                    break;
                  }
                  this._handleMouseMove(T.x, T.y);
                  break;
              }
            }
          }
        },
        {
          key: "_handleMouseButton",
          value: function(_, T, v) {
            this._flushMouseMoveTimer(_, T), this._mouseButtonMask = v, this._sendMouse(_, T, this._mouseButtonMask);
          }
        },
        {
          key: "_handleMouseMove",
          value: function(_, T) {
            var v = this;
            if (this._mousePos = {
              x: _,
              y: T
            }, this._mouseMoveTimer == null) {
              var H = Date.now() - this._mouseLastMoveTime;
              H > ve ? (this._sendMouse(_, T, this._mouseButtonMask), this._mouseLastMoveTime = Date.now()) : this._mouseMoveTimer = setTimeout(function() {
                v._handleDelayedMouseMove();
              }, ve - H);
            }
          }
        },
        {
          key: "_handleDelayedMouseMove",
          value: function() {
            this._mouseMoveTimer = null, this._sendMouse(this._mousePos.x, this._mousePos.y, this._mouseButtonMask), this._mouseLastMoveTime = Date.now();
          }
        },
        {
          key: "_sendMouse",
          value: function(_, T, v) {
            if (this._rfbConnectionState === "connected" && !this._viewOnly) {
              if (v & 32768) throw new Error("Illegal mouse button mask (mask: " + v + ")");
              var H = v & 32640;
              this._extendedPointerEventSupported && H ? R.messages.extendedPointerEvent(this._sock, this._display.absX(_), this._display.absY(T), v) : R.messages.pointerEvent(this._sock, this._display.absX(_), this._display.absY(T), v);
            }
          }
        },
        {
          key: "_handleWheel",
          value: function(_) {
            if (this._rfbConnectionState === "connected" && !this._viewOnly) {
              _.stopPropagation(), _.preventDefault();
              var T = (0, o.clientToElement)(_.clientX, _.clientY, this._canvas), v = R._convertButtonMask(_.buttons), H = _.deltaX, J = _.deltaY;
              _.deltaMode !== 0 && (H *= Pe, J *= Pe), this._accumulatedWheelDeltaX += H, this._accumulatedWheelDeltaY += J, Math.abs(this._accumulatedWheelDeltaX) >= de && (this._accumulatedWheelDeltaX < 0 ? (this._handleMouseButton(T.x, T.y, v | 32), this._handleMouseButton(T.x, T.y, v)) : this._accumulatedWheelDeltaX > 0 && (this._handleMouseButton(T.x, T.y, v | 64), this._handleMouseButton(T.x, T.y, v)), this._accumulatedWheelDeltaX = 0), Math.abs(this._accumulatedWheelDeltaY) >= de && (this._accumulatedWheelDeltaY < 0 ? (this._handleMouseButton(T.x, T.y, v | 8), this._handleMouseButton(T.x, T.y, v)) : this._accumulatedWheelDeltaY > 0 && (this._handleMouseButton(T.x, T.y, v | 16), this._handleMouseButton(T.x, T.y, v)), this._accumulatedWheelDeltaY = 0);
            }
          }
        },
        {
          key: "_fakeMouseMove",
          value: function(_, T, v) {
            this._handleMouseMove(T, v), this._cursor.move(_.detail.clientX, _.detail.clientY);
          }
        },
        {
          key: "_handleTapEvent",
          value: function(_, T) {
            var v = (0, o.clientToElement)(_.detail.clientX, _.detail.clientY, this._canvas);
            if (this._gestureLastTapTime !== null && Date.now() - this._gestureLastTapTime < le && this._gestureFirstDoubleTapEv.detail.type === _.detail.type) {
              var H = this._gestureFirstDoubleTapEv.detail.clientX - _.detail.clientX, J = this._gestureFirstDoubleTapEv.detail.clientY - _.detail.clientY, te = Math.hypot(H, J);
              te < bt ? v = (0, o.clientToElement)(this._gestureFirstDoubleTapEv.detail.clientX, this._gestureFirstDoubleTapEv.detail.clientY, this._canvas) : this._gestureFirstDoubleTapEv = _;
            } else this._gestureFirstDoubleTapEv = _;
            this._gestureLastTapTime = Date.now(), this._fakeMouseMove(this._gestureFirstDoubleTapEv, v.x, v.y), this._handleMouseButton(v.x, v.y, T), this._handleMouseButton(v.x, v.y, 0);
          }
        },
        {
          key: "_handleGesture",
          value: function(_) {
            var T, v = (0, o.clientToElement)(_.detail.clientX, _.detail.clientY, this._canvas);
            switch (_.type) {
              case "gesturestart":
                switch (_.detail.type) {
                  case "onetap":
                    this._handleTapEvent(_, 1);
                    break;
                  case "twotap":
                    this._handleTapEvent(_, 4);
                    break;
                  case "threetap":
                    this._handleTapEvent(_, 2);
                    break;
                  case "drag":
                    this.dragViewport ? (this._viewportHasMoved = false, this._viewportDragging = true, this._viewportDragPos = {
                      x: v.x,
                      y: v.y
                    }) : (this._fakeMouseMove(_, v.x, v.y), this._handleMouseButton(v.x, v.y, 1));
                    break;
                  case "longpress":
                    this.dragViewport ? (this._viewportHasMoved = false, this._viewportDragPos = {
                      x: v.x,
                      y: v.y
                    }) : (this._fakeMouseMove(_, v.x, v.y), this._handleMouseButton(v.x, v.y, 4));
                    break;
                  case "twodrag":
                    this._gestureLastMagnitudeX = _.detail.magnitudeX, this._gestureLastMagnitudeY = _.detail.magnitudeY, this._fakeMouseMove(_, v.x, v.y);
                    break;
                  case "pinch":
                    this._gestureLastMagnitudeX = Math.hypot(_.detail.magnitudeX, _.detail.magnitudeY), this._fakeMouseMove(_, v.x, v.y);
                    break;
                }
                break;
              case "gesturemove":
                switch (_.detail.type) {
                  case "onetap":
                  case "twotap":
                  case "threetap":
                    break;
                  case "drag":
                  case "longpress":
                    if (this.dragViewport) {
                      this._viewportDragging = true;
                      var H = this._viewportDragPos.x - v.x, J = this._viewportDragPos.y - v.y;
                      (this._viewportHasMoved || Math.abs(H) > a.dragThreshold || Math.abs(J) > a.dragThreshold) && (this._viewportHasMoved = true, this._viewportDragPos = {
                        x: v.x,
                        y: v.y
                      }, this._display.viewportChangePos(H, J));
                    } else this._fakeMouseMove(_, v.x, v.y);
                    break;
                  case "twodrag":
                    for (this._fakeMouseMove(_, v.x, v.y); _.detail.magnitudeY - this._gestureLastMagnitudeY > Oe; ) this._handleMouseButton(v.x, v.y, 8), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeY += Oe;
                    for (; _.detail.magnitudeY - this._gestureLastMagnitudeY < -Oe; ) this._handleMouseButton(v.x, v.y, 16), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeY -= Oe;
                    for (; _.detail.magnitudeX - this._gestureLastMagnitudeX > Oe; ) this._handleMouseButton(v.x, v.y, 32), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeX += Oe;
                    for (; _.detail.magnitudeX - this._gestureLastMagnitudeX < -Oe; ) this._handleMouseButton(v.x, v.y, 64), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeX -= Oe;
                    break;
                  case "pinch":
                    if (this._fakeMouseMove(_, v.x, v.y), T = Math.hypot(_.detail.magnitudeX, _.detail.magnitudeY), Math.abs(T - this._gestureLastMagnitudeX) > Me) {
                      for (this._handleKeyEvent(f.default.XK_Control_L, "ControlLeft", true); T - this._gestureLastMagnitudeX > Me; ) this._handleMouseButton(v.x, v.y, 8), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeX += Me;
                      for (; T - this._gestureLastMagnitudeX < -Me; ) this._handleMouseButton(v.x, v.y, 16), this._handleMouseButton(v.x, v.y, 0), this._gestureLastMagnitudeX -= Me;
                    }
                    this._handleKeyEvent(f.default.XK_Control_L, "ControlLeft", false);
                    break;
                }
                break;
              case "gestureend":
                switch (_.detail.type) {
                  case "onetap":
                  case "twotap":
                  case "threetap":
                  case "pinch":
                  case "twodrag":
                    break;
                  case "drag":
                    this.dragViewport ? this._viewportDragging = false : (this._fakeMouseMove(_, v.x, v.y), this._handleMouseButton(v.x, v.y, 0));
                    break;
                  case "longpress":
                    if (this._viewportHasMoved) break;
                    this.dragViewport && !this._viewportHasMoved ? (this._fakeMouseMove(_, v.x, v.y), this._handleMouseButton(v.x, v.y, 4), this._handleMouseButton(v.x, v.y, 0), this._viewportDragging = false) : (this._fakeMouseMove(_, v.x, v.y), this._handleMouseButton(v.x, v.y, 0));
                    break;
                }
                break;
            }
          }
        },
        {
          key: "_flushMouseMoveTimer",
          value: function(_, T) {
            this._mouseMoveTimer !== null && (clearTimeout(this._mouseMoveTimer), this._mouseMoveTimer = null, this._sendMouse(_, T, this._mouseButtonMask));
          }
        },
        {
          key: "_negotiateProtocolVersion",
          value: function() {
            if (this._sock.rQwait("version", 12)) return false;
            var _ = this._sock.rQshiftStr(12).substr(4, 7);
            r.Info("Server ProtocolVersion: " + _);
            var T = 0;
            switch (_) {
              case "000.000":
                T = 1;
                break;
              case "003.003":
              case "003.006":
                this._rfbVersion = 3.3;
                break;
              case "003.007":
                this._rfbVersion = 3.7;
                break;
              case "003.008":
              case "003.889":
              case "004.000":
              case "004.001":
              case "005.000":
                this._rfbVersion = 3.8;
                break;
              default:
                return this._fail("Invalid server version " + _);
            }
            if (T) {
              for (var v = "ID:" + this._repeaterID; v.length < 250; ) v += "\0";
              return this._sock.sQpushString(v), this._sock.flush(), true;
            }
            this._rfbVersion > this._rfbMaxVersion && (this._rfbVersion = this._rfbMaxVersion);
            var H = "00" + parseInt(this._rfbVersion, 10) + ".00" + this._rfbVersion * 10 % 10;
            this._sock.sQpushString("RFB " + H + `
`), this._sock.flush(), r.Debug("Sent ProtocolVersion: " + H), this._rfbInitState = "Security";
          }
        },
        {
          key: "_isSupportedSecurityType",
          value: function(_) {
            var T = [
              mt,
              Yr,
              Ei,
              Ki,
              Sn,
              Xi,
              Fi,
              Ci,
              Pi
            ];
            return T.includes(_);
          }
        },
        {
          key: "_negotiateSecurity",
          value: function() {
            if (this._rfbVersion >= 3.7) {
              var _ = this._sock.rQshift8();
              if (this._sock.rQwait("security type", _, 1)) return false;
              if (_ === 0) return this._rfbInitState = "SecurityReason", this._securityContext = "no security types", this._securityStatus = 1, true;
              var T = this._sock.rQshiftBytes(_);
              r.Debug("Server security types: " + T), this._rfbAuthScheme = -1;
              var v = ce(T), H;
              try {
                for (v.s(); !(H = v.n()).done; ) {
                  var J = H.value;
                  if (this._isSupportedSecurityType(J)) {
                    this._rfbAuthScheme = J;
                    break;
                  }
                }
              } catch (te) {
                v.e(te);
              } finally {
                v.f();
              }
              if (this._rfbAuthScheme === -1) return this._fail("Unsupported security types (types: " + T + ")");
              this._sock.sQpush8(this._rfbAuthScheme), this._sock.flush();
            } else {
              if (this._sock.rQwait("security scheme", 4)) return false;
              if (this._rfbAuthScheme = this._sock.rQshift32(), this._rfbAuthScheme == 0) return this._rfbInitState = "SecurityReason", this._securityContext = "authentication scheme", this._securityStatus = 1, true;
            }
            return this._rfbInitState = "Authentication", r.Debug("Authenticating using scheme: " + this._rfbAuthScheme), true;
          }
        },
        {
          key: "_handleSecurityReason",
          value: function() {
            if (this._sock.rQwait("reason length", 4)) return false;
            var _ = this._sock.rQshift32(), T = "";
            if (_ > 0) {
              if (this._sock.rQwait("reason", _, 4)) return false;
              T = this._sock.rQshiftStr(_);
            }
            return T !== "" ? (this.dispatchEvent(new CustomEvent("securityfailure", {
              detail: {
                status: this._securityStatus,
                reason: T
              }
            })), this._fail("Security negotiation failed on " + this._securityContext + " (reason: " + T + ")")) : (this.dispatchEvent(new CustomEvent("securityfailure", {
              detail: {
                status: this._securityStatus
              }
            })), this._fail("Security negotiation failed on " + this._securityContext));
          }
        },
        {
          key: "_negotiateXvpAuth",
          value: function() {
            return this._rfbCredentials.username === void 0 || this._rfbCredentials.password === void 0 || this._rfbCredentials.target === void 0 ? (this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "username",
                  "password",
                  "target"
                ]
              }
            })), false) : (this._sock.sQpush8(this._rfbCredentials.username.length), this._sock.sQpush8(this._rfbCredentials.target.length), this._sock.sQpushString(this._rfbCredentials.username), this._sock.sQpushString(this._rfbCredentials.target), this._sock.flush(), this._rfbAuthScheme = Yr, this._negotiateAuthentication());
          }
        },
        {
          key: "_negotiateVeNCryptAuth",
          value: function() {
            if (this._rfbVeNCryptState == 0) {
              if (this._sock.rQwait("vencrypt version", 2)) return false;
              var _ = this._sock.rQshift8(), T = this._sock.rQshift8();
              if (!(_ == 0 && T == 2)) return this._fail("Unsupported VeNCrypt version " + _ + "." + T);
              this._sock.sQpush8(0), this._sock.sQpush8(2), this._sock.flush(), this._rfbVeNCryptState = 1;
            }
            if (this._rfbVeNCryptState == 1) {
              if (this._sock.rQwait("vencrypt ack", 1)) return false;
              var v = this._sock.rQshift8();
              if (v != 0) return this._fail("VeNCrypt failure " + v);
              this._rfbVeNCryptState = 2;
            }
            if (this._rfbVeNCryptState == 2) {
              if (this._sock.rQwait("vencrypt subtypes length", 1)) return false;
              var H = this._sock.rQshift8();
              if (H < 1) return this._fail("VeNCrypt subtypes empty");
              this._rfbVeNCryptSubtypesLength = H, this._rfbVeNCryptState = 3;
            }
            if (this._rfbVeNCryptState == 3) {
              if (this._sock.rQwait("vencrypt subtypes", 4 * this._rfbVeNCryptSubtypesLength)) return false;
              for (var J = [], te = 0; te < this._rfbVeNCryptSubtypesLength; te++) J.push(this._sock.rQshift32());
              this._rfbAuthScheme = -1;
              for (var ae = 0, we = J; ae < we.length; ae++) {
                var Ce = we[ae];
                if (Ce !== Sn && this._isSupportedSecurityType(Ce)) {
                  this._rfbAuthScheme = Ce;
                  break;
                }
              }
              return this._rfbAuthScheme === -1 ? this._fail("Unsupported security types (types: " + J + ")") : (this._sock.sQpush32(this._rfbAuthScheme), this._sock.flush(), this._rfbVeNCryptState = 4, true);
            }
          }
        },
        {
          key: "_negotiatePlainAuth",
          value: function() {
            if (this._rfbCredentials.username === void 0 || this._rfbCredentials.password === void 0) return this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "username",
                  "password"
                ]
              }
            })), false;
            var _ = (0, i.encodeUTF8)(this._rfbCredentials.username), T = (0, i.encodeUTF8)(this._rfbCredentials.password);
            return this._sock.sQpush32(_.length), this._sock.sQpush32(T.length), this._sock.sQpushString(_), this._sock.sQpushString(T), this._sock.flush(), this._rfbInitState = "SecurityResult", true;
          }
        },
        {
          key: "_negotiateStdVNCAuth",
          value: function() {
            if (this._sock.rQwait("auth challenge", 16)) return false;
            if (this._rfbCredentials.password === void 0) return this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "password"
                ]
              }
            })), false;
            var _ = Array.prototype.slice.call(this._sock.rQshiftBytes(16)), T = R.genDES(this._rfbCredentials.password, _);
            return this._sock.sQpushBytes(T), this._sock.flush(), this._rfbInitState = "SecurityResult", true;
          }
        },
        {
          key: "_negotiateARDAuth",
          value: function() {
            if (this._rfbCredentials.username === void 0 || this._rfbCredentials.password === void 0) return this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "username",
                  "password"
                ]
              }
            })), false;
            if (this._rfbCredentials.ardPublicKey != null && this._rfbCredentials.ardCredentials != null) return this._sock.sQpushBytes(this._rfbCredentials.ardCredentials), this._sock.sQpushBytes(this._rfbCredentials.ardPublicKey), this._sock.flush(), this._rfbCredentials.ardCredentials = null, this._rfbCredentials.ardPublicKey = null, this._rfbInitState = "SecurityResult", true;
            if (this._sock.rQwait("read ard", 4)) return false;
            var _ = this._sock.rQshiftBytes(2), T = this._sock.rQshift16();
            if (this._sock.rQwait("read ard keylength", T * 2, 4)) return false;
            var v = this._sock.rQshiftBytes(T), H = this._sock.rQshiftBytes(T), J = x.default.generateKey({
              name: "DH",
              g: _,
              p: v
            }, false, [
              "deriveBits"
            ]);
            return this._negotiateARDAuthAsync(T, H, J), false;
          }
        },
        {
          key: "_negotiateARDAuthAsync",
          value: function() {
            var D = B(m().mark(function T(v, H, J) {
              var te, ae, we, Ce, Xe, Se, Te, _e, ke, We;
              return m().wrap(function(Le) {
                for (; ; ) switch (Le.prev = Le.next) {
                  case 0:
                    for (te = x.default.exportKey("raw", J.publicKey), ae = x.default.deriveBits({
                      name: "DH",
                      public: H
                    }, J.privateKey, v * 8), we = (0, i.encodeUTF8)(this._rfbCredentials.username).substring(0, 63), Ce = (0, i.encodeUTF8)(this._rfbCredentials.password).substring(0, 63), Xe = window.crypto.getRandomValues(new Uint8Array(128)), Se = 0; Se < we.length; Se++) Xe[Se] = we.charCodeAt(Se);
                    for (Xe[we.length] = 0, Te = 0; Te < Ce.length; Te++) Xe[64 + Te] = Ce.charCodeAt(Te);
                    return Xe[64 + Ce.length] = 0, Le.next = 11, x.default.digest("MD5", ae);
                  case 11:
                    return _e = Le.sent, Le.next = 14, x.default.importKey("raw", _e, {
                      name: "AES-ECB"
                    }, false, [
                      "encrypt"
                    ]);
                  case 14:
                    return ke = Le.sent, Le.next = 17, x.default.encrypt({
                      name: "AES-ECB"
                    }, ke, Xe);
                  case 17:
                    We = Le.sent, this._rfbCredentials.ardCredentials = We, this._rfbCredentials.ardPublicKey = te, this._resumeAuthentication();
                  case 21:
                  case "end":
                    return Le.stop();
                }
              }, T, this);
            }));
            function _(T, v, H) {
              return D.apply(this, arguments);
            }
            return _;
          }()
        },
        {
          key: "_negotiateTightUnixAuth",
          value: function() {
            return this._rfbCredentials.username === void 0 || this._rfbCredentials.password === void 0 ? (this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "username",
                  "password"
                ]
              }
            })), false) : (this._sock.sQpush32(this._rfbCredentials.username.length), this._sock.sQpush32(this._rfbCredentials.password.length), this._sock.sQpushString(this._rfbCredentials.username), this._sock.sQpushString(this._rfbCredentials.password), this._sock.flush(), this._rfbInitState = "SecurityResult", true);
          }
        },
        {
          key: "_negotiateTightTunnels",
          value: function(_) {
            for (var T = {
              0: {
                vendor: "TGHT",
                signature: "NOTUNNEL"
              }
            }, v = {}, H = 0; H < _; H++) {
              var J = this._sock.rQshift32(), te = this._sock.rQshiftStr(4), ae = this._sock.rQshiftStr(8);
              v[J] = {
                vendor: te,
                signature: ae
              };
            }
            return r.Debug("Server Tight tunnel types: " + v), v[1] && v[1].vendor === "SICR" && v[1].signature === "SCHANNEL" && (r.Debug("Detected Siemens server. Assuming NOTUNNEL support."), v[0] = {
              vendor: "TGHT",
              signature: "NOTUNNEL"
            }), v[0] ? v[0].vendor != T[0].vendor || v[0].signature != T[0].signature ? this._fail("Client's tunnel type had the incorrect vendor or signature") : (r.Debug("Selected tunnel type: " + T[0]), this._sock.sQpush32(0), this._sock.flush(), false) : this._fail("Server wanted tunnels, but doesn't support the notunnel type");
          }
        },
        {
          key: "_negotiateTightAuth",
          value: function() {
            if (!this._rfbTightVNC) {
              if (this._sock.rQwait("num tunnels", 4)) return false;
              var _ = this._sock.rQshift32();
              if (_ > 0 && this._sock.rQwait("tunnel capabilities", 16 * _, 4)) return false;
              if (this._rfbTightVNC = true, _ > 0) return this._negotiateTightTunnels(_), false;
            }
            if (this._sock.rQwait("sub auth count", 4)) return false;
            var T = this._sock.rQshift32();
            if (T === 0) return this._rfbInitState = "SecurityResult", true;
            if (this._sock.rQwait("sub auth capabilities", 16 * T, 4)) return false;
            for (var v = {
              STDVNOAUTH__: 1,
              STDVVNCAUTH_: 2,
              TGHTULGNAUTH: 129
            }, H = [], J = 0; J < T; J++) {
              this._sock.rQshift32();
              var te = this._sock.rQshiftStr(12);
              H.push(te);
            }
            r.Debug("Server Tight authentication types: " + H);
            for (var ae in v) if (H.indexOf(ae) != -1) switch (this._sock.sQpush32(v[ae]), this._sock.flush(), r.Debug("Selected authentication type: " + ae), ae) {
              case "STDVNOAUTH__":
                return this._rfbInitState = "SecurityResult", true;
              case "STDVVNCAUTH_":
                return this._rfbAuthScheme = Yr, true;
              case "TGHTULGNAUTH":
                return this._rfbAuthScheme = Ai, true;
              default:
                return this._fail("Unsupported tiny auth scheme (scheme: " + ae + ")");
            }
            return this._fail("No supported sub-auth types!");
          }
        },
        {
          key: "_handleRSAAESCredentialsRequired",
          value: function(_) {
            this.dispatchEvent(_);
          }
        },
        {
          key: "_handleRSAAESServerVerification",
          value: function(_) {
            this.dispatchEvent(_);
          }
        },
        {
          key: "_negotiateRA2neAuth",
          value: function() {
            var _ = this;
            return this._rfbRSAAESAuthenticationState === null && (this._rfbRSAAESAuthenticationState = new K.default(this._sock, function() {
              return _._rfbCredentials;
            }), this._rfbRSAAESAuthenticationState.addEventListener("serververification", this._eventHandlers.handleRSAAESServerVerification), this._rfbRSAAESAuthenticationState.addEventListener("credentialsrequired", this._eventHandlers.handleRSAAESCredentialsRequired)), this._rfbRSAAESAuthenticationState.checkInternalEvents(), this._rfbRSAAESAuthenticationState.hasStarted || this._rfbRSAAESAuthenticationState.negotiateRA2neAuthAsync().catch(function(T) {
              T.message !== "disconnect normally" && _._fail(T.message);
            }).then(function() {
              return _._rfbInitState = "SecurityResult", true;
            }).finally(function() {
              _._rfbRSAAESAuthenticationState.removeEventListener("serververification", _._eventHandlers.handleRSAAESServerVerification), _._rfbRSAAESAuthenticationState.removeEventListener("credentialsrequired", _._eventHandlers.handleRSAAESCredentialsRequired), _._rfbRSAAESAuthenticationState = null;
            }), false;
          }
        },
        {
          key: "_negotiateMSLogonIIAuth",
          value: function() {
            if (this._sock.rQwait("mslogonii dh param", 24)) return false;
            if (this._rfbCredentials.username === void 0 || this._rfbCredentials.password === void 0) return this.dispatchEvent(new CustomEvent("credentialsrequired", {
              detail: {
                types: [
                  "username",
                  "password"
                ]
              }
            })), false;
            var _ = this._sock.rQshiftBytes(8), T = this._sock.rQshiftBytes(8), v = this._sock.rQshiftBytes(8), H = x.default.generateKey({
              name: "DH",
              g: _,
              p: T
            }, true, [
              "deriveBits"
            ]), J = x.default.exportKey("raw", H.publicKey), te = x.default.deriveBits({
              name: "DH",
              public: v
            }, H.privateKey, 64), ae = x.default.importKey("raw", te, {
              name: "DES-CBC"
            }, false, [
              "encrypt"
            ]), we = (0, i.encodeUTF8)(this._rfbCredentials.username).substring(0, 255), Ce = (0, i.encodeUTF8)(this._rfbCredentials.password).substring(0, 63), Xe = new Uint8Array(256), Se = new Uint8Array(64);
            window.crypto.getRandomValues(Xe), window.crypto.getRandomValues(Se);
            for (var Te = 0; Te < we.length; Te++) Xe[Te] = we.charCodeAt(Te);
            Xe[we.length] = 0;
            for (var _e = 0; _e < Ce.length; _e++) Se[_e] = Ce.charCodeAt(_e);
            return Se[Ce.length] = 0, Xe = x.default.encrypt({
              name: "DES-CBC",
              iv: te
            }, ae, Xe), Se = x.default.encrypt({
              name: "DES-CBC",
              iv: te
            }, ae, Se), this._sock.sQpushBytes(J), this._sock.sQpushBytes(Xe), this._sock.sQpushBytes(Se), this._sock.flush(), this._rfbInitState = "SecurityResult", true;
          }
        },
        {
          key: "_negotiateAuthentication",
          value: function() {
            switch (this._rfbAuthScheme) {
              case mt:
                return this._rfbVersion >= 3.8 ? this._rfbInitState = "SecurityResult" : this._rfbInitState = "ClientInitialisation", true;
              case Xi:
                return this._negotiateXvpAuth();
              case Fi:
                return this._negotiateARDAuth();
              case Yr:
                return this._negotiateStdVNCAuth();
              case Ki:
                return this._negotiateTightAuth();
              case Sn:
                return this._negotiateVeNCryptAuth();
              case Pi:
                return this._negotiatePlainAuth();
              case Ai:
                return this._negotiateTightUnixAuth();
              case Ei:
                return this._negotiateRA2neAuth();
              case Ci:
                return this._negotiateMSLogonIIAuth();
              default:
                return this._fail("Unsupported auth scheme (scheme: " + this._rfbAuthScheme + ")");
            }
          }
        },
        {
          key: "_handleSecurityResult",
          value: function() {
            if (this._sock.rQwait("VNC auth response ", 4)) return false;
            var _ = this._sock.rQshift32();
            return _ === 0 ? (this._rfbInitState = "ClientInitialisation", r.Debug("Authentication OK"), true) : this._rfbVersion >= 3.8 ? (this._rfbInitState = "SecurityReason", this._securityContext = "security result", this._securityStatus = _, true) : (this.dispatchEvent(new CustomEvent("securityfailure", {
              detail: {
                status: _
              }
            })), this._fail("Security handshake failed"));
          }
        },
        {
          key: "_negotiateServerInit",
          value: function() {
            if (this._sock.rQwait("server initialization", 24)) return false;
            var _ = this._sock.rQshift16(), T = this._sock.rQshift16(), v = this._sock.rQshift8(), H = this._sock.rQshift8(), J = this._sock.rQshift8(), te = this._sock.rQshift8(), ae = this._sock.rQshift16(), we = this._sock.rQshift16(), Ce = this._sock.rQshift16(), Xe = this._sock.rQshift8(), Se = this._sock.rQshift8(), Te = this._sock.rQshift8();
            this._sock.rQskipBytes(3);
            var _e = this._sock.rQshift32();
            if (this._sock.rQwait("server init name", _e, 24)) return false;
            var ke = this._sock.rQshiftStr(_e);
            if (ke = (0, i.decodeUTF8)(ke, true), this._rfbTightVNC) {
              if (this._sock.rQwait("TightVNC extended server init header", 8, 24 + _e)) return false;
              var We = this._sock.rQshift16(), lt = this._sock.rQshift16(), Le = this._sock.rQshift16();
              this._sock.rQskipBytes(2);
              var ze = (We + lt + Le) * 16;
              if (this._sock.rQwait("TightVNC extended server init header", ze, 32 + _e)) return false;
              this._sock.rQskipBytes(16 * We), this._sock.rQskipBytes(16 * lt), this._sock.rQskipBytes(16 * Le);
            }
            return r.Info("Screen: " + _ + "x" + T + ", bpp: " + v + ", depth: " + H + ", bigEndian: " + J + ", trueColor: " + te + ", redMax: " + ae + ", greenMax: " + we + ", blueMax: " + Ce + ", redShift: " + Xe + ", greenShift: " + Se + ", blueShift: " + Te), this._setDesktopName(ke), this._resize(_, T), this._viewOnly || this._keyboard.grab(), this._fbDepth = 24, this._fbName === "Intel(r) AMT KVM" && (r.Warn("Intel AMT KVM only supports 8/16 bit depths. Using low color mode."), this._fbDepth = 8), R.messages.pixelFormat(this._sock, this._fbDepth, true), this._sendEncodings(), R.messages.fbUpdateRequest(this._sock, false, 0, 0, this._fbWidth, this._fbHeight), this._updateConnectionState("connected"), true;
          }
        },
        {
          key: "_sendEncodings",
          value: function() {
            var _ = [];
            _.push(h.encodings.encodingCopyRect), this._fbDepth == 24 && (a.supportsWebCodecsH264Decode && _.push(h.encodings.encodingH264), _.push(h.encodings.encodingTight), _.push(h.encodings.encodingTightPNG), _.push(h.encodings.encodingZRLE), _.push(h.encodings.encodingJPEG), _.push(h.encodings.encodingHextile), _.push(h.encodings.encodingRRE), _.push(h.encodings.encodingZlib)), _.push(h.encodings.encodingRaw), _.push(h.encodings.pseudoEncodingQualityLevel0 + this._qualityLevel), _.push(h.encodings.pseudoEncodingCompressLevel0 + this._compressionLevel), _.push(h.encodings.pseudoEncodingDesktopSize), _.push(h.encodings.pseudoEncodingLastRect), _.push(h.encodings.pseudoEncodingQEMUExtendedKeyEvent), _.push(h.encodings.pseudoEncodingQEMULedEvent), _.push(h.encodings.pseudoEncodingExtendedDesktopSize), _.push(h.encodings.pseudoEncodingXvp), _.push(h.encodings.pseudoEncodingFence), _.push(h.encodings.pseudoEncodingContinuousUpdates), _.push(h.encodings.pseudoEncodingDesktopName), _.push(h.encodings.pseudoEncodingExtendedClipboard), _.push(h.encodings.pseudoEncodingExtendedMouseButtons), this._fbDepth == 24 && (_.push(h.encodings.pseudoEncodingVMwareCursor), _.push(h.encodings.pseudoEncodingCursor)), R.messages.clientEncodings(this._sock, _);
          }
        },
        {
          key: "_initMsg",
          value: function() {
            switch (this._rfbInitState) {
              case "ProtocolVersion":
                return this._negotiateProtocolVersion();
              case "Security":
                return this._negotiateSecurity();
              case "Authentication":
                return this._negotiateAuthentication();
              case "SecurityResult":
                return this._handleSecurityResult();
              case "SecurityReason":
                return this._handleSecurityReason();
              case "ClientInitialisation":
                return this._sock.sQpush8(this._shared ? 1 : 0), this._sock.flush(), this._rfbInitState = "ServerInitialisation", true;
              case "ServerInitialisation":
                return this._negotiateServerInit();
              default:
                return this._fail("Unknown init state (state: " + this._rfbInitState + ")");
            }
          }
        },
        {
          key: "_resumeAuthentication",
          value: function() {
            setTimeout(this._initMsg.bind(this), 0);
          }
        },
        {
          key: "_handleSetColourMapMsg",
          value: function() {
            return r.Debug("SetColorMapEntries"), this._fail("Unexpected SetColorMapEntries message");
          }
        },
        {
          key: "_handleServerCutText",
          value: function() {
            if (r.Debug("ServerCutText"), this._sock.rQwait("ServerCutText header", 7, 1)) return false;
            this._sock.rQskipBytes(3);
            var _ = this._sock.rQshift32();
            if (_ = (0, n.toSigned32bit)(_), this._sock.rQwait("ServerCutText content", Math.abs(_), 8)) return false;
            if (_ >= 0) {
              var T = this._sock.rQshiftStr(_);
              if (this._viewOnly) return true;
              this.dispatchEvent(new CustomEvent("clipboard", {
                detail: {
                  text: T
                }
              }));
            } else {
              _ = Math.abs(_);
              var v = this._sock.rQshift32(), H = v & 65535, J = v & 4278190080, te = !!(J & Ti);
              if (te) {
                this._clipboardServerCapabilitiesFormats = {}, this._clipboardServerCapabilitiesActions = {};
                for (var ae = 0; ae <= 15; ae++) {
                  var we = 1 << ae;
                  H & we && (this._clipboardServerCapabilitiesFormats[we] = true, this._sock.rQshift32());
                }
                for (var Ce = 24; Ce <= 31; Ce++) {
                  var Xe = 1 << Ce;
                  this._clipboardServerCapabilitiesActions[Xe] = !!(J & Xe);
                }
                var Se = [
                  Ti,
                  $r,
                  Li,
                  kr,
                  Jr
                ];
                R.messages.extendedClipboardCaps(this._sock, Se, {
                  extendedClipboardFormatText: 0
                });
              } else if (J === $r) {
                if (this._viewOnly) return true;
                this._clipboardText != null && this._clipboardServerCapabilitiesActions[Jr] && H & wt && R.messages.extendedClipboardProvide(this._sock, [
                  wt
                ], [
                  this._clipboardText
                ]);
              } else if (J === Li) {
                if (this._viewOnly) return true;
                this._clipboardServerCapabilitiesActions[kr] && (this._clipboardText != null ? R.messages.extendedClipboardNotify(this._sock, [
                  wt
                ]) : R.messages.extendedClipboardNotify(this._sock, []));
              } else if (J === kr) {
                if (this._viewOnly) return true;
                this._clipboardServerCapabilitiesActions[$r] && H & wt && R.messages.extendedClipboardRequest(this._sock, [
                  wt
                ]);
              } else if (J === Jr) {
                if (this._viewOnly || !(H & wt)) return true;
                this._clipboardText = null;
                var Te = this._sock.rQshiftBytes(_ - 4), _e = new l.default(), ke = null;
                _e.setInput(Te);
                for (var We = 0; We <= 15; We++) {
                  var lt = 1 << We;
                  if (H & lt) {
                    var Le = 0, ze = _e.inflate(4);
                    Le |= ze[0] << 24, Le |= ze[1] << 16, Le |= ze[2] << 8, Le |= ze[3];
                    var St = _e.inflate(Le);
                    lt === wt && (ke = St);
                  }
                }
                if (_e.setInput(null), ke !== null) {
                  for (var Ht = "", Et = 0; Et < ke.length; Et++) Ht += String.fromCharCode(ke[Et]);
                  ke = Ht, ke = (0, i.decodeUTF8)(ke), ke.length > 0 && ke.charAt(ke.length - 1) === "\0" && (ke = ke.slice(0, -1)), ke = ke.replaceAll(`\r
`, `
`), this.dispatchEvent(new CustomEvent("clipboard", {
                    detail: {
                      text: ke
                    }
                  }));
                }
              } else return this._fail("Unexpected action in extended clipboard message: " + J);
            }
            return true;
          }
        },
        {
          key: "_handleServerFenceMsg",
          value: function() {
            if (this._sock.rQwait("ServerFence header", 8, 1)) return false;
            this._sock.rQskipBytes(3);
            var _ = this._sock.rQshift32(), T = this._sock.rQshift8();
            if (this._sock.rQwait("ServerFence payload", T, 9)) return false;
            T > 64 && (r.Warn("Bad payload length (" + T + ") in fence response"), T = 64);
            var v = this._sock.rQshiftStr(T);
            return this._supportsFence = true, _ & 1 << 31 ? (_ &= 3, R.messages.clientFence(this._sock, _, v), true) : this._fail("Unexpected fence response");
          }
        },
        {
          key: "_handleXvpMsg",
          value: function() {
            if (this._sock.rQwait("XVP version and message", 3, 1)) return false;
            this._sock.rQskipBytes(1);
            var _ = this._sock.rQshift8(), T = this._sock.rQshift8();
            switch (T) {
              case 0:
                r.Error("XVP operation failed");
                break;
              case 1:
                this._rfbXvpVer = _, r.Info("XVP extensions enabled (version " + this._rfbXvpVer + ")"), this._setCapability("power", true);
                break;
              default:
                this._fail("Illegal server XVP message (msg: " + T + ")");
                break;
            }
            return true;
          }
        },
        {
          key: "_normalMsg",
          value: function() {
            var _;
            this._FBU.rects > 0 ? _ = 0 : _ = this._sock.rQshift8();
            var T, v;
            switch (_) {
              case 0:
                return v = this._framebufferUpdate(), v && !this._enabledContinuousUpdates && R.messages.fbUpdateRequest(this._sock, true, 0, 0, this._fbWidth, this._fbHeight), v;
              case 1:
                return this._handleSetColourMapMsg();
              case 2:
                return r.Debug("Bell"), this.dispatchEvent(new CustomEvent("bell", {
                  detail: {}
                })), true;
              case 3:
                return this._handleServerCutText();
              case 150:
                return T = !this._supportsContinuousUpdates, this._supportsContinuousUpdates = true, this._enabledContinuousUpdates = false, T && (this._enabledContinuousUpdates = true, this._updateContinuousUpdates(), r.Info("Enabling continuous updates.")), true;
              case 248:
                return this._handleServerFenceMsg();
              case 250:
                return this._handleXvpMsg();
              default:
                return this._fail("Unexpected server message (type " + _ + ")"), r.Debug("sock.rQpeekBytes(30): " + this._sock.rQpeekBytes(30)), true;
            }
          }
        },
        {
          key: "_framebufferUpdate",
          value: function() {
            var _ = this;
            if (this._FBU.rects === 0) {
              if (this._sock.rQwait("FBU header", 3, 1)) return false;
              if (this._sock.rQskipBytes(1), this._FBU.rects = this._sock.rQshift16(), this._display.pending()) return this._flushing = true, this._display.flush().then(function() {
                _._flushing = false, _._sock.rQwait("message", 1) || _._handleMessage();
              }), false;
            }
            for (; this._FBU.rects > 0; ) {
              if (this._FBU.encoding === null) {
                if (this._sock.rQwait("rect header", 12)) return false;
                this._FBU.x = this._sock.rQshift16(), this._FBU.y = this._sock.rQshift16(), this._FBU.width = this._sock.rQshift16(), this._FBU.height = this._sock.rQshift16(), this._FBU.encoding = this._sock.rQshift32(), this._FBU.encoding >>= 0;
              }
              if (!this._handleRect()) return false;
              this._FBU.rects--, this._FBU.encoding = null;
            }
            return this._display.flip(), true;
          }
        },
        {
          key: "_handleRect",
          value: function() {
            switch (this._FBU.encoding) {
              case h.encodings.pseudoEncodingLastRect:
                return this._FBU.rects = 1, true;
              case h.encodings.pseudoEncodingVMwareCursor:
                return this._handleVMwareCursor();
              case h.encodings.pseudoEncodingCursor:
                return this._handleCursor();
              case h.encodings.pseudoEncodingQEMUExtendedKeyEvent:
                return this._qemuExtKeyEventSupported = true, true;
              case h.encodings.pseudoEncodingDesktopName:
                return this._handleDesktopName();
              case h.encodings.pseudoEncodingDesktopSize:
                return this._resize(this._FBU.width, this._FBU.height), true;
              case h.encodings.pseudoEncodingExtendedDesktopSize:
                return this._handleExtendedDesktopSize();
              case h.encodings.pseudoEncodingExtendedMouseButtons:
                return this._extendedPointerEventSupported = true, true;
              case h.encodings.pseudoEncodingQEMULedEvent:
                return this._handleLedEvent();
              default:
                return this._handleDataRect();
            }
          }
        },
        {
          key: "_handleVMwareCursor",
          value: function() {
            var _ = this._FBU.x, T = this._FBU.y, v = this._FBU.width, H = this._FBU.height;
            if (this._sock.rQwait("VMware cursor encoding", 1)) return false;
            var J = this._sock.rQshift8();
            this._sock.rQshift8();
            var te, ae = 4;
            if (J == 0) {
              var we = -256;
              if (te = new Array(v * H * ae), this._sock.rQwait("VMware cursor classic encoding", v * H * ae * 2, 2)) return false;
              for (var Ce = new Array(v * H), Xe = 0; Xe < v * H; Xe++) Ce[Xe] = this._sock.rQshift32();
              for (var Se = new Array(v * H), Te = 0; Te < v * H; Te++) Se[Te] = this._sock.rQshift32();
              for (var _e = 0; _e < v * H; _e++) if (Ce[_e] == 0) {
                var ke = Se[_e], We = ke >> 8 & 255, lt = ke >> 16 & 255, Le = ke >> 24 & 255;
                te[_e * ae] = We, te[_e * ae + 1] = lt, te[_e * ae + 2] = Le, te[_e * ae + 3] = 255;
              } else (Ce[_e] & we) == we ? Se[_e] == 0 ? (te[_e * ae] = 0, te[_e * ae + 1] = 0, te[_e * ae + 2] = 0, te[_e * ae + 3] = 0) : ((Se[_e] & we) == we, te[_e * ae] = 0, te[_e * ae + 1] = 0, te[_e * ae + 2] = 0, te[_e * ae + 3] = 255) : (te[_e * ae] = 0, te[_e * ae + 1] = 0, te[_e * ae + 2] = 0, te[_e * ae + 3] = 255);
            } else if (J == 1) {
              if (this._sock.rQwait("VMware cursor alpha encoding", v * H * 4, 2)) return false;
              te = new Array(v * H * ae);
              for (var ze = 0; ze < v * H; ze++) {
                var St = this._sock.rQshift32();
                te[ze * 4] = St >> 24 & 255, te[ze * 4 + 1] = St >> 16 & 255, te[ze * 4 + 2] = St >> 8 & 255, te[ze * 4 + 3] = St & 255;
              }
            } else return r.Warn("The given cursor type is not supported: " + J + " given."), false;
            return this._updateCursor(te, _, T, v, H), true;
          }
        },
        {
          key: "_handleCursor",
          value: function() {
            var _ = this._FBU.x, T = this._FBU.y, v = this._FBU.width, H = this._FBU.height, J = v * H * 4, te = Math.ceil(v / 8) * H, ae = J + te;
            if (this._sock.rQwait("cursor encoding", ae)) return false;
            for (var we = this._sock.rQshiftBytes(J), Ce = this._sock.rQshiftBytes(te), Xe = new Uint8Array(v * H * 4), Se = 0, Te = 0; Te < H; Te++) for (var _e = 0; _e < v; _e++) {
              var ke = Te * Math.ceil(v / 8) + Math.floor(_e / 8), We = Ce[ke] << _e % 8 & 128 ? 255 : 0;
              Xe[Se] = we[Se + 2], Xe[Se + 1] = we[Se + 1], Xe[Se + 2] = we[Se], Xe[Se + 3] = We, Se += 4;
            }
            return this._updateCursor(Xe, _, T, v, H), true;
          }
        },
        {
          key: "_handleDesktopName",
          value: function() {
            if (this._sock.rQwait("DesktopName", 4)) return false;
            var _ = this._sock.rQshift32();
            if (this._sock.rQwait("DesktopName", _, 4)) return false;
            var T = this._sock.rQshiftStr(_);
            return T = (0, i.decodeUTF8)(T, true), this._setDesktopName(T), true;
          }
        },
        {
          key: "_handleLedEvent",
          value: function() {
            if (this._sock.rQwait("LED status", 1)) return false;
            var _ = this._sock.rQshift8(), T = !!(_ & 2), v = !!(_ & 4);
            return this._remoteCapsLock = v, this._remoteNumLock = T, true;
          }
        },
        {
          key: "_handleExtendedDesktopSize",
          value: function() {
            if (this._sock.rQwait("ExtendedDesktopSize", 4)) return false;
            var _ = this._sock.rQpeek8(), T = 4 + _ * 16;
            if (this._sock.rQwait("ExtendedDesktopSize", T)) return false;
            var v = !this._supportsSetDesktopSize;
            this._supportsSetDesktopSize = true, this._sock.rQskipBytes(1), this._sock.rQskipBytes(3);
            for (var H = 0; H < _; H += 1) H === 0 ? (this._screenID = this._sock.rQshift32(), this._sock.rQskipBytes(2), this._sock.rQskipBytes(2), this._sock.rQskipBytes(2), this._sock.rQskipBytes(2), this._screenFlags = this._sock.rQshift32()) : this._sock.rQskipBytes(16);
            if (this._FBU.x === 1 && (this._pendingRemoteResize = false), this._FBU.x === 1 && this._FBU.y !== 0) {
              var J = "";
              switch (this._FBU.y) {
                case 1:
                  J = "Resize is administratively prohibited";
                  break;
                case 2:
                  J = "Out of resources";
                  break;
                case 3:
                  J = "Invalid screen layout";
                  break;
                default:
                  J = "Unknown reason";
                  break;
              }
              r.Warn("Server did not accept the resize request: " + J);
            } else this._resize(this._FBU.width, this._FBU.height);
            return v && this._requestRemoteResize(), this._FBU.x === 1 && this._FBU.y === 0 && this._requestRemoteResize(), true;
          }
        },
        {
          key: "_handleDataRect",
          value: function() {
            var _ = this._decoders[this._FBU.encoding];
            if (!_) return this._fail("Unsupported encoding (encoding: " + this._FBU.encoding + ")"), false;
            try {
              return _.decodeRect(this._FBU.x, this._FBU.y, this._FBU.width, this._FBU.height, this._sock, this._display, this._fbDepth);
            } catch (T) {
              return this._fail("Error decoding rect: " + T), false;
            }
          }
        },
        {
          key: "_updateContinuousUpdates",
          value: function() {
            this._enabledContinuousUpdates && R.messages.enableContinuousUpdates(this._sock, true, 0, 0, this._fbWidth, this._fbHeight);
          }
        },
        {
          key: "_resize",
          value: function(_, T) {
            this._fbWidth = _, this._fbHeight = T, this._display.resize(this._fbWidth, this._fbHeight), this._updateClip(), this._updateScale(), this._updateContinuousUpdates(), this._saveExpectedClientSize();
          }
        },
        {
          key: "_xvpOp",
          value: function(_, T) {
            this._rfbXvpVer < _ || (r.Info("Sending XVP operation " + T + " (version " + _ + ")"), R.messages.xvpOp(this._sock, _, T));
          }
        },
        {
          key: "_updateCursor",
          value: function(_, T, v, H, J) {
            this._cursorImage = {
              rgbaPixels: _,
              hotx: T,
              hoty: v,
              w: H,
              h: J
            }, this._refreshCursor();
          }
        },
        {
          key: "_shouldShowDotCursor",
          value: function() {
            if (!this._showDotCursor) return false;
            for (var _ = 3; _ < this._cursorImage.rgbaPixels.length; _ += 4) if (this._cursorImage.rgbaPixels[_]) return false;
            return true;
          }
        },
        {
          key: "_refreshCursor",
          value: function() {
            if (!(this._rfbConnectionState !== "connecting" && this._rfbConnectionState !== "connected")) {
              var _ = this._shouldShowDotCursor() ? R.cursors.dot : this._cursorImage;
              this._cursor.change(_.rgbaPixels, _.hotx, _.hoty, _.w, _.h);
            }
          }
        }
      ], [
        {
          key: "_convertButtonMask",
          value: function(_) {
            for (var T = {
              0: 1,
              1: 4,
              2: 2,
              3: 128,
              4: 256
            }, v = 0, H = 0; H < 5; H++) _ & 1 << H && (v |= T[H]);
            return v;
          }
        },
        {
          key: "genDES",
          value: function(_, T) {
            var v = _.split("").map(function(J) {
              return J.charCodeAt(0);
            }), H = x.default.importKey("raw", v, {
              name: "DES-ECB"
            }, false, [
              "encrypt"
            ]);
            return x.default.encrypt({
              name: "DES-ECB"
            }, H, T);
          }
        }
      ]);
    }(y.default);
    kt.messages = {
      keyEvent: function(R, D, _) {
        R.sQpush8(4), R.sQpush8(_), R.sQpush16(0), R.sQpush32(D), R.flush();
      },
      QEMUExtendedKeyEvent: function(R, D, _, T) {
        function v(J) {
          var te = T >> 8, ae = T & 255;
          return te === 224 && ae < 127 ? ae | 128 : J;
        }
        R.sQpush8(255), R.sQpush8(0), R.sQpush16(_), R.sQpush32(D);
        var H = v(T);
        R.sQpush32(H), R.flush();
      },
      pointerEvent: function(R, D, _, T) {
        R.sQpush8(5), T = T & 127, R.sQpush8(T), R.sQpush16(D), R.sQpush16(_), R.flush();
      },
      extendedPointerEvent: function(R, D, _, T) {
        R.sQpush8(5);
        var v = T >> 7 & 255;
        if (v & 252) throw new Error("Invalid mouse button mask: " + T);
        var H = T & 127;
        H |= 128, R.sQpush8(H), R.sQpush16(D), R.sQpush16(_), R.sQpush8(v), R.flush();
      },
      _buildExtendedClipboardFlags: function(R, D) {
        for (var _ = new Uint8Array(4), T = 0, v = 0, H = 0; H < R.length; H++) v |= R[H];
        for (var J = 0; J < D.length; J++) T |= D[J];
        return _[0] = v >> 24, _[1] = 0, _[2] = 0, _[3] = T, _;
      },
      extendedClipboardProvide: function(R, D, _) {
        for (var T = new k.default(), v = [], H = 0; H < D.length; H++) {
          if (D[H] != wt) throw new Error("Unsupported extended clipboard format for Provide message.");
          _[H] = _[H].replace(/\r\n|\r|\n/gm, `\r
`);
          var J = (0, i.encodeUTF8)(_[H] + "\0");
          v.push(J.length >> 24 & 255, J.length >> 16 & 255, J.length >> 8 & 255, J.length & 255);
          for (var te = 0; te < J.length; te++) v.push(J.charCodeAt(te));
        }
        var ae = T.deflate(new Uint8Array(v)), we = new Uint8Array(4 + ae.length);
        we.set(kt.messages._buildExtendedClipboardFlags([
          Jr
        ], D)), we.set(ae, 4), kt.messages.clientCutText(R, we, true);
      },
      extendedClipboardNotify: function(R, D) {
        var _ = kt.messages._buildExtendedClipboardFlags([
          kr
        ], D);
        kt.messages.clientCutText(R, _, true);
      },
      extendedClipboardRequest: function(R, D) {
        var _ = kt.messages._buildExtendedClipboardFlags([
          $r
        ], D);
        kt.messages.clientCutText(R, _, true);
      },
      extendedClipboardCaps: function(R, D, _) {
        var T = Object.keys(_), v = new Uint8Array(4 + 4 * T.length);
        T.map(function(te) {
          return parseInt(te);
        }), T.sort(function(te, ae) {
          return te - ae;
        }), v.set(kt.messages._buildExtendedClipboardFlags(D, []));
        for (var H = 4, J = 0; J < T.length; J++) v[H] = _[T[J]] >> 24, v[H + 1] = _[T[J]] >> 16, v[H + 2] = _[T[J]] >> 8, v[H + 3] = _[T[J]] >> 0, H += 4, v[3] |= 1 << T[J];
        kt.messages.clientCutText(R, v, true);
      },
      clientCutText: function(R, D) {
        var _ = arguments.length > 2 && arguments[2] !== void 0 ? arguments[2] : false;
        R.sQpush8(6), R.sQpush8(0), R.sQpush8(0), R.sQpush8(0);
        var T;
        _ ? T = (0, n.toUnsigned32bit)(-D.length) : T = D.length, R.sQpush32(T), R.sQpushBytes(D), R.flush();
      },
      setDesktopSize: function(R, D, _, T, v) {
        R.sQpush8(251), R.sQpush8(0), R.sQpush16(D), R.sQpush16(_), R.sQpush8(1), R.sQpush8(0), R.sQpush32(T), R.sQpush16(0), R.sQpush16(0), R.sQpush16(D), R.sQpush16(_), R.sQpush32(v), R.flush();
      },
      clientFence: function(R, D, _) {
        R.sQpush8(248), R.sQpush8(0), R.sQpush8(0), R.sQpush8(0), R.sQpush32(D), R.sQpush8(_.length), R.sQpushString(_), R.flush();
      },
      enableContinuousUpdates: function(R, D, _, T, v, H) {
        R.sQpush8(150), R.sQpush8(D), R.sQpush16(_), R.sQpush16(T), R.sQpush16(v), R.sQpush16(H), R.flush();
      },
      pixelFormat: function(R, D, _) {
        var T;
        D > 16 ? T = 32 : D > 8 ? T = 16 : T = 8;
        var v = Math.floor(D / 3);
        R.sQpush8(0), R.sQpush8(0), R.sQpush8(0), R.sQpush8(0), R.sQpush8(T), R.sQpush8(D), R.sQpush8(0), R.sQpush8(_ ? 1 : 0), R.sQpush16((1 << v) - 1), R.sQpush16((1 << v) - 1), R.sQpush16((1 << v) - 1), R.sQpush8(v * 0), R.sQpush8(v * 1), R.sQpush8(v * 2), R.sQpush8(0), R.sQpush8(0), R.sQpush8(0), R.flush();
      },
      clientEncodings: function(R, D) {
        R.sQpush8(2), R.sQpush8(0), R.sQpush16(D.length);
        for (var _ = 0; _ < D.length; _++) R.sQpush32(D[_]);
        R.flush();
      },
      fbUpdateRequest: function(R, D, _, T, v, H) {
        typeof _ > "u" && (_ = 0), typeof T > "u" && (T = 0), R.sQpush8(3), R.sQpush8(D ? 1 : 0), R.sQpush16(_), R.sQpush16(T), R.sQpush16(v), R.sQpush16(H), R.flush();
      },
      xvpOp: function(R, D, _) {
        R.sQpush8(250), R.sQpush8(0), R.sQpush8(D), R.sQpush8(_), R.flush();
      }
    }, kt.cursors = {
      none: {
        rgbaPixels: new Uint8Array(),
        w: 0,
        h: 0,
        hotx: 0,
        hoty: 0
      },
      dot: {
        rgbaPixels: new Uint8Array([
          255,
          255,
          255,
          255,
          0,
          0,
          0,
          255,
          255,
          255,
          255,
          255,
          0,
          0,
          0,
          255,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          255,
          255,
          255,
          255,
          255,
          0,
          0,
          0,
          255,
          255,
          255,
          255,
          255
        ]),
        w: 3,
        h: 3,
        hotx: 1,
        hoty: 1
      }
    };
  })($a);
  const af = Ts($a);
  function of(e) {
    let t, n, r, i, a, o, s, y, u, l, k, X, g;
    return {
      c() {
        t = _t("div"), n = _t("div"), r = _t("button"), r.textContent = "Ctrl + Alt + Del", i = Xr(), a = _t("input"), o = Xr(), s = _t("button"), s.textContent = "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C", y = Xr(), u = _t("button"), u.textContent = "\u0412\u0441\u0442\u0430\u0432\u0438\u0442\u044C \u0438\u0437 \u0431\u0443\u0444\u0435\u0440\u0430", l = Xr(), k = _t("div"), ft(r, "class", "button"), ft(a, "class", "input"), ft(a, "maxlength", "1000"), ft(a, "type", "text"), ft(s, "class", "button"), ft(u, "class", "button"), ft(n, "class", "flex flex-row items-center w-full"), ft(k, "class", "vnc-screen-container");
      },
      m(b, d) {
        Ur(b, t, d), Ge(t, n), Ge(n, r), Ge(n, i), Ge(n, a), Oi(a, e[1]), Ge(n, o), Ge(n, s), Ge(n, y), Ge(n, u), Ge(t, l), Ge(t, k), e[11](k), X || (g = [
          tn(r, "click", e[2]),
          tn(a, "input", e[10]),
          tn(s, "click", e[3]),
          tn(u, "click", e[4])
        ], X = true);
      },
      p(b, [d]) {
        d & 2 && a.value !== b[1] && Oi(a, b[1]);
      },
      i: Jt,
      o: Jt,
      d(b) {
        b && gr(t), e[11](null), X = false, xr(g);
      }
    };
  }
  let sf = 6;
  const Na = 65505, uf = 65293;
  function Kr(e) {
    return new Promise((t) => setTimeout(t, e));
  }
  function lf(e, t, n) {
    let r = null, i, { desktopCallback: a } = t, { connectCallback: o } = t, { url: s } = t, { onConnectCallback: y = async () => {
    } } = t, { onDisconnectCallback: u = async () => {
    } } = t;
    Ga(() => (r = new af(i, s), r.compressionLevel = 5, r.qualityLevel = sf, r.viewOnly = false, r.dragViewport = false, r.clipViewport = false, r.scaleViewport = true, r.addEventListener("desktopname", a), r.addEventListener("connect", (c) => {
      o(true), y();
    }), r.addEventListener("disconnect", (c) => {
      o(false), u();
    }), () => {
      r == null ? void 0 : r.disconnect();
    }));
    const l = () => {
      r == null ? void 0 : r.sendCtrlAltDel();
    }, k = function(c) {
      var h = c.shift();
      if (h != null && r != null) {
        var K = h.charCodeAt(0);
        if (K === 13) {
          Kr(50).then((F) => {
            k(c);
          });
          return;
        }
        if (K === 10) {
          r.sendKey(uf, null), Kr(50).then((F) => {
            k(c);
          });
          return;
        }
        var x = h.match(/[A-Z!@#$%^&*()_+{}:\"<>?~|]/);
        x ? (r.sendKey(Na, null, true), Kr(50).then((F) => {
          r != null && (r.sendKey(K, null), Kr(50).then((S) => {
            r.sendKey(Na, null, false);
          }));
        })) : r.sendKey(K, null), Kr(50).then((F) => {
          k(c);
        });
      }
    }, X = () => {
      b.length > 0 && b.length < 1001 && r != null && k(b.split(""));
    }, g = () => {
      navigator.clipboard.readText().then((c) => {
        r != null && k(c.split(""));
      }).catch((c) => {
        console.error("Failed to read clipboard contents: ", c);
      });
    };
    let b = "";
    function d() {
      b = this.value, n(1, b);
    }
    function f(c) {
      Nn[c ? "unshift" : "push"](() => {
        i = c, n(0, i);
      });
    }
    return e.$$set = (c) => {
      "desktopCallback" in c && n(5, a = c.desktopCallback), "connectCallback" in c && n(6, o = c.connectCallback), "url" in c && n(7, s = c.url), "onConnectCallback" in c && n(8, y = c.onConnectCallback), "onDisconnectCallback" in c && n(9, u = c.onDisconnectCallback);
    }, [
      i,
      b,
      l,
      X,
      g,
      a,
      o,
      s,
      y,
      u,
      d,
      f
    ];
  }
  class ff extends ui {
    constructor(t) {
      super(), si(this, t, lf, of, vn, {
        desktopCallback: 5,
        connectCallback: 6,
        url: 7,
        onConnectCallback: 8,
        onDisconnectCallback: 9
      });
    }
  }
  function cf(e) {
    let t, n = e[5] ? "\u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E" : "\u041E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u043E", r;
    return {
      c() {
        t = _t("h3"), r = hr(n), ft(t, "class", "font-semibold");
      },
      m(i, a) {
        Ur(i, t, a), Ge(t, r);
      },
      p(i, a) {
        a & 32 && n !== (n = i[5] ? "\u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E" : "\u041E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u043E") && Un(r, n);
      },
      d(i) {
        i && gr(t);
      }
    };
  }
  function hf(e) {
    let t, n = (e[0] ? e[4].length == 0 ? "\u0412\u0438\u0440\u0442\u0443\u0430\u043B\u044C\u043D\u0430\u044F \u043C\u0430\u0448\u0438\u043D\u0430" : e[4] : "") + "", r, i, a = e[5] ? "\u043F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E" : "\u043E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u043E", o;
    return {
      c() {
        t = _t("h3"), r = hr(n), i = hr(" - "), o = hr(a), ft(t, "class", "text-xl font-semibold");
      },
      m(s, y) {
        Ur(s, t, y), Ge(t, r), Ge(t, i), Ge(t, o);
      },
      p(s, y) {
        y & 17 && n !== (n = (s[0] ? s[4].length == 0 ? "\u0412\u0438\u0440\u0442\u0443\u0430\u043B\u044C\u043D\u0430\u044F \u043C\u0430\u0448\u0438\u043D\u0430" : s[4] : "") + "") && Un(r, n), y & 32 && a !== (a = s[5] ? "\u043F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E" : "\u043E\u0442\u043A\u043B\u044E\u0447\u0435\u043D\u043E") && Un(o, a);
      },
      d(s) {
        s && gr(t);
      }
    };
  }
  function ja(e) {
    let t, n;
    return t = new ff({
      props: {
        desktopCallback: e[7],
        connectCallback: e[8],
        url: e[1],
        onConnectCallback: e[2],
        onDisconnectCallback: e[3]
      }
    }), {
      c() {
        Ya(t.$$.fragment);
      },
      m(r, i) {
        ai(t, r, i), n = true;
      },
      p(r, i) {
        const a = {};
        i & 2 && (a.url = r[1]), i & 4 && (a.onConnectCallback = r[2]), i & 8 && (a.onDisconnectCallback = r[3]), t.$set(a);
      },
      i(r) {
        n || (Nt(t.$$.fragment, r), n = true);
      },
      o(r) {
        pr(t.$$.fragment, r), n = false;
      },
      d(r) {
        oi(t, r);
      }
    };
  }
  function df(e) {
    let t, n, r, i, a = e[6], o;
    function s(k, X) {
      return k[0] ? hf : cf;
    }
    let y = s(e), u = y(e), l = ja(e);
    return {
      c() {
        t = _t("div"), n = _t("div"), r = _t("div"), u.c(), i = Xr(), l.c(), ft(r, "class", "flex flex-row items-center justify-between text-slate w-full"), ft(n, "class", "vnc-container"), ft(t, "class", "vnc-container__wrapper");
      },
      m(k, X) {
        Ur(k, t, X), Ge(t, n), Ge(n, r), u.m(r, null), Ge(n, i), l.m(n, null), o = true;
      },
      p(k, [X]) {
        y === (y = s(k)) && u ? u.p(k, X) : (u.d(1), u = y(k), u && (u.c(), u.m(r, null))), X & 64 && vn(a, a = k[6]) ? (Za(), pr(l, 1, 1, Jt), qa(), l = ja(k), l.c(), Nt(l, 1), l.m(n, null)) : l.p(k, X);
      },
      i(k) {
        o || (Nt(l), o = true);
      },
      o(k) {
        pr(l), o = false;
      },
      d(k) {
        k && gr(t), u.d(), l.d(k);
      }
    };
  }
  function _f(e, t, n) {
    let r = "", i = false, a = {}, { getPowerCallback: o = async () => null } = t, { controlPower: s = true } = t, { showDesktopName: y = true } = t, { url: u } = t, { onConnectCallback: l = async () => {
    } } = t, { onDisconnectCallback: k = async () => {
    } } = t;
    const X = (d) => {
      n(4, r = d.detail.name), document.title = d.detail.name;
    }, g = (d) => {
      n(5, i = d);
    }, b = () => {
      n(6, a = {});
    };
    return Ga(() => (setInterval(() => {
      i || b();
    }, 2e3), () => {
    })), s && o(), e.$$set = (d) => {
      "getPowerCallback" in d && n(9, o = d.getPowerCallback), "controlPower" in d && n(10, s = d.controlPower), "showDesktopName" in d && n(0, y = d.showDesktopName), "url" in d && n(1, u = d.url), "onConnectCallback" in d && n(2, l = d.onConnectCallback), "onDisconnectCallback" in d && n(3, k = d.onDisconnectCallback);
    }, [
      y,
      u,
      l,
      k,
      r,
      i,
      a,
      X,
      g,
      o,
      s
    ];
  }
  class pf extends ui {
    constructor(t) {
      super(), si(this, t, _f, df, vn, {
        getPowerCallback: 9,
        controlPower: 10,
        showDesktopName: 0,
        url: 1,
        onConnectCallback: 2,
        onDisconnectCallback: 3
      });
    }
  }
  function Ha(e) {
    let t, n;
    return t = new pf({
      props: {
        url: e[1]
      }
    }), {
      c() {
        Ya(t.$$.fragment);
      },
      m(r, i) {
        ai(t, r, i), n = true;
      },
      p: Jt,
      i(r) {
        n || (Nt(t.$$.fragment, r), n = true);
      },
      o(r) {
        pr(t.$$.fragment, r), n = false;
      },
      d(r) {
        oi(t, r);
      }
    };
  }
  function vf(e) {
    let t, n, r = e[0] != null && Ha(e);
    return {
      c() {
        r && r.c(), t = ks();
      },
      m(i, a) {
        r && r.m(i, a), Ur(i, t, a), n = true;
      },
      p(i, [a]) {
        i[0] != null ? r ? (r.p(i, a), a & 1 && Nt(r, 1)) : (r = Ha(i), r.c(), Nt(r, 1), r.m(t.parentNode, t)) : r && (Za(), pr(r, 1, 1, () => {
          r = null;
        }), qa());
      },
      i(i) {
        n || (Nt(r), n = true);
      },
      o(i) {
        pr(r), n = false;
      },
      d(i) {
        i && gr(t), r && r.d(i);
      }
    };
  }
  function yf(e, t, n) {
    let r = null;
    const a = new URL(document.URL).pathname.match("/vnc/(.*)");
    a != null && a.length > 1 && (r = a[1]);
    const o = window.location.hostname, y = (window.location.protocol == "https:" ? "wss" : "ws") + "://" + o + "/api/vm/" + r + "/vnc";
    return [
      r,
      y
    ];
  }
  class xf extends ui {
    constructor(t) {
      super(), si(this, t, yf, vf, vn, {});
    }
  }
  new xf({
    target: document.getElementById("app")
  });
})();
