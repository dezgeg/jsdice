class Board
    constructor: (scene) ->
        # plane
        planeTexture = new THREE.ImageUtils.loadTexture('images/grid0.png')
        planeTexture.wrapS = planeTexture.wrapT = THREE.RepeatWrapping
        planeTexture.repeat.set(BOARD, BOARD)

        planeMaterial = new THREE.MeshBasicMaterial({ map: planeTexture, vertexColors: THREE.FaceColors })
        planeGeom = new THREE.PlaneGeometry(BOARD, BOARD, BOARD, BOARD)
        @floorPlane = new THREE.Mesh(planeGeom, planeMaterial)
        @floorPlane.rotation.x = -Math.PI / 2
        scene.add(@floorPlane)

        # container for die
        @diceContainer = new THREE.Object3D()
        @diceContainer.translateX(-BOARD/2 + DICE/2)
        @diceContainer.translateY(0)
        @diceContainer.translateZ(-BOARD/2 + DICE/2)
        scene.add(@diceContainer)

    loadLevel: (lvl, @player) ->
        @levelData = lvl
        @dices = []
        @player.dice = null
        for i in [0...BOARD]
            @dices[i] = []
            for j in [0...BOARD]
                entry = lvl.level[i][j]
                if entry > 1
                    type = Math.round(10 * (entry - Math.floor(entry)))
                    d = new Dice(this, j, i, type, Math.floor(entry))
                    @dices[i][j] = d
                    if j == lvl.px && i == lvl.py
                        @player.playerMesh.position.set(j, 1, i)
                        @player.dice = d
                else if entry == 0
                    f = 2 * (BOARD * i + j)
                    @floorPlane.geometry.faces[f].color.setHex(0)
                    @floorPlane.geometry.faces[f+1].color.setHex(0)
        @floorPlane.geometry.colorsNeedUpdate = true
window.Board = Board

class Dice
    DICE_TYPES:
        5: 'normal'
        6: 'wood'
        7: 'ice'
        8: 'stone'
        9: 'iron'

    materials: {}

    constructor: (board, x, z, type, rot) ->
        type ||= 'normal'
        if typeof type != 'string'
            type = Dice::DICE_TYPES[type]

        @type = type
        unless Dice::materials[type]
            Dice::materials[type] = []
            for mode in ['normal', 'vanishing']
                sides = [null]
                for i in [1..6]
                    tex = new THREE.ImageUtils.loadTexture("images/dice/#{type}/#{i}.png")
                    material = new THREE.MeshLambertMaterial({ map: tex })
                    if mode == 'vanishing'
                        material.emissive.setHex(0xFF0000)
                    material.jsDiceSideValue = i
                    sides.push(material)
                # Order is +X, -X, +Y, -Y, +Z, -Z
                Dice::materials[type][mode] = new THREE.MeshFaceMaterial([
                    sides[1], sides[6], sides[2], sides[5], sides[3], sides[4],
                ])

        @mesh = new THREE.Mesh(new THREE.CubeGeometry(1, 1, 1), Dice::materials[type].normal)
        @mesh.position.set(x, 1/2, z)

        if typeof rot == 'number'
            rot = ROTATIONS[rot]
        if typeof rot != 'undefined'
            @mesh.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(rot))

        board.diceContainer.add(@mesh)

    getValue: (dir) ->
        for face in @mesh.geometry.faces
            dp = face.normal.dot(dir || new Vector3(0, 1, 0))
            if dp > 0.2
                return @mesh.material.materials[face.materialIndex].jsDiceSideValue
        return undefined
window.Dice = Dice

class Player
    constructor: (@board) ->
        unless Player.coneMaterial
            Player.coneMaterial = new THREE.MeshLambertMaterial({ color: 0xFF0000, ambient: 0xFF0000 })
            Player.coneGeom = new THREE.CylinderGeometry(DICE/4, 0, DICE)
            Player.coneGeom.applyMatrix(new Matrix4().makeTranslation(0, DICE/2, 0))
        @playerMesh = new THREE.Mesh(Player.coneGeom, Player.coneMaterial)
        @board.diceContainer.add(@playerMesh)

        @playerOrigPosition = undefined
        @cubeOrigPosition = undefined
        @cubeRotationDir = undefined
        @cubeRotationAmount = undefined
        @cubeRotationAxis = undefined
        @cubeTranslatedMatrix = undefined

    move: (dir) ->
        return false if @cubeRotationDir

        ox = Math.round(@playerMesh.position.x)
        oz = Math.round(@playerMesh.position.z)
        newPos = @playerMesh.position.clone().add(dir.clone().multiplyScalar(0.05))
        nx = Math.round(newPos.x)
        nz = Math.round(newPos.z)
        if ox == nx && oz == nz
            # Player didn't cross dice boundary.
            @playerMesh.position = newPos
            return false

        if nx < 0 or nz < 0 or nx >= BOARD or nz >= BOARD
            return false

        unless @board.levelData.level[nz][nx]
            # No floor
            return false

        newDice = @board.dices[nz][nx]
        if newDice
            # Just step onto the next dice
            @playerMesh.position = newPos
            @dice = newDice
            return false

        # Otherwise, we do the roll animation
        @playerOrigPosition = @playerMesh.position.clone()
        @cubeOrigPosition = @dice.mesh.position.clone()
        @cubeRotationDir = dir
        @cubeRotationAmount = 0
        @cubeRotationAxis = dir.clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI/2)

        @cubeTranslatedMatrix = new Matrix4().makeTranslation(-dir.x/2, DICE/2, -dir.z/2)
        @dice.mesh.position.add(new Vector3(dir.x/2, -DICE/2, dir.z/2))
        @dice.mesh.geometry.applyMatrix(@cubeTranslatedMatrix)
        @dice.mesh.geometry.verticesNeedUpdate = true

        return true

    update: () ->
        return false unless @cubeRotationDir
        @cubeRotationAmount += 0.05

        axis = @cubeRotationAxis.clone()
        axis.multiplyScalar(@cubeRotationAmount * Math.PI / 2)
        @dice.mesh.rotation = new Euler(axis.x, axis.y, axis.z)
        @playerMesh.position = @playerOrigPosition.clone().add(
            @cubeRotationDir.clone().multiplyScalar(0.5 * @cubeRotationAmount))
        @playerMesh.position.y += Math.sqrt(2) * @cubeRotationAmount * (1 - @cubeRotationAmount)

        # Rotation finished?
        return true if @cubeRotationAmount < 1

        inv = new Matrix4().getInverse(@cubeTranslatedMatrix)
        @dice.mesh.geometry.applyMatrix(inv)
        @dice.mesh.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(@dice.mesh.rotation))
        @dice.mesh.geometry.verticesNeedUpdate = true
        @dice.mesh.geometry.elementsNeedUpdate = true
        @dice.mesh.geometry.normalsNeedUpdate = true
        @dice.mesh.geometry.computeFaceNormals()

        @dice.mesh.position.add(@cubeRotationDir.clone().multiplyScalar(1/2))
        @dice.mesh.position.y = DICE/2
        @dice.mesh.rotation.set(0, 0, 0)

        @board.dices[@cubeOrigPosition.z][@cubeOrigPosition.x] = null
        @board.dices[@dice.mesh.position.z][@dice.mesh.position.x] = @dice

        console.log(@checkForNewVanishingDice())

        @cubeRotationDir = undefined
        return true

    checkForNewVanishingDice: () ->
        goodDices = {}
        wantedValue = @dice.getValue()
        return false if wantedValue == 1

        recurse = (x, z) =>
            return if goodDices[x + ',' + z] or x < 0 or z < 0 or x >= BOARD or z >= BOARD
            dice = @board.dices[z][x]
            return if not dice

            if dice.getValue() == wantedValue
                goodDices[x + ',' + z] = dice
                for i, dir of DIRECTIONS
                    recurse(x + dir.x, z + dir.z)
            return
        recurse(@dice.mesh.position.x, @dice.mesh.position.z)

        if _.size(goodDices) >= wantedValue
            for key, dice of goodDices
                dice.mesh.material = Dice::materials[dice.type].vanishing
            return true
        return false

window.Player = Player
