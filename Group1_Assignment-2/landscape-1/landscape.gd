extends Node3D


@export var grid_size: int = 50 #Total Quads

@export var quad_size: float = 1.0 # Size of each quad

@export var height_scale: float = 5.0 # Height scale to amplify the noise

var land: MeshInstance3D

func _ready():
	land = MeshInstance3D.new()

	
	var noise = FastNoiseLite.new() #FastNoiseLite instance
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	noise.fractal_octaves = 4

	
	var st = SurfaceTool.new() #surface tool for generating the mesh
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate the vertices and indices for a grid of quads
	var count: Array[int] = [0]
	
	for z in range(grid_size):
		for x in range(grid_size):
			
			var noise_value = noise.get_noise_2d(x, z)
			var height = noise_value * height_scale
			
			
			_quad(st, Vector3(x * quad_size, height, z * quad_size), quad_size, count, noise)
	
	
	st.generate_normals() # Generate the normals
	var mesh = st.commit()
	land.mesh = mesh
	

	var material = StandardMaterial3D.new() # Create and assign the material
	material.albedo_color = Color(0.5, 0.5, 0.5) # Light grey color
	land.material_override = material

	# Calculate half of the terrain size
	var half_terrain_size = (grid_size * quad_size) / 2.0

	
	land.position = Vector3(-half_terrain_size, 0, -half_terrain_size)
	
	
	add_child(land) # Add the generated mesh to the scene

# Function to create a quad using the surface tool
func _quad(
	st: SurfaceTool,
	pt: Vector3,
	quad_size: float,
	count: Array[int],
	noise: FastNoiseLite
	):
	# Each corner of the quad
	var height_bl = noise.get_noise_2d(pt.x, pt.z) * height_scale
	var height_br = noise.get_noise_2d(pt.x + quad_size, pt.z) * height_scale
	var height_tl = noise.get_noise_2d(pt.x, pt.z + quad_size) * height_scale
	var height_tr = noise.get_noise_2d(pt.x + quad_size, pt.z + quad_size) * height_scale

	st.set_uv(Vector2(0, 0))
	st.add_vertex(pt + Vector3(0, height_bl, 0)) # bottom-left
	count[0] += 1

	st.set_uv(Vector2(1, 0))
	st.add_vertex(pt + Vector3(quad_size, height_br, 0)) # bottom-right
	count[0] += 1

	st.set_uv(Vector2(1, 1))
	st.add_vertex(pt + Vector3(quad_size, height_tr, quad_size)) # top-right
	count[0] += 1

	st.set_uv(Vector2(0, 1))
	st.add_vertex(pt + Vector3(0, height_tl, quad_size)) # top-left
	count[0] += 1

	# First triangle of the quad
	st.add_index(count[0] - 4)
	st.add_index(count[0] - 3)
	st.add_index(count[0] - 2)

	# Second triangle of the quad
	st.add_index(count[0] - 4)
	st.add_index(count[0] - 2)
	st.add_index(count[0] - 1)
