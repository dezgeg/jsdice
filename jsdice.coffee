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
    lvl = LEVELS[16]
    for i in [0...BOARD]
        for j in [0...BOARD]
            unless lvl.level[i][j]
                f = 2 * (BOARD * i + j)
                plane.geometry.faces[f].color.setHex(0)
                plane.geometry.faces[f+1].color.setHex(0)
                plane.geometry.colorsNeedUpdate = true

    # container for die
    diceGroup = new THREE.Object3D()
    diceGroup.translateX(-BOARD/2 + DICE/2)
    diceGroup.translateY(0)
    diceGroup.translateZ(-BOARD/2 + DICE/2)
    scene.add(diceGroup)

    cubeFaces = []
    for i in [1..6]
        tex = new THREE.ImageUtils.loadTexture("images/dice-c#{i}.png")
        cubeFaces.push(new THREE.MeshBasicMaterial({ map: tex }))

    cubeMaterial = new THREE.MeshFaceMaterial(cubeFaces)
    cubeGeom = new THREE.CubeGeometry(DICE, DICE, DICE)

    cube = window.cube = new THREE.Mesh(cubeGeom, cubeMaterial)
    cube.position.x = lvl.px
    cube.position.z = lvl.py
    cube.position.y = DICE/2
    diceGroup.add(cube)

    coneMaterial = new THREE.MeshLambertMaterial({ color: 0xCC0000 })
    coneGeom = new THREE.CylinderGeometry(DICE/4, 0, DICE)
    coneGeom.applyMatrix(new Matrix4().makeTranslation(0, DICE/2, 0))
    cone = new THREE.Mesh(coneGeom, coneMaterial)
    cone.position.x = lvl.px
    cone.position.z = lvl.py
    cone.position.y = 1
    diceGroup.add(cone)

    player = new Player(cube, cone)

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
