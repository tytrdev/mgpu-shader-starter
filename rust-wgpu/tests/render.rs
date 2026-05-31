#[test]
fn matches_reference() {
    let res = 256u32;
    let rgb = starter::render_offscreen(res).expect("no gpu adapter");
    starter::write_ppm("frame.ppm", res, &rgb).unwrap();
    let status = std::process::Command::new("python3")
        .args(["../tools/assert_frame.py", "frame.ppm"])
        .status()
        .expect("run assert_frame.py");
    assert!(status.success());
}
