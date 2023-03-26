function main(){return (


(function(){
  p1 = ((function(){return (_mkButton)})())(null)
  return (function (_i1, _btn1){
  return (
(function(){
  p1 = ((function(){return (_mkButton)})())(null)
  return (function (_i2, _btn2){
  return (
(function(){
  p1 = ((function(){return (_mkButton)})())(null)
  return (function (_ifin, _btnfin){
  return (
(function(){
  p1 = (((function(){return (_onClick)})())(_i1))(_btn1)
  return (function (_btn11, _clk1){
  return (
(function(){
  p1 = (((function(){return (_onClick)})())(_i2))(_btn2)
  return (function (_btn21, _clk2){
  return (
(function(){
  p1 = (function (){
  var chan = new Channel();
  var finchan = new Channel();
  var g1 = (_clk1);
  var g2 = (_clk2);
  var f1 = (_x => (_y => (
(function(){
  p1 = _x
  return (function (){
  return (
(function(){
  p1 = (function(){return (_red)})()
  return (function (_cl1){
  return (
(function(){
  p1 = (function(){
  var chan = new Channel();
  var g = (_y);
  var f = (_un => (
(function(){
  p1 = _un
  return (function (){
  return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_blue)})());
  return curriedget(chan);
})())
})()})()));
  g( x => f(x)(y => chan.put(y)) );
  return curriedget(chan);
})()
  return (function (_cl2){
  return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())
})(p1)})())
})(p1)})())
})()})()))); // what i have, what i dont have, what it do
  var f2 = (_y => (_x => (
(function(){
  p1 = _y
  return (function (){
  return (
(function(){
  p1 = (function(){return (_green)})()
  return (function (_cl1){
  return (
(function(){
  p1 = (function(){
  var chan = new Channel();
  var g = (_x);
  var f = (_un => (
(function(){
  p1 = _un
  return (function (){
  return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_yellow)})());
  return curriedget(chan);
})())
})()})()));
  g( x => f(x)(y => chan.put(y)) );
  return curriedget(chan);
})()
  return (function (_cl2){
  return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())
})(p1)})())
})(p1)})())
})()})())));
  var first = true;
  g1( a=> {if(first){
    first = false;
    var newchan = new Channel();
    chan.get(curriedput(newchan));
    f1(a)(curriedget(newchan))(curriedput(finchan))
  } else chan.put(a)})
  g2( b=> {if(first){
    first = false;
    var newchan = new Channel();
    chan.get(curriedput(newchan));
    f2(b)(curriedget(newchan))(curriedput(finchan))
  } else chan.put(b)})
  return curriedget(finchan);
})()
  return (function (_col){
  return (
(function(){
  p1 = _col
  return (function (_n, _colat){
  return (
(function(){
  var chan1 = new Channel();
  var chan2 = new Channel();
  var g = (_colat);
  g(pair => {chan1.put(pair[0]); chan2.put(pair[1]);})
  var f = (_colatnow => _colatthen => (
(function(){
  p1 = _colatnow
  return (function (_coltnow){
  return (
(function(){
  p1 = _colatthen
  return (function (_coltthen){
  return (
(function(){
  p1 = ((((function(){return (_split)})())(_ifin))(_n))(_btnfin)
  return (function (_pr, _fw){
  return (
(function(){
  p1 = _fw
  return (function (_fwt){
  return (
(function(){
  p1 = (function(){
                var chan = new Channel();
                _coltnow(_coltnow=>{_fwt(_fwt=>{_coltthen(_coltthen=>{chan.put(
(function(){
  p1 = (((function(){return (_setColor)})())(_ifin))([_fwt, _coltnow])
  return (function (_w1){
  return (
(function(){
  p1 = _coltthen
  return (function (_n2, _coltatthen){
  return (
(function(){
  p1 = _coltatthen
  return (function (_colttthen){
  return (
(function(){
  p1 = ((((function(){return (_split)})())(_ifin))(_n2))(_w1)
  return (function (_pr2, _fw2a){
  return (
(function(){
  p1 = _fw2a
  return (function (_fw2){
  return (
(function(){
  p1 = (function(){
                var chan = new Channel();
                _fw2(_fw2=>{_colttthen(_colttthen=>{chan.put((((function(){return (_setColor)})())(_ifin))([_fw2, _colttthen]))})});
                return curriedget(chan);
              })()
  return (function (_wf){
  return (((((function(){return (_join)})())(_ifin))(_n2))([_pr2, _wf]))
})(p1)})())
})(p1)})())
})(p1[0], p1[1])})())
})(p1)})())
})(null, p1)})())
})(p1)})())})})});
                return curriedget(chan);
              })()
  return (function (_fwfin){
  return (
(function(){
  p1 = ((((function(){return (_join)})())(_ifin))(_n))([_pr, _fwfin])
  return (function (_wfin){
  return ([_wfin, [_btn11, _btn21]])
})(p1)})())
})(p1)})())
})(p1)})())
})(p1[0], p1[1])})())
})(p1)})())
})(p1)})()))
  return f(curriedget(chan1))(curriedget(chan2))
})())
})(null, p1)})())
})(p1)})())
})(p1[0], p1[1])})())
})(p1[0], p1[1])})())
})(null, p1)})())
})(null, p1)})())
})(null, p1)})()

)};