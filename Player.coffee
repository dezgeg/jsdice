Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4
Euler = THREE.Euler

class Dice
    constructor: (diceGroup, x, z) ->
        unless Dice.cubeMaterial
            cubeFaces = []
            for i in [1..6]
                tex = new THREE.ImageUtils.loadTexture("images/dice-c#{i}.png")
                cubeFaces.push(new THREE.MeshBasicMaterial({ map: tex }))
            Dice.cubeMaterial = new THREE.MeshFaceMaterial(cubeFaces)
            Dice.cubeGeom = new THREE.CubeGeometry(DICE, DICE, DICE)

        @mesh = new THREE.Mesh(Dice.cubeGeom, Dice.cubeMaterial)
        @mesh.position.x = x
        @mesh.position.z = z
        @mesh.position.y = DICE/2
        diceGroup.add(@mesh)
window.Dice = Dice

class Player
    constructor: (diceGroup, @dice, x, z) ->
        unless Player.coneMaterial
            Player.coneMaterial = new THREE.MeshLambertMaterial({ color: 0xCC0000 })
            Player.coneGeom = new THREE.CylinderGeometry(DICE/4, 0, DICE)
            Player.coneGeom.applyMatrix(new Matrix4().makeTranslation(0, DICE/2, 0))
        @playerMesh = new THREE.Mesh(Player.coneGeom, Player.coneMaterial)
        @playerMesh.position.x = x
        @playerMesh.position.z = z
        @playerMesh.position.y = 1
        diceGroup.add(@playerMesh)

        @playerOrigPosition = undefined
        @cubeRotationDir = undefined
        @cubeRotationAmount = undefined
        @cubeRotationAxis = undefined
        @cubeTranslatedMatrix = undefined

    move: (dir) ->
        return false if @cubeRotationDir

        ox = Math.round(@playerMesh.position.x)
        oz = Math.round(@playerMesh.position.z)
        @playerMesh.position.add(dir.clone().multiplyScalar(0.05))
        nx = Math.round(@playerMesh.position.x)
        nz = Math.round(@playerMesh.position.z)
        return false if ox == nx && oz == nz

        @playerOrigPosition = @playerMesh.position.clone()
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

        return true if @cubeRotationAmount < 1

        inv = new Matrix4().getInverse(@cubeTranslatedMatrix)
        @dice.mesh.geometry.applyMatrix(inv)
        @dice.mesh.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(@dice.mesh.rotation))
        @dice.mesh.geometry.verticesNeedUpdate = true
        @dice.mesh.geometry.elementsNeedUpdate = true
        @dice.mesh.geometry.normalsNeedUpdate = true
        @dice.mesh.geometry.computeFaceNormals()

        @dice.mesh.position.add(@cubeRotationDir)
        @dice.mesh.position.add(@cubeRotationDir.clone().multiplyScalar(-1/2))
        @dice.mesh.position.y = DICE/2

        @dice.mesh.rotation.set(0, 0, 0)
        @cubeRotationDir = undefined

        return true

    calculateDiceNumber: () ->
        for face in @dice.mesh.geometry.faces
            dp = face.normal.dot(new Vector3(0, 1, 0))
            if dp > 0.2
                return face.materialIndex + 1
        return undefined
window.Player = Player
