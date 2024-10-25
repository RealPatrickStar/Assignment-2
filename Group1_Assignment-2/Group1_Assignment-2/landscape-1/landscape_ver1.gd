extends Node3D

@export var grid_size: int = 256
@export var quad_size: float = 1.0
@export var height_scale: float = 20.0
@export var num_octaves: int = 4
@export var persistence: float = 0.5
@export var lacunarity: float = 2.0
@export var grass_texture_path: String = "res://path/to/your/grass_texture.png"  # Set path to your grass texture

var noise: FastNoiseLite
var noise_image: Image
var mesh_instance: MeshInstance3D

func _ready():
	generate_noise_image()
	generate_landscape()

func generate_noise_image():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = randi()
	noise_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGBAF)
	for y in range(grid_size):
		for x in range(grid_size):
			var noise_value = calculate_noise(x, y)
			noise_image.set_pixel(x, y, Color(noise_value, noise_value, noise_value, 1.0))
	print("Noise image generated")

func generate_landscape():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var offset = Vector3(-grid_size * quad_size / 2, 0, -grid_size * quad_size / 2)
	for z in range(grid_size):
		for x in range(grid_size):
			add_vertex(st, x, z, offset)
	st.generate_normals()
	var mesh = st.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	setup_material(mesh_instance)
	add_child(mesh_instance)
	print("Landscape generated")

func calculate_noise(x, y):
	var noise_value = 0.0
	var amplitude = 1.0
	var frequency = 1.0
	for i in range(num_octaves):
		noise_value += noise.get_noise_2d(x * frequency, y * frequency) * amplitude
		amplitude *= persistence
		frequency *= lacunarity
	return (noise_value + 1) * 0.5

func add_vertex(st, x, z, offset):
	var uv = Vector2(float(x) / (grid_size - 1), float(z) / (grid_size - 1))
	var height = get_height_from_uv(uv)
	st.set_uv(uv)
	st.add_vertex(Vector3(x * quad_size, height, z * quad_size) + offset)
	if x < grid_size - 1 and z < grid_size - 1:
		var i = z * grid_size + x
		st.add_index(i)
		st.add_index(i + grid_size + 1)
		st.add_index(i + grid_size)
		st.add_index(i)
		st.add_index(i + 1)
		st.add_index(i + grid_size + 1)

func setup_material(instance):
	var material = StandardMaterial3D.new()
	material.albedo_texture = load(grass_texture_path)
	material.roughness = 0.9  # Adjust for natural dullness of grass
	material.specular = 0.1  # Lower specular for a less shiny surface
	instance.set_surface_override_material(0, material)

func get_height_from_uv(uv: Vector2):
	var pixel_pos = uv * Vector2(noise_image.get_width() - 1, noise_image.get_height() - 1)
	return noise_image.get_pixelv(pixel_pos).r * height_scale
