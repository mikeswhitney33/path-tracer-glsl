import numpy as np
import moderngl_window as mglw
from PIL import Image

def make_program(ctx, vert_path, frag_path):
    with open(vert_path, 'r')  as f:
            vertex_source = f.read()
    with open(frag_path, 'r') as f:
        frag_source = f.read()

    return ctx.program(
        vertex_shader=vertex_source,
        fragment_shader=frag_source)

class PathTracer(mglw.WindowConfig):
    gl_version = (3, 3)
    title = "ModernGL Example"
    window_size = (1280, 720)
    aspect_ratio = 16/9
    resizable = True
    samples = 4
    path_to_frag = 'path-frag.glsl'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.tex_prog = make_program(self.ctx, 'tex-vert.glsl', 'tex-frag.glsl')
        self.path_prog = make_program(self.ctx, 'path-vert.glsl', self.path_to_frag)

        vertices = np.array([
            -1, -1,
            1, -1,
            1, 1,
            -1, -1,
            -1, 1,
            1, 1
        ])
        self.tex_vbo = self.ctx.buffer(vertices.astype('f4').tobytes())
        self.tex_vao = self.ctx.simple_vertex_array(self.tex_prog, self.tex_vbo, 'in_vert')
        self.path_vbo = self.ctx.buffer(vertices.astype('f4').tobytes())
        self.path_vao = self.ctx.simple_vertex_array(self.path_prog, self.path_vbo, 'in_vert')

        self.texture = self.ctx.texture(self.wnd.size, 3)
        self.fbo = self.ctx.simple_framebuffer(self.wnd.size)

        self.sample_i = 0
        self.sample_iu = self.path_prog['sample_i']
        self.aspect = self.path_prog['aspect']
        self.aspect.value = self.aspect_ratio
        self.scale = self.path_prog['scale']
        self.scale.value = np.tan(np.deg2rad(90) * 0.5)
        self.pixel_dim = self.path_prog['pixel_dim']
        self.pixel_dim.value = tuple(1 / np.array(self.wnd.size))


    def render(self, time, frame_time):
        self.fbo.clear(1, 1, 1)
        self.fbo.use()
        self.sample_iu.value = self.sample_i

        self.texture.use()
        self.path_vao.render()
        self.texture.write(self.fbo.read())

        self.ctx.clear(1.0, 1.0, 1.0)
        self.ctx.screen.use()
        self.texture.use()
        self.tex_vao.render()
        self.sample_i += 1

class RayTracer(mglw.WindowConfig):
    gl_version = (3, 3)
    title = "ModernGL Example"
    window_size = (1280, 720)
    aspect_ratio = 16/9
    resizable = True
    samples = 4
    path_to_frag = 'path-frag.glsl'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.tex_prog = make_program(self.ctx, 'tex-vert.glsl', 'tex-frag.glsl')
        
        
        self.path_prog = make_program(self.ctx, 'path-vert.glsl', self.path_to_frag)

        vertices = np.array([
            -1, -1,
            1, -1,
            1, 1,
            -1, -1,
            -1, 1,
            1, 1
        ])
        self.tex_vbo = self.ctx.buffer(vertices.astype('f4').tobytes())
        self.tex_vao = self.ctx.simple_vertex_array(self.tex_prog, self.tex_vbo, 'in_vert')
        self.path_vbo = self.ctx.buffer(vertices.astype('f4').tobytes())
        self.path_vao = self.ctx.simple_vertex_array(self.path_prog, self.path_vbo, 'in_vert')

        self.texture = self.ctx.texture(self.wnd.size, 3)
        self.fbo = self.ctx.simple_framebuffer(self.wnd.size)

        self.sample_i = 0
        self.sample_iu = self.path_prog['sample_i']
        self.aspect = self.path_prog['aspect']
        self.aspect.value = self.aspect_ratio
        self.scale = self.path_prog['scale']
        self.scale.value = np.tan(np.deg2rad(90) * 0.5)
        self.pixel_dim = self.path_prog['pixel_dim']
        self.pixel_dim.value = tuple(1 / np.array(self.wnd.size))


    def render(self, time, frame_time):
        self.fbo.clear(1, 1, 1)
        self.fbo.use()
        self.sample_iu.value = self.sample_i

        self.texture.use()
        self.path_vao.render()
        self.texture.write(self.fbo.read())

        self.ctx.clear(1.0, 1.0, 1.0)
        self.ctx.screen.use()
        self.texture.use()
        self.tex_vao.render()
        self.sample_i += 1

if __name__ == "__main__":
    mglw.run_window_config(PathTracer)