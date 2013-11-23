$ ->
    # set the scene size
    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight

    # set some camera attributes
    VIEW_ANGLE = 45
    NEAR = 0.1
    FAR = 10000

    # get the DOM element to attach to
    # - assume we've got jQuery to hand
    container = $('#container')

    # create a WebGL renderer, camera
    # and a scene
    renderer = new THREE.WebGLRenderer({ antialias: true })
    scene = new THREE.Scene()

    rendererStats = new THREEx.RendererStats()
    rendererStats.domElement.style.position = 'absolute'
    rendererStats.domElement.style.left = '0px'
    rendererStats.domElement.style.bottom   = '0px'
    document.body.appendChild(rendererStats.domElement)

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, WIDTH / HEIGHT, NEAR, FAR)
    camera.position.set(6, 8, 6)
    camera.lookAt(new Vector3(0, 0, 0))
    camera.updateProjectionMatrix()
    scene.add(camera)
    new THREEx.WindowResize(renderer, camera)

    # create a point light
    pointLight = new THREE.PointLight(0xFFFFFF)
    pointLight.position.set(0, 10, 0)
    scene.add(pointLight)

    ambientLight = new THREE.AmbientLight(0x222222)
    scene.add(ambientLight)

    # plane
    planeTexture = new THREE.ImageUtils.loadTexture('images/grid0.png')
    planeTexture.wrapS = planeTexture.wrapT = THREE.RepeatWrapping
    planeTexture.repeat.set(BOARD, BOARD)

    planeMaterial = new THREE.MeshBasicMaterial({ map: planeTexture, vertexColors: THREE.FaceColors })
    planeGeom = new THREE.PlaneGeometry(BOARD, BOARD, BOARD, BOARD)
    plane = new THREE.Mesh(planeGeom, planeMaterial)
    window.plane = plane
    plane.rotation.x = -Math.PI / 2
    scene.add(plane)

    # container for die
    diceGroup = new THREE.Object3D()
    diceGroup.translateX(-BOARD/2 + DICE/2)
    diceGroup.translateY(0)
    diceGroup.translateZ(-BOARD/2 + DICE/2)
    scene.add(diceGroup)

    # level load
    lvl = LEVELS[1]
    playerDice = null
    for i in [0...BOARD]
        for j in [0...BOARD]
            entry = lvl.level[i][j]
            if entry > 1
                type = Math.round(10 * (entry - Math.floor(entry)))
                d = new Dice(diceGroup, j, i, type, Math.floor(entry))
                playerDice = d if j == lvl.px && i == lvl.py
            else if entry == 0
                f = 2 * (BOARD * i + j)
                plane.geometry.faces[f].color.setHex(0)
                plane.geometry.faces[f+1].color.setHex(0)
    plane.geometry.colorsNeedUpdate = true

    if false
        # Generate rotations map
        result = {}
        for i in [0...4]
            for j in [0...4]
                for k in [0...4]
                        dir = new Euler(i * Math.PI/2, k * Math.PI/2, j * Math.PI/2)
                        dice = new Dice(diceGroup, 2*i, 2*j, 'normal', dir)
                        topNum = dice.calculateDiceNumber()
                        frontNum = dice.calculateDiceNumber(DIRECTIONS.Down)
                        sideNum = dice.calculateDiceNumber(DIRECTIONS.Right)
                        key = 1000*topNum + 100*frontNum + 10*sideNum
                        s = "new Euler(#{i} * Math.PI/2, #{k} * Math.PI/2, #{j} * Math.PI/2)"
                        result[key] = s if result[key] == undefined
                        console.log(i, j, k, key)
        console.log(JSON.stringify(result))
        window.result = result

    player = new Player(diceGroup, playerDice, lvl.px, lvl.py)

    # start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # attach the render-supplied DOM element
    container.append(renderer.domElement)
    keyboard = window.keyboard = new THREEx.KeyboardState()

    render = ->
        for key, dir of DIRECTIONS
            continue if not keyboard.pressed(key.toLowerCase())
            player.move(dir)
        player.update()

        requestAnimationFrame(render)
        renderer.render(scene, camera)
        rendererStats.update(renderer)
    render()
