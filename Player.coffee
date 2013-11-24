class Board
    constructor: (scene) ->
        @floorPlane = new THREE.Mesh(Resources.floorGeometry.clone(), Resources.floorMaterial)
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

    hasFloorAt: (x, z) ->
        if x < 0 or z < 0 or x >= BOARD or z >= BOARD
            return false
        return !!@levelData.level[z][x]

    getDiceAt: (x, z) ->
        if x < 0 or z < 0 or x >= BOARD or z >= BOARD
            return null
        return @dices[z][x]

window.Board = Board

class Dice
    DICE_TYPES:
        5: 'normal'
        6: 'wood'
        7: 'ice'
        8: 'stone'
        9: 'iron'
    VANISH_TRANSPARENT_THRESHOLD: 0.5

    constructor: (@board, x, z, type, rot) ->
        type ||= 'normal'
        if typeof type != 'string'
            type = Dice::DICE_TYPES[type]

        @type = type
        @state = "IDLE"
        @mesh = new THREE.Mesh(new THREE.CubeGeometry(1, 1, 1),
                Resources.diceMaterials[type].normal)
        @mesh.position.set(x, 1/2, z)
        @vanishMaterial = Resources.diceMaterials[type].vanishing
        @vanishTransparentMaterial = Resources.diceMaterials[type].vanishingTransparent

        if typeof rot == 'number'
            rot = ROTATIONS[rot]
        if typeof rot != 'undefined'
            @mesh.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(rot))

        @board.diceContainer.add(@mesh)

    update: () ->
        if @state == "VANISHING"
            @vanishAmount -= 0.005
            @mesh.position.y = -1/2 + @vanishAmount

            if @vanishAmount < Dice::VANISH_TRANSPARENT_THRESHOLD and @mesh.material == @vanishMaterial
                @mesh.material = @vanishTransparentMaterial

            else if @vanishAmount < 0
                if @board.player.dice == this
                    @board.player.dice = null
                @board.dices[@mesh.position.z][@mesh.position.x] = null
                @board.diceContainer.remove(@mesh)
                @state = "GONE"
        else if @state == "GONE"
            throw new Error("Dice should be gone")

    getValue: (dir) ->
        for face in @mesh.geometry.faces
            dp = face.normal.dot(dir || new Vector3(0, 1, 0))
            if dp > 0.2
                return @mesh.material.materials[face.materialIndex].jsDiceSideValue
        return undefined

    canRoll: () ->
        return @state == "IDLE"

    canSlide: () ->
        return @state == "IDLE"
window.Dice = Dice

class Player
    constructor: (@board) ->
        @playerMesh = new THREE.Mesh(Resources.playerGeometry, Resources.playerMaterial)
        @board.diceContainer.add(@playerMesh)

        @playerMovementAction = undefined

    # Get action to do when moving from integral coords (ox, oz) to (nx, nz)
    # Returns either: falsey, 'move', 'roll', 'slide'
    getMovementAction: (ox, oz, nx, nz, dir) ->
        if ox == nx && oz == nz
            # Player didn't cross dice boundary.
            return 'move'

        unless @board.hasFloorAt(nx, nz)
            return false

        newDice = @board.getDiceAt(nx, nz)
        if @dice
            # Just step onto the next dice
            if newDice
                # Just step onto the next dice
                return 'move'
            else
                return if @dice.canRoll() then 'roll' else false
        else
            # On the floor
            return 'move' if !newDice # Just move to another new empty square
            if !newDice.canSlide()
                return false
            newDiceX = nx + dir.x
            newDiceZ = nz + dir.z
            if !@board.hasFloorAt(newDiceX, newDiceZ) or @board.getDiceAt(newDiceX, newDiceZ)
                return false
            return 'slide'

    move: (dir) ->
        return false if @playerMovementAction

        ox = Math.round(@playerMesh.position.x)
        oz = Math.round(@playerMesh.position.z)
        newPos = @playerMesh.position.clone().add(dir.clone().multiplyScalar(0.05))
        nx = Math.round(newPos.x)
        nz = Math.round(newPos.z)

        movement = @getMovementAction(ox, oz, nx, nz, dir)
        if !movement
            return
        else if movement == 'move'
            @playerMesh.position = newPos
            @dice = @board.getDiceAt(nx, nz)
            return

        @playerMovementAction = movement
        @playerOrigPosition = @playerMesh.position.clone()
        @cubeRotationDir = dir
        @cubeRotationAmount = 0

        if movement == 'slide'
            @animatedDice = @board.getDiceAt(nx, nz)
            @cubeOrigPosition = @animatedDice.mesh.position.clone()
        else if movement == 'roll'
            # Otherwise, we do the roll animation
            @cubeOrigPosition = @dice.mesh.position.clone()
            @animatedDice = @dice
            @cubeRotationAxis = dir.clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI/2)

            @cubeTranslatedMatrix = new Matrix4().makeTranslation(-dir.x/2, DICE/2, -dir.z/2)
            @dice.mesh.position.add(new Vector3(dir.x/2, -DICE/2, dir.z/2))
            @dice.mesh.geometry.applyMatrix(@cubeTranslatedMatrix)
            @dice.mesh.geometry.verticesNeedUpdate = true

        return true

    update: () ->
        if not @playerMovementAction
            @playerMesh.position.y = 1/2 + @dice.mesh.position.y if @dice
            return
        @cubeRotationAmount += 0.05
        @cubeRotationAmount = Math.min(@cubeRotationAmount, 1.0)

        if @playerMovementAction == 'slide'
            # Constant of .99 to avoid float inaccuracies... :(
            @playerMesh.position = @playerOrigPosition.clone().add(
                @cubeRotationDir.clone().multiplyScalar(0.99 * @cubeRotationAmount))
            @animatedDice.mesh.position = @cubeOrigPosition.clone().add(
                @cubeRotationDir.clone().multiplyScalar(@cubeRotationAmount))
        else
            axis = @cubeRotationAxis.clone()
            axis.multiplyScalar(@cubeRotationAmount * Math.PI / 2)
            @animatedDice.mesh.rotation = new Euler(axis.x, axis.y, axis.z)
            @playerMesh.position = @playerOrigPosition.clone().add(
                @cubeRotationDir.clone().multiplyScalar(0.5 * @cubeRotationAmount))
            @playerMesh.position.y += Math.sqrt(2) * @cubeRotationAmount * (1 - @cubeRotationAmount)

        # Rotation finished?
        return true if @cubeRotationAmount < 1

        if @playerMovementAction == 'roll'
            inv = new Matrix4().getInverse(@cubeTranslatedMatrix)
            @animatedDice.mesh.geometry.applyMatrix(inv)
            @animatedDice.mesh.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(@animatedDice.mesh.rotation))
            @animatedDice.mesh.geometry.verticesNeedUpdate = true
            @animatedDice.mesh.geometry.elementsNeedUpdate = true
            @animatedDice.mesh.geometry.normalsNeedUpdate = true
            @animatedDice.mesh.geometry.computeFaceNormals()

            @animatedDice.mesh.position.add(@cubeRotationDir.clone().multiplyScalar(1/2))
            @animatedDice.mesh.position.y = DICE/2
            @animatedDice.mesh.rotation.set(0, 0, 0)

        @animatedDice.mesh.position.x = Math.round(@animatedDice.mesh.position.x)
        @animatedDice.mesh.position.z = Math.round(@animatedDice.mesh.position.z)
        @board.dices[@cubeOrigPosition.z][@cubeOrigPosition.x] = null
        @board.dices[@animatedDice.mesh.position.z][@animatedDice.mesh.position.x] = @animatedDice
        console.log(@checkForNewVanishingDice(@animatedDice))

        @playerMovementAction = null
        return true

    checkForNewVanishingDice: (startDice) ->
        goodDices = {}
        wantedValue = startDice.getValue()
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
        recurse(startDice.mesh.position.x, startDice.mesh.position.z)

        if _.size(goodDices) >= wantedValue
            for key, dice of goodDices
                dice.mesh.material = dice.vanishMaterial
                dice.state = 'VANISHING'
                if typeof dice.vanishAmount != 'number'
                    dice.vanishAmount = 1.0
            return true
        return false

window.Player = Player
