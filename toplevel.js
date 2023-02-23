class Channel{
    constructor(){
        this.state = {state: "new"}
    }
    get(k){
        if (this.state.state=="new"){
            this.state = {state: "cb", cb: k}
        }
        else if (this.state.state=="value"){
            var v = this.state.v
            this.state = {state:"done"}
            return k(v);
        }
    }
    put(v){
        if (this.state.state=="new"){
            this.state = {state: "value", v: v}
        }
        else if (this.state.state=="cb"){
            var cb = this.state.cb;
            this.state = {state: "done"}
            return cb(v);
        }
    }
}

let curriedget = ch => cb => ch.get(cb);

let _mkButton = (unit => {
    let b = document.createElement("button");
    return b;
})

let _onClick = (id => widget => {
    return [widget, function(cb){return widget.addEventListener("click", cb)}];
})

let _setColor = (id => ([widget, color]) => {
    widget.style.color = color;
    return widget;
})

let _split = (id => t => widget => {
    return [widget, function(cb){return cb(widget)}];
})

let _join = (id => t => ([prf, future_widget]) => {
    return future_widget(x=>x);
})

let _red = "red";

let run = () => document.body.append(main())