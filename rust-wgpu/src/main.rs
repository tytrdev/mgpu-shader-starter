use std::sync::Arc;
use std::time::Instant;

use starter::{make_pipeline, render_offscreen, write_ppm, Uniforms};
use winit::{
    event::{ElementState, Event, MouseButton, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() >= 3 {
        let res: u32 = args[1].parse().unwrap_or(256);
        match render_offscreen(res) {
            Some(rgb) => {
                write_ppm(&args[2], res, &rgb).expect("write ppm");
                eprintln!("wrote {}", args[2]);
            }
            None => {
                eprintln!("skip: no adapter");
                std::process::exit(77);
            }
        }
        return;
    }
    run_window();
}

fn run_window() {
    let event_loop = EventLoop::new().unwrap();
    let window = Arc::new(
        WindowBuilder::new()
            .with_title("rust-wgpu")
            .build(&event_loop)
            .unwrap(),
    );

    let instance = wgpu::Instance::default();
    let surface = instance.create_surface(window.clone()).unwrap();
    let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
        power_preference: wgpu::PowerPreference::HighPerformance,
        compatible_surface: Some(&surface),
        force_fallback_adapter: false,
    }))
    .unwrap();
    let (device, queue) =
        pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor::default(), None))
            .unwrap();

    let caps = surface.get_capabilities(&adapter);
    let format = caps
        .formats
        .iter()
        .copied()
        .find(|f| !f.is_srgb())
        .unwrap_or(caps.formats[0]);
    let size = window.inner_size();
    let mut config = wgpu::SurfaceConfiguration {
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
        format,
        width: size.width.max(1),
        height: size.height.max(1),
        present_mode: caps.present_modes[0],
        alpha_mode: caps.alpha_modes[0],
        view_formats: vec![],
        desired_maximum_frame_latency: 2,
    };
    surface.configure(&device, &config);

    let (pipeline, bgl) = make_pipeline(&device, format);
    let ubo = device.create_buffer(&wgpu::BufferDescriptor {
        label: None,
        size: std::mem::size_of::<Uniforms>() as u64,
        usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        mapped_at_creation: false,
    });
    let bind = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: None,
        layout: &bgl,
        entries: &[wgpu::BindGroupEntry {
            binding: 0,
            resource: ubo.as_entire_binding(),
        }],
    });

    let start = Instant::now();
    let mut last = 0.0f32;
    let mut frame = 0i32;
    let mut mouse = [0.0f32; 4];
    let mut down = false;

    event_loop.set_control_flow(ControlFlow::Poll);
    event_loop
        .run(move |event, elwt| match event {
            Event::WindowEvent { event, .. } => match event {
                WindowEvent::CloseRequested => elwt.exit(),
                WindowEvent::Resized(new) => {
                    config.width = new.width.max(1);
                    config.height = new.height.max(1);
                    surface.configure(&device, &config);
                }
                WindowEvent::MouseInput { state, button, .. } => {
                    if button == MouseButton::Left {
                        down = state == ElementState::Pressed;
                    }
                }
                WindowEvent::CursorMoved { position, .. } => {
                    let y = config.height as f32 - position.y as f32;
                    mouse[0] = position.x as f32;
                    mouse[1] = y;
                    if down {
                        mouse[2] = position.x as f32;
                        mouse[3] = y;
                    }
                }
                WindowEvent::RedrawRequested => {
                    let t = start.elapsed().as_secs_f32();
                    let u = Uniforms {
                        i_resolution: [config.width as f32, config.height as f32, 1.0],
                        i_time: t,
                        i_mouse: mouse,
                        i_time_delta: t - last,
                        i_frame: frame,
                        _pad: [0.0; 2],
                    };
                    last = t;
                    frame += 1;
                    queue.write_buffer(&ubo, 0, bytemuck::bytes_of(&u));

                    let frame_tex = match surface.get_current_texture() {
                        Ok(f) => f,
                        Err(_) => {
                            surface.configure(&device, &config);
                            return;
                        }
                    };
                    let view = frame_tex
                        .texture
                        .create_view(&wgpu::TextureViewDescriptor::default());
                    let mut enc = device
                        .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
                    {
                        let mut pass = enc.begin_render_pass(&wgpu::RenderPassDescriptor {
                            label: None,
                            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                                view: &view,
                                resolve_target: None,
                                ops: wgpu::Operations {
                                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                                    store: wgpu::StoreOp::Store,
                                },
                            })],
                            depth_stencil_attachment: None,
                            timestamp_writes: None,
                            occlusion_query_set: None,
                        });
                        pass.set_pipeline(&pipeline);
                        pass.set_bind_group(0, &bind, &[]);
                        pass.draw(0..3, 0..1);
                    }
                    queue.submit([enc.finish()]);
                    frame_tex.present();
                }
                _ => {}
            },
            Event::AboutToWait => window.request_redraw(),
            _ => {}
        })
        .unwrap();
}
