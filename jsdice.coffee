Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4

KeyCode =
    Left:   37
    Up:     38
    Right:  39
    Down:   40

$ ->
    # set the scene size
    WIDTH = 400
    HEIGHT = 300

    BOARD = 7
    DICE = 1

    # set some camera attributes
    VIEW_ANGLE = 45
    NEAR = 0.1
    FAR = 10000

    # get the DOM element to attach to
    # - assume we've got jQuery to hand
    container = $('#container')

    # create a WebGL renderer, camera
    # and a scene
    renderer = new THREE.WebGLRenderer()
    scene = new THREE.Scene()

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, WIDTH / HEIGHT, NEAR, FAR)

    # the camera starts at 0,0,0 so pull it back
    camera.position.x = 6
    camera.position.y = 8
    camera.position.z = 6
    camera.lookAt(new Vector3(0, 0, 0))
    camera.updateProjectionMatrix()
    scene.add(camera)

    # create a point light
    pointLight = new THREE.PointLight(0xFFFFFF)
    pointLight.position.x = 0
    pointLight.position.y = 10
    pointLight.position.z = 0
    scene.add(pointLight)
    ambientLight = new THREE.AmbientLight(0x222222)
    scene.add(ambientLight)

    # plane
    planeMaterial = new THREE.MeshLambertMaterial({ color: 0xCCCCCC })
    plane = new THREE.Mesh(new THREE.CubeGeometry(BOARD, DICE, BOARD), planeMaterial)
    scene.add(plane)

    # container for die
    diceGroup = new THREE.Object3D()
    diceGroup.translateX(-BOARD/2 + DICE/2)
    diceGroup.translateZ(-BOARD/2 + DICE/2)
    scene.add(diceGroup)

    cubeMaterial = new THREE.MeshLambertMaterial({ color: 0xCC0000 })
    cubeGeom = new THREE.CubeGeometry(DICE, DICE, DICE)
    cubeGeom.applyMatrix(new Matrix4().makeTranslation(0, DICE, 0))

    cube = new THREE.Mesh(cubeGeom, cubeMaterial)
    diceGroup.add(cube)

    # start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # attach the render-supplied DOM element
    container.append(renderer.domElement)

    render = ->
        requestAnimationFrame(render)
        renderer.render(scene, camera)
    render()

    DIRECTIONS = {}
    DIRECTIONS[KeyCode.Up] = new Vector3(0, 0, -1)
    DIRECTIONS[KeyCode.Down] = new Vector3(0, 0, 1)
    DIRECTIONS[KeyCode.Right] = new Vector3(1, 0, 0)
    DIRECTIONS[KeyCode.Left] = new Vector3(-1, 0, 0)

    $(document.body).keydown (e) ->
        dir = DIRECTIONS[e.keyCode]
        cube.applyMatrix(new Matrix4().makeTranslation(dir.x, dir.y, dir.z)) if dir

        if dir
            e.preventDefault()
            return false
        return true
