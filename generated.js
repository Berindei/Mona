function main(){return (

((function (_interleave){return (((function (_map){return (((function (_mkUnitStr){return (
(function(){
  g = ((function(){return (_mkButton)})())(null)
  return (function (_j, _w){
  return (
(function(){
  g = ((function(){return (_mkButton)})())(null)
  return (function (_k, _w2){
  return (
(function(){
  g = function(unit){return (function (_j){return (function(_p){return (
(function(){
  g = _p
  return (function (_w, _f){
  return (((((_mkUnitStr)(null))(_j))(_w))(_f))
})(g[0], g[1])})())})})}
  return (function (_FGmkStr){
  return (
(function(){
  g = _FGmkStr
  return (function (_GmkStr){
  return (
(function(){
  g = (_GmkStr)(null)
  return (function (_mkStr){
  return (
(function(){
  g = (((function(){return (_setText)})())(_j))([_w, "Buton"])
  return (function (_w){
  return (
(function(){
  g = (((function(){return (_setSize)})())(_j))([_w, 20])
  return (function (_w){
  return (
(function(){
  g = ((_mkStr)(_j))([_w, function(unit){return ((function(){return (_onClick)})())}])
  return (function (_w, _str1){
  return (
(function(){
  g = (_GmkStr)(null)
  return (function (_mkStr){
  return (
(function(){
  g = (((function(){return (_setText)})())(_k))([_w2, "Buton 2"])
  return (function (_w2){
  return (
(function(){
  g = ((_mkStr)(_k))([_w2, function(unit){return ((function(){return (_onClick)})())}])
  return (function (_w2, _str2){
  return (
(function(){
  g = (((_interleave)(null))(_str1))(_str2)
  return (function (_str){
  return (((function (_printer){return (
(function(){
  g = ((_printer)(null))(_str)
  return (function (_n, _ev){
  return (
(function(){
  g = ((((function(){return (_split)})())(_j))(_n))(_w)
  return (function (_pr, _fw){
  return (
(function(){
  g = ((((function(){return (_join)})())(_j))(_n))([_pr, (function(){
                var chan = new Channel();
                _ev(_ev=>{_fw(_fw=>{chan.put(
(function(){
  g = _ev
  return (function (){
  return (_fw)
})()})())})});
                return curriedget(chan);
              })()])
  return (function (_w){
  return ([_w, _w2])
})(g)})())
})(g[0], g[1])})())
})(null, g)})());})
(function _printer(unit){
  return ( (_s) => {return ((function(){
  var chan = new Channel();
  var g = (_s);
  function f(_sum, _str1){
    return (
(function(){
  g = (function(){
  var sum = (_sum);
  function f1() {
    return ("Buton 1")
  };
  function f2() {
    return ("Buton 2")
  };
  if(sum.tag=="L") return f1();
  else return f2();
})()
  return (function (_text){
  return (
(function(){
  g = ((function(){return (_log)})())(_text)
  return (function (){
  return (((_printer)(null))(_str1))
})()})())
})(g)})())
  };
  g( x => f(x[0], x[1])(y => chan.put(y)) );
  return curriedget(chan);
})());} );
})))
})(g)})())
})(g[0], g[1])})())
})(g)})())
})(g)})())
})(g[0], g[1])})())
})(g)})())
})(g)})())
})(g)})())
})(g)})())
})(g)})())
})(null, g)})())
})(null, g)})());})
(function _mkUnitStr(unit){
  return ( (_j) => {return (function(_w){return (function(_ff){return (
(function(){
  g = _ff
  return (function (_f){
  return (
(function(){
  g = (((_f)(null))(_j))(_w)
  return (function (_w, _ev){
  return (
(function(){
  g = _ev
  return (function (_n, _evat){
  return (
(function(){
  g = ((((function(){return (_split)})())(_j))(_n))(_w)
  return (function (_pr, _fw){
  return (
(function(){
  var chan1 = new Channel();
  var chan2 = new Channel();
  var g = ((function(){
                var chan = new Channel();
                _fw(_fw=>{_evat(_evat=>{chan.put(
(function(){
  g = ((((_mkUnitStr)(null))(_j))(_fw))(_f)
  return (function (_fw, _str){
  return ([_fw, [_evat, _str]])
})(g[0], g[1])})())})});
                return curriedget(chan);
              })());
  g(pair => {chan1.put(pair[0]); chan2.put(pair[1]);})
  function f(_fwfin, _fstr){
    return (
(function(){
  g = ((((function(){return (_join)})())(_j))(_n))([_pr, _fwfin])
  return (function (_wfin){
  return (
(function(){
  g = (function (){return (_fstr)})()
  return (function (_str){
  return ([_wfin, _str])
})(g)})())
})(g)})())
  }
  return f(curriedget(chan1), curriedget(chan2))
})())
})(g[0], g[1])})())
})(null, g)})())
})(g[0], g[1])})())
})(g)})())})});} );
})));})
(function _map(unit){
  return ( (_f) => {return (function(_s){return (
(function(){
  g = _f
  return (function (_f1){
  return ((function(){
  var chan = new Channel();
  var g = (_s);
  function f(_x, _sxs){
    return ((function(){
  var chan = new Channel();
  chan.put([((_f1)(null))(_x), (((_map)(null))(_f1))(_sxs)]);
  return curriedget(chan);
})())
  };
  g( x => f(x[0], x[1])(y => chan.put(y)) );
  return curriedget(chan);
})())
})(g)})())});} );
})));})
(function _interleave(unit){
  return ( (_s1) => {return (function(_s2){return ((function (){
  var chans = {"_xs": new Channel(),"_ys": new Channel(),};
  var finchan = new Channel();
  var gs = {"_xs": (_s1),"_ys": (_s2),};
  var fs = {"_xs": function(_xs, _ys){
          return (
(function(){
  g = _xs
  return (function (_x, _sxs){
  return ((function(){
  var chan = new Channel();
  chan.put([{value: _x, tag:"L"}, (((_interleave)(null))(_sxs))(_ys)]);
  return curriedget(chan);
})())
})(g[0], g[1])})())
        },
"_ys": function(_ys, _xs){
          return (
(function(){
  g = _ys
  return (function (_y, _sys){
  return ((function(){
  var chan = new Channel();
  chan.put([{value: _y, tag:"R"}, (((_interleave)(null))(_xs))(_sys)]);
  return curriedget(chan);
})())
})(g[0], g[1])})())
        },
};
  var first = true;
  gs["_xs"]( x=> {if(first){
        first = false;
        fs["_xs"](x, curriedget(chans["_ys"]))(curriedput(finchan))
      } else chans["_xs"].put(x)});
gs["_ys"]( x=> {if(first){
        first = false;
        fs["_ys"](x, curriedget(chans["_xs"]))(curriedput(finchan))
      } else chans["_ys"].put(x)});
;
  return curriedget(finchan);
})())});} );
}))

)};