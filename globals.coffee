window.Vector3 = THREE.Vector3
window.Matrix4 = THREE.Matrix4
window.Euler = THREE.Euler

window.DIRECTIONS =
    Up:     new Vector3(0, 0, -1)
    Down:   new Vector3(0, 0, 1)
    Right:  new Vector3(1, 0, 0)
    Left:   new Vector3(-1, 0, 0)

window.BOARD = 7
window.DICE = 1

window.ROTATIONS =
    1230: new Euler(0 * Math.PI/2, 1 * Math.PI/2, 1 * Math.PI/2),
    1350: new Euler(0 * Math.PI/2, 0 * Math.PI/2, 1 * Math.PI/2),
    1420: new Euler(0 * Math.PI/2, 2 * Math.PI/2, 1 * Math.PI/2),
    1540: new Euler(0 * Math.PI/2, 3 * Math.PI/2, 1 * Math.PI/2),
    2140: new Euler(0 * Math.PI/2, 3 * Math.PI/2, 0 * Math.PI/2),
    2310: new Euler(0 * Math.PI/2, 0 * Math.PI/2, 0 * Math.PI/2),
    2460: new Euler(0 * Math.PI/2, 2 * Math.PI/2, 0 * Math.PI/2),
    2630: new Euler(0 * Math.PI/2, 1 * Math.PI/2, 0 * Math.PI/2),
    3120: new Euler(1 * Math.PI/2, 2 * Math.PI/2, 1 * Math.PI/2),
    3260: new Euler(1 * Math.PI/2, 2 * Math.PI/2, 0 * Math.PI/2),
    3510: new Euler(1 * Math.PI/2, 2 * Math.PI/2, 2 * Math.PI/2),
    3650: new Euler(1 * Math.PI/2, 2 * Math.PI/2, 3 * Math.PI/2),
    4150: new Euler(1 * Math.PI/2, 0 * Math.PI/2, 1 * Math.PI/2),
    4210: new Euler(1 * Math.PI/2, 0 * Math.PI/2, 0 * Math.PI/2),
    4560: new Euler(1 * Math.PI/2, 0 * Math.PI/2, 2 * Math.PI/2),
    4620: new Euler(1 * Math.PI/2, 0 * Math.PI/2, 3 * Math.PI/2),
    5130: new Euler(0 * Math.PI/2, 1 * Math.PI/2, 2 * Math.PI/2),
    5360: new Euler(0 * Math.PI/2, 0 * Math.PI/2, 2 * Math.PI/2),
    5410: new Euler(0 * Math.PI/2, 2 * Math.PI/2, 2 * Math.PI/2),
    5640: new Euler(0 * Math.PI/2, 3 * Math.PI/2, 2 * Math.PI/2),
    6240: new Euler(0 * Math.PI/2, 3 * Math.PI/2, 3 * Math.PI/2),
    6320: new Euler(0 * Math.PI/2, 0 * Math.PI/2, 3 * Math.PI/2),
    6450: new Euler(0 * Math.PI/2, 2 * Math.PI/2, 3 * Math.PI/2),
    6530: new Euler(0 * Math.PI/2, 1 * Math.PI/2, 3 * Math.PI/2),
