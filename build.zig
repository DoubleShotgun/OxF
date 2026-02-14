const std = @import("std");

pub fn build(b: *std.Build) void {
  
  const exe = b.addExecutable(.{
    .name = "OxF",
    .root_module = b.createModule(.{
      .root_source_file = b.path("OxF.zig"),
      .target = b.standardTargetOptions(.{}),
      .optimize = b.standardOptimizeOption(.{})
    }),
  });

  exe.linkSystemLibrary("c");
  b.installArtifact(exe);

  const run_exe = b.addRunArtifact(exe);

  const run_step = b.step("run", "Run the application");
  run_step.dependOn(&run_exe.step);
}
