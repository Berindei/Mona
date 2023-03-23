function main(){return (

(function(_i1){return ((function(_btn1){return ((function(_i2){return ((function(_btn2){return ((function(_ifin){return ((function(_btnfin){return ((function() {
  var pair = (((function(){return (_onClick)})())(_i1))(_btn1);
  return (function(_btn11, _clk1){
      return((function() {
  var pair = (((function(){return (_onClick)})())(_i2))(_btn2);
  return (function(_btn21, _clk2){
      return((function(_col){return ((function(_n){return ((function(_colat){return (
(function(){
  var chan1 = new Channel();
  var chan2 = new Channel();
  var g = (_colat);
  g(pair => {chan1.put(pair[0]); chan2.put(pair[1]);})
  var f = (_colatnow => _colatthen => ((function(_coltnow){return ((function(_coltthen){return ((function() {
  var pair = ((((function(){return (_split)})())(_ifin))(_n))(_btnfin);
  return (function(_pr, _fw){
      return((function(_fwt){return ((function(_fwfin){return ((function(_wfin){return ([_wfin, [_btn11, _btn21]])})(((((function(){return (_join)})())(_ifin))(_n))([_pr, _fwfin])))})((function(){
                var chan = new Channel();
                _coltnow(_coltnow=>{_fwt(_fwt=>{_coltthen(_coltthen=>{chan.put((function(_w1){return ((function(_n2){return ((function(_coltatthen){return ((function(_colttthen){return ((function() {
  var pair = ((((function(){return (_split)})())(_ifin))(_n2))(_w1);
  return (function(_pr2, _fw2a){
      return((function(_fw2){return ((function(_wf){return (((((function(){return (_join)})())(_ifin))(_n2))([_pr2, _wf]))})((function(){
                var chan = new Channel();
                _fw2(_fw2=>{_colttthen(_colttthen=>{chan.put((((function(){return (_setColor)})())(_ifin))([_fw2, _colttthen]))})});
                return curriedget(chan);
              })()))})(_fw2a))
  })(pair[0], pair[1])
})())})(_coltatthen))})(_coltthen))})(null))})((((function(){return (_setColor)})())(_ifin))([_fwt, _coltnow])))})})});
                return curriedget(chan);
              })()))})(_fw))
  })(pair[0], pair[1])
})())})(_colatthen))})(_colatnow)))
  return f(curriedget(chan1))(curriedget(chan2))
})())})(_col))})(null))})((function (){
  var chan = new Channel();
  var finchan = new Channel();
  var g1 = (_clk1);
  var g2 = (_clk2);
  var f1 = (_x => (_y => ((function(kill){return ((function(_cl1){return ((function(_cl2){return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())})((function(){
  var chan = new Channel();
  var g = (_y);
  var f = (_un => ((function(kill){return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_blue)})());
  return curriedget(chan);
})())})(_un)));
  g( x => f(x)(y => chan.put(y)) );
  return curriedget(chan);
})()))})((function(){return (_red)})()))})(_x)))); // what i have, what i dont have, what it do
  var f2 = (_y => (_x => ((function(kill){return ((function(_cl1){return ((function(_cl2){return ((function(){
  var chan = new Channel();
  chan.put([_cl1, _cl2]);
  return curriedget(chan);
})())})((function(){
  var chan = new Channel();
  var g = (_x);
  var f = (_un => ((function(kill){return ((function(){
  var chan = new Channel();
  chan.put((function(){return (_yellow)})());
  return curriedget(chan);
})())})(_un)));
  g( x => f(x)(y => chan.put(y)) );
  return curriedget(chan);
})()))})((function(){return (_green)})()))})(_y))));
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
})()))
  })(pair[0], pair[1])
})())
  })(pair[0], pair[1])
})())})(((function(){return (_mkButton)})())(null)))})(null))})(((function(){return (_mkButton)})())(null)))})(null))})(((function(){return (_mkButton)})())(null)))})(null)

)};