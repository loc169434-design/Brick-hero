# Turns a model from an AI 3D generator (.glb) into an .fbx Mixamo will rig, textures packed in.
#
#   /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/glb_to_fbx.py -- in.glb out.fbx
#
# The model is stood on the ground (lowest point at z = 0), centred, faced down -Y as Mixamo
# expects, and scaled to 1.7 m tall so its marker guides fit.
import sys, bpy
from mathutils import Vector

src, dst = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
corners = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
low = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
high = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
scale = 1.7 / max(high.z - low.z, 1e-6)
centre = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
for o in bpy.context.scene.objects:
    if o.parent is None:
        o.location = (o.location - centre) * scale
        o.scale = o.scale * scale
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.export_scene.fbx(filepath=dst, use_selection=False, path_mode="COPY", embed_textures=True, axis_forward="-Y", axis_up="Z")
print("fbx written: %s (%d meshes, was %.2f tall)" % (dst, len(meshes), high.z - low.z))
