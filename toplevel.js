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
            k(v);
        }
    }
    put(v){
        if (this.state.state=="new"){
            this.state = {state: "value", v: v}
        }
        else if (this.state.state=="cb"){
            var cb = this.state.cb;
            this.state = {state: "done"}
            cb(v);
        }
    }
}

let curriedget = ch => cb => ch.get(cb);
let curriedput = ch => cb => ch.put(cb);

let _mkButton = (unit => {
    let b = document.createElement("button");
    return b;
})

let _mkText = (unit => {
    return document.createElement("div");
})

let _mkOList = (unit => {
    return document.createElement("ol");
})

let _mkUList = (unit => {
    return document.createElement("ul");
})

let _mkListItem = (unit => {
    return document.createElement("li");
})

let _onClick = (id => widget => {
    return [widget, function(cb){return widget.addEventListener("click", cb, {once: true})}];
})

let _setText = (id => ([widget, text]) => {
    widget.textContent = text
    return widget
})

let _setColor = (id => ([widget, color]) => {
    widget.style.color = color;
    return widget;
})

let _split = (id => t => widget => {
    return [widget, function(cb){return cb(widget)}];
})

let _join = (id => t => ([prf, future_widget]) => {
    future_widget(x=>x)
    return prf;
})

let _red = "red";

let _blue = "blue";

let _green = "green";

let _yellow = "yellow";

let run = () => {
    document.body.textContent = ""
    let res = main()
    document.body.append(res)
    return res
}