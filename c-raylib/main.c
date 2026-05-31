#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    Shader shader;
    int locRes, locTime, locDelta, locFrame, locMouse;
} Uniforms;

static Uniforms load_uniforms(void) {
    Shader s = LoadShader(0, "shader.fs");
    Uniforms u = {s,
                  GetShaderLocation(s, "iResolution"),
                  GetShaderLocation(s, "iTime"),
                  GetShaderLocation(s, "iTimeDelta"),
                  GetShaderLocation(s, "iFrame"),
                  GetShaderLocation(s, "iMouse")};
    return u;
}

static void set_uniforms(Uniforms u, float w, float h, float t, float dt, int frame, Vector4 mouse) {
    float res[3] = {w, h, 1.0f};
    float ms[4] = {mouse.x, mouse.y, mouse.z, mouse.w};
    SetShaderValue(u.shader, u.locRes, res, SHADER_UNIFORM_VEC3);
    SetShaderValue(u.shader, u.locTime, &t, SHADER_UNIFORM_FLOAT);
    SetShaderValue(u.shader, u.locDelta, &dt, SHADER_UNIFORM_FLOAT);
    SetShaderValue(u.shader, u.locFrame, &frame, SHADER_UNIFORM_INT);
    SetShaderValue(u.shader, u.locMouse, ms, SHADER_UNIFORM_VEC4);
}

static int render_ppm(int res, const char *out) {
    SetConfigFlags(FLAG_WINDOW_HIDDEN);
    InitWindow(res, res, "c-raylib");
    RenderTexture2D target = LoadRenderTexture(res, res);
    Uniforms u = load_uniforms();
    set_uniforms(u, (float)res, (float)res, 0.0f, 0.0f, 0, (Vector4){0, 0, 0, 0});

    BeginTextureMode(target);
    ClearBackground(BLACK);
    BeginShaderMode(u.shader);
    DrawRectangle(0, 0, res, res, WHITE);
    EndShaderMode();
    EndTextureMode();

    Image img = LoadImageFromTexture(target.texture);
    ImageFormat(&img, PIXELFORMAT_UNCOMPRESSED_R8G8B8);
    unsigned char *p = img.data;

    FILE *f = fopen(out, "wb");
    if (!f) return 1;
    fprintf(f, "P6\n%d %d\n255\n", res, res);
    // RenderTexture rows are bottom-first; PPM is top-first.
    for (int row = 0; row < res; row++) {
        const unsigned char *src = p + (size_t)(res - 1 - row) * res * 3;
        fwrite(src, 1, (size_t)res * 3, f);
    }
    fclose(f);

    UnloadImage(img);
    UnloadRenderTexture(target);
    UnloadShader(u.shader);
    CloseWindow();
    fprintf(stderr, "wrote %s\n", out);
    return 0;
}

static void run_window(void) {
    int w = 512, h = 512;
    InitWindow(w, h, "c-raylib");
    SetTargetFPS(60);
    Uniforms u = load_uniforms();
    int frame = 0;

    while (!WindowShouldClose()) {
        w = GetScreenWidth();
        h = GetScreenHeight();
        Vector2 mp = GetMousePosition();
        float my = (float)h - mp.y;
        float down = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? 1.0f : 0.0f;
        Vector4 mouse = {mp.x, my, mp.x * down, my * down};
        set_uniforms(u, (float)w, (float)h, (float)GetTime(), GetFrameTime(), frame++, mouse);

        BeginDrawing();
        ClearBackground(BLACK);
        BeginShaderMode(u.shader);
        DrawRectangle(0, 0, w, h, WHITE);
        EndShaderMode();
        EndDrawing();
    }
    UnloadShader(u.shader);
    CloseWindow();
}

int main(int argc, char **argv) {
    if (argc >= 4 && strcmp(argv[1], "render") == 0) {
        return render_ppm(atoi(argv[2]), argv[3]);
    }
    run_window();
    return 0;
}
