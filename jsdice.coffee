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

    cubeMaterial = new THREE.MeshFaceMaterial([
        new THREE.MeshBasicMaterial({ color: 0xFF0000 }),
        new THREE.MeshBasicMaterial({ color: 0x00FF00 }),
        new THREE.MeshBasicMaterial({ color: 0x0000FF }),
        new THREE.MeshBasicMaterial({ color: 0x00FFFF }),
        new THREE.MeshBasicMaterial({ color: 0xFF00FF }),
        new THREE.MeshBasicMaterial({ color: 0xFFFF00 }),
    ])
    cubeGeom = new THREE.CubeGeometry(DICE, DICE, DICE)

    cube = window.cube = new THREE.Mesh(cubeGeom, cubeMaterial)
    cube.position.y = DICE/2
    diceGroup.add(cube)

    # start the renderer
    renderer.setSize(WIDTH, HEIGHT)

    # attach the render-supplied DOM element
    container.append(renderer.domElement)

    cubeRotationDir = undefined
    cubeRotationAmount = undefined
    cubeRotationAxis = undefined
    cubeTranslatedMatrix = undefined

    calculateDiceNumber = (dice) ->
        for face in dice.geometry.faces
            dp = face.normal.dot(new Vector3(0, 1, 0))
            if dp > 0.2
                console.log(face.normal, dice.material.materials[face.materialIndex].color)

    render = ->
        if cubeRotationDir
            cubeRotationAmount += 0.05

            axis = cubeRotationAxis.clone()
            axis.multiplyScalar(cubeRotationAmount * Math.PI / 2)
            cube.rotation = new Euler(axis.x, axis.y, axis.z)

            if cubeRotationAmount > 1
                inv = new Matrix4().getInverse(cubeTranslatedMatrix)
                cube.geometry.applyMatrix(inv)
                cube.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(cube.rotation))
                cube.geometry.verticesNeedUpdate = true
                cube.geometry.elementsNeedUpdate = true
                cube.geometry.normalsNeedUpdate = true
                cube.geometry.computeFaceNormals()

                cube.position.add(cubeRotationDir)
                cube.position.add(cubeRotationDir.clone().multiplyScalar(-1/2))
                cube.position.y = DICE/2

                cube.rotation.set(0, 0, 0)
                cubeRotationDir = undefined
                calculateDiceNumber(cube)

        requestAnimationFrame(render)
        renderer.render(scene, camera)
    render()

    $(document.body).keydown (e) ->
        dir = DIRECTIONS[e.keyCode]
        if dir and !cubeRotationDir
            cubeRotationDir = dir
            cubeRotationAmount = 0
            cubeRotationAxis = dir.clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI/2)

            cubeTranslatedMatrix = new Matrix4().makeTranslation(-dir.x/2, DICE/2, -dir.z/2)
            cube.position.add(new Vector3(dir.x/2, -DICE/2, dir.z/2))
            cube.geometry.applyMatrix(cubeTranslatedMatrix)
            cube.geometry.verticesNeedUpdate = true

        if dir
            e.preventDefault()
            return false
        return true
