class Resources
    # Board
    @floorTexture = new THREE.ImageUtils.loadTexture('images/grid0.png')
    @floorTexture.wrapS = @floorTexture.wrapT = THREE.RepeatWrapping
    @floorTexture.repeat.set(BOARD, BOARD)

    @floorMaterial = new THREE.MeshBasicMaterial({ map: @floorTexture, vertexColors: THREE.FaceColors })
    @floorGeometry = new THREE.PlaneGeometry(BOARD, BOARD, BOARD, BOARD)

    # Player
    @playerMaterial = new THREE.MeshLambertMaterial({ color: 0xFF0000, ambient: 0xFF0000 })
    @playerGeometry = new THREE.CylinderGeometry(1/4, 0, 1)
    @playerGeometry.applyMatrix(new Matrix4().makeTranslation(0, 1/2, 0))

    # Dice
    @diceMaterials = {}
    for code, type of Dice::DICE_TYPES
        @diceMaterials[type] = {}
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
            @diceMaterials[type][mode] = new THREE.MeshFaceMaterial([
                sides[1], sides[6], sides[2], sides[5], sides[3], sides[4],
            ])
window.Resources = Resources
