---@meta

---@class PhotonElementMeshStateProperties
---@field BloomColor? PhotonBlendColor
---@field DrawColor? PhotonBlendColor
---@field Intensity? number
---@field IntensityGainFactor? number
---@field IntensityLossFactor? number
---@field TargetIntensity? number
---@field IntensityTransitions? boolean
---@field DrawMaterial? string | IMaterial Material to use when drawing the mesh.
---@field BloomMaterial? string | IMaterial Material to use 

---@class PhotonElementMeshProperties : PhotonElementMeshStateProperties, PhotonElementPositionalProperties
---@field Model string Name of model that contains the mesh.
---@field MeshName? string Mesh name (model sub-material).
---@field Scale? Vector
---@field States? table<string, PhotonElementMeshStateProperties>
---@field ManipulateAlpha? boolean If the mesh's alpha channel should be manipulated.
---@field EnableDraw? boolean Whether or the mesh should be rendered in the normal pass.
---@field EnableBloom? boolean Whether or not the mesh should be drawn during the bloom pass.

---@class PhotonElementMeshEntry : PhotonElementMeshProperties
---@field [1] string Element template name.
---@field [2] Vector Local position.
---@field [3] Angle Local angles.
---@field [4] string Mesh sub-material.

---@class PhotonElementMesh : PhotonElement, PhotonElementMeshProperties
---@field MeshSubIndex? number Model's mesh sub-index (default = `1`).
---@field Mesh? IMesh
---@field LocalPosition? Vector
---@field LocalAngles? Angle
---@field Matrix? VMatrix
---@field protected FinalScale? Vector The scale of the mesh multiplied by the scale of its spawned parent. Set automatically.
---@field States? table<string, PhotonElementMeshState>
---@field Initialize fun(self: PhotonElementMesh, id: number, component: PhotonLightingComponent)