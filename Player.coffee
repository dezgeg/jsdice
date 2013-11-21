Vector3 = THREE.Vector3
Matrix4 = THREE.Matrix4
Euler = THREE.Euler

class Player
    constructor: (@cube) ->
        @cubeRotationDir = undefined
        @cubeRotationAmount = undefined
        @cubeRotationAxis = undefined
        @cubeTranslatedMatrix = undefined

    beginRotate: (dir) ->
        return false if @cubeRotationDir
        @cubeRotationDir = dir
        @cubeRotationAmount = 0
        @cubeRotationAxis = dir.clone().applyAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI/2)

        @cubeTranslatedMatrix = new Matrix4().makeTranslation(-dir.x/2, DICE/2, -dir.z/2)
        @cube.position.add(new Vector3(dir.x/2, -DICE/2, dir.z/2))
        @cube.geometry.applyMatrix(@cubeTranslatedMatrix)
        @cube.geometry.verticesNeedUpdate = true

        return true

    update: () ->
        return false unless @cubeRotationDir
        @cubeRotationAmount += 0.05

        axis = @cubeRotationAxis.clone()
        axis.multiplyScalar(@cubeRotationAmount * Math.PI / 2)
        @cube.rotation = new Euler(axis.x, axis.y, axis.z)

        return true if @cubeRotationAmount < 1

        inv = new Matrix4().getInverse(@cubeTranslatedMatrix)
        @cube.geometry.applyMatrix(inv)
        @cube.geometry.applyMatrix(new Matrix4().makeRotationFromEuler(@cube.rotation))
        @cube.geometry.verticesNeedUpdate = true
        @cube.geometry.elementsNeedUpdate = true
        @cube.geometry.normalsNeedUpdate = true
        @cube.geometry.computeFaceNormals()

        @cube.position.add(@cubeRotationDir)
        @cube.position.add(@cubeRotationDir.clone().multiplyScalar(-1/2))
        @cube.position.y = DICE/2

        @cube.rotation.set(0, 0, 0)
        @cubeRotationDir = undefined

        return true

    calculateDiceNumber: () ->
        for face in @cube.geometry.faces
            dp = face.normal.dot(new Vector3(0, 1, 0))
            if dp > 0.2
                return face.materialIndex + 1
        return undefined

window.Player = Player
