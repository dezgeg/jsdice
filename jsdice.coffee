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
    pointLight = new THREE.PointLight(0x88888888)
    pointLight.position.set(0, 10, 0)
    scene.add(pointLight)

    ambientLight = new THREE.AmbientLight(0x666666)
    scene.add(ambientLight)

    board = new Board(scene)
    window.player = player = new Player(board)
    board.loadLevel(LEVELS[16], player)

    # start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # attach the render-supplied DOM element
    container.append(renderer.domElement)
    keyboard = window.keyboard = new THREEx.KeyboardState()

    render = ->
        requestAnimationFrame(render)

        for key, dir of DIRECTIONS
            continue if not keyboard.pressed(key.toLowerCase())
            player.move(dir)
        player.update()

        for i in [0...BOARD]
            for j in [0...BOARD]
                board.dices[i][j].update() if board.dices[i][j]

        renderer.render(scene, camera)
        rendererStats.update(renderer)
    render()
