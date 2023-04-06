function main(){return (


(function(){
  g = ((function(){return (_mkButton)})())(null)
  return (function (_i1, _btn1){
  return (
(function(){
  g = ((function(){return (_mkButton)})())(null)
  return (function (_i2, _btn2){
  return (
(function(){
  g = ((function(){return (_mkButton)})())(null)
  return (function (_ifin, _btnfin){
  return (
(function(){
  g = (((function(){return (_setText)})())(_i1))([_btn1, "Buton1"])
  return (function (_btn1){
  return (
(function(){
  g = (((function(){return (_setColor)})())(_i1))([_btn1, (function(){return (_red)})()])
  return (function (_btn1){
  return (
(function(){
  g = (((function(){return (_onClick)})())(_i1))(_btn1)
  return (function (_btn1, _clk1){
  return (
(function(){
  g = (((function(){return (_setText)})())(_i2))([_btn2, "Buton2"])
  return (function (_btn2){
  return (
(function(){
  g = (((function(){return (_setColor)})())(_i2))([_btn2, (function(){return (_green)})()])
  return (function (_btn2){
  return (
(function(){
  g = (((function(){return (_onClick)})())(_i2))(_btn2)
  return (function (_btn2, _clk2){
  return (
(function(){
  g = (((function(){return (_setText)})())(_ifin))([_btnfin, "Buton final"])
  return (function (_btnfin){
  return (
(function(){
  g = (function (){
  var chans = {"_x": new Channel(),"_y": new Channel(),};
  var finchan = new Channel();
  var gs = {"_x": (_clk1),"_y": (_clk2),};
  var fs = {"_x": function(_x, _y){
          return (
(function(){
  g = _x
  return (function (){
  return (
(function(){
  g = (function(){return (_red)})()
  return (function (_cl1){
  return (
(function(){
  g = (function(){
  var chan = new Channel();
  var g = (_y);
  function f(){
    return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_blue)})());
  return curriedget(chan);
})())
  };
  g( x => f()(y => chan.put(y)) );
  return curriedget(chan);
})()
  return (function (_cl2){
  return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())
})(g)})())
})(g)})())
})()})())
        },
"_y": function(_y, _x){
          return (
(function(){
  g = _y
  return (function (){
  return (
(function(){
  g = (function(){return (_green)})()
  return (function (_cl1){
  return (
(function(){
  g = (function(){
  var chan = new Channel();
  var g = (_x);
  function f(){
    return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_yellow)})());
  return curriedget(chan);
})())
  };
  g( x => f()(y => chan.put(y)) );
  return curriedget(chan);
})()
  return (function (_cl2){
  return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())
})(g)})())
})(g)})())
})()})())
        },
};
  var first = true;
  gs["_x"]( x=> {if(first){
        first = false;
        fs["_x"](x, curriedget(chans["_y"]))(curriedput(finchan))
      } else chans["_x"].put(x)});
gs["_y"]( x=> {if(first){
        first = false;
        fs["_y"](x, curriedget(chans["_x"]))(curriedput(finchan))
      } else chans["_y"].put(x)});
;
  return curriedget(finchan);
})()
  return (function (_col){
  return (
(function(){
  g = _col
  return (function (_n, _colat){
  return (
(function(){
  var chan1 = new Channel();
  var chan2 = new Channel();
  var g = (_colat);
  g(pair => {chan1.put(pair[0]); chan2.put(pair[1]);})
  function f(_coltnow, _coltthen){
    return (
(function(){
  g = ((((function(){return (_split)})())(_ifin))(_n))(_btnfin)
  return (function (_pr, _fwt){
  return (
(function(){
  g = (function(){
                var chan = new Channel();
                _coltnow(_coltnow=>{_fwt(_fwt=>{_coltthen(_coltthen=>{chan.put(
(function(){
  g = (((function(){return (_setColor)})())(_ifin))([_fwt, _coltnow])
  return (function (_w1){
  return (
(function(){
  g = _coltthen
  return (function (_n2, _colttthen){
  return (
(function(){
  g = ((((function(){return (_split)})())(_ifin))(_n2))(_w1)
  return (function (_pr2, _fw2){
  return (
(function(){
  g = (function(){
                var chan = new Channel();
                _fw2(_fw2=>{_colttthen(_colttthen=>{chan.put((((function(){return (_setColor)})())(_ifin))([_fw2, _colttthen]))})});
                return curriedget(chan);
              })()
  return (function (_wf){
  return (((((function(){return (_join)})())(_ifin))(_n2))([_pr2, _wf]))
})(g)})())
})(g[0], g[1])})())
})(null, g)})())
})(g)})())})})});
                return curriedget(chan);
              })()
  return (function (_fwfin){
  return (
(function(){
  g = ((((function(){return (_join)})())(_ifin))(_n))([_pr, _fwfin])
  return (function (_wfin){
  return ([_wfin, [_btn1, _btn2]])
})(g)})())
})(g)})())
})(g[0], g[1])})())
  }
  return f(curriedget(chan1), curriedget(chan2))
})())
})(null, g)})())
})(g)})())
})(g)})())
})(g[0], g[1])})())
})(g)})())
})(g)})())
})(g[0], g[1])})())
})(g)})())
})(g)})())
})(null, g)})())
})(null, g)})())
})(null, g)})()

)};