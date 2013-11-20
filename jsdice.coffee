Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4
Euler = THREE.Euler

KeyCode =
    Left:   37
    Up:     38
    Right:  39
    Down:   40

DIRECTIONS = {}
DIRECTIONS[KeyCode.Up] = new Vector3(0, 0, -1)
DIRECTIONS[KeyCode.Down] = new Vector3(0, 0, 1)
DIRECTIONS[KeyCode.Right] = new Vector3(1, 0, 0)
DIRECTIONS[KeyCode.Left] = new Vector3(-1, 0, 0)

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
    camera.position.set(6, 8, 6)
    camera.lookAt(new Vector3(0, 0, 0))
    camera.updateProjectionMatrix()
    scene.add(camera)

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

    side = new THREE.MeshLambertMaterial({ color: 0xCCCCCC })
    top = new THREE.MeshLambertMaterial({ map: planeTexture })
    planeMaterial = new THREE.MeshFaceMaterial([side, side, top, side, side, side])
    plane = new THREE.Mesh(new THREE.CubeGeometry(BOARD, DICE, BOARD), planeMaterial)
    scene.add(plane)

    # container for die
    diceGroup = new THREE.Object3D()
    diceGroup.translateX(-BOARD/2 + DICE/2)
    diceGroup.translateY(DICE/2)
    diceGroup.translateZ(-BOARD/2 + DICE/2)
    scene.add(diceGroup)

    cubeMaterial = new THREE.MeshLambertMaterial({ color: 0xCC0000 })
    cubeGeom = new THREE.CubeGeometry(DICE, DICE, DICE)
    cubeGeom.applyMatrix(new Matrix4().makeTranslation(0, DICE/2, 0))

    cube = window.cube = new THREE.Mesh(cubeGeom, cubeMaterial)
    diceGroup.add(cube)

    # start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # attach the render-supplied DOM element
    container.append(renderer.domElement)

    cubeRotationDir = undefined
    cubeRotationAmount = undefined
    cubeRotationAxis = undefined
    cubeTranslatedMatrix = undefined

    render = ->
        if cubeRotationDir
            cubeRotationAmount += 0.05

            axis = cubeRotationAxis.clone()
            axis.multiplyScalar(cubeRotationAmount * Math.PI / 2)
            cube.rotation = new Euler(axis.x, axis.y, axis.z)

            if cubeRotationAmount > 1
                inv = new Matrix4().getInverse(cubeTranslatedMatrix)
                cube.geometry.applyMatrix(inv)
                cube.geometry.verticesNeedUpdate = true

                cube.position.add(cubeRotationDir)
                cube.position.add(cubeRotationDir.clone().multiplyScalar(-1/2))
                cube.rotation = new Euler()

                cubeRotationDir = undefined
        requestAnimationFrame(render)
        renderer.render(scene, camera)
    render()

    $(document.body).keydown (e) ->
        dir = DIRECTIONS[e.keyCode]
        if dir and !cubeRotationDir
            cubeRotationDir = dir
            cubeRotationAmount = 0
            cubeRotationAxis = dir.clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI/2)

            cubeTranslatedMatrix = new Matrix4().makeTranslation(-dir.x/2, 0, -dir.z/2)
            cube.position.add(new Vector3(dir.x/2, 0, dir.z/2))
            cube.geometry.applyMatrix(cubeTranslatedMatrix)
            cube.geometry.verticesNeedUpdate = true

        if dir
            e.preventDefault()
            return false
        return true
