#version 300 es

#if defined GL_EXT_shader_framebuffer_fetch
#extension GL_EXT_shader_framebuffer_fetch : require
#elif defined GL_ARM_shader_framebuffer_fetch
#extension GL_ARM_shader_framebuffer_fetch : require
#endif

precision highp float;
#define GLSLIFY 1

layout(std140) uniform glfx_GLOBAL
{
	highp mat4 glfx_MVP;
	highp mat4 glfx_PROJ;
	highp mat4 glfx_MV;
	highp vec4 glfx_QUAT;

	// retouch
	highp vec4 js_softlight; // y - softlight strength, z - eyeflare strength
  highp vec4 js_skinsoftening_removebags_rotation;
	highp vec4 js_is_apply_makeup; // x - makeup, y - softlight, z - eyeflare
	highp vec4 js_makeup_type;

	// selective makeup
	highp vec4 js_blushes_color;
	highp vec4 js_contour_color;
	highp vec4 js_eyeliner_color;
	highp vec4 js_eyeshadow_color;
	highp vec4 js_lashes_color;
	highp vec4 js_lashes3d_color;
	highp vec4 js_brows_color;
	highp vec4 js_highlighter_color;

	// common variable
	// TODO: but actually has effect only for eyes coloring
	highp vec4 js_is_face_tracked;

	// LUT filter
	highp vec4 js_slider_pos_alpha;

	// background texture
	highp vec4 js_bg_rotation;
	highp vec4 js_bg_scale;
	highp vec4 js_bg_alpha;
	highp vec4 js_bg_content_mode;
	highp vec4 js_bg_blur_radius;

	// skin
	highp vec4 js_skin_color;

	// eyes coloring
	highp vec4 js_eyes_color;

	// hair coloring (monotone & gradient)
	highp vec4 js_hair_colors[8];
	highp vec4 js_hair_colors_size;
	// hair strands coloring
	highp vec4 js_strand_colors[5];

	// mat & shiny lips color
	highp vec4 js_lips_color;
	// mat lips brightness & contrast
	highp vec4 js_lips_brightness_contrast;
	// lips shine parameters: color saturation, brightness (intensity), saturation (color bleeding),  darkness (more is less)
	highp vec4 js_lips_shine;
	// lips glitter parameters noiseness (width), highlights, grain (pixely)
	highp vec4 js_lips_glitter;

	// the value must declared at the end - this is SDK convention
	// shiny lips nn-specific params

	highp vec4 lips_nn_params; // no `js_` prefix cuz the value is not set by JS but by SDK
};

in vec2 var_uv;

layout( location = 0 ) out vec4 frag_color;

uniform sampler2D tex_diffuse;

void main()
{
	vec4 lashes_color_added = js_lashes3d_color;
	// lashes_color_added = vec4 (1.,0.,0.,1.);
	vec4 lashes_original = texture(tex_diffuse,var_uv);
	frag_color = vec4(lashes_original.rgb + lashes_color_added.rgb, lashes_original.a);
}
