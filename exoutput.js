/*

(
    let btn = mkButton () in
    let pack(i, w) = btn in
    let (w1, cl) = (onClick i) w in
    let pack(n, clt) = out cl in
    let @cla= clt in
    let (pr, wt) = ((split i) n) w1 in
    let @wa = wt in
    let wfa = ((@(
        let () = cla in
        (setColor i) (wa,(F Red))
        )) : Widget i @ n) in
    let wf = ((join i) n) (pr, wfa) in
    wf
) : Widget i


*/



function main(){

    let btn = document.createElement("button");

    let cl = btn.onClick

    let wt = cb => cb(btn)
    let pr = btn

    var chan = new Channel();

    cl(clr => {
      wt(wtr => {
        chan.put(wtr.setColor("red"))
      })
    })

    let wfa = chan.get;

    wfa(x=>x)

    wf = pr

    return wf
  };