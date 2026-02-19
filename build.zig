const std = @import("std");
const builtin = @import("builtin");


pub fn build(b: *std.Build) void {    
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //c libraries
    const cmake_configure = b.addSystemCommand(&.{"cmake",
        "-S", "OpenBLAS",
        "-B", "OpenBLAS/build",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DNOFORTRAN=1",
        "-DCMAKE_C_COMPILER=clang",
        "-DCMAKE_ASM_COMPILER=clang",
        "-DCMAKE_C_FLAGS=-w",        
        "-DCMAKE_ASM_FLAGS=-w"});
    const cmake_build = b.addSystemCommand(&.{"cmake", "--build", "OpenBLAS/build", "--parallel"});
    cmake_build.step.dependOn(&cmake_configure.step);
    const cmake_step = b.option(bool, "cmake", "Run cmake for c dependencies") orelse false;
    

    //main librarie
    const mod = b.addModule("snn_lib", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    mod.addLibraryPath(b.path("OpenBLAS/build/lib"));
    mod.addIncludePath(b.path("OpenBLAS"));
    mod.addIncludePath(b.path("OpenBLAS/build"));
    
    //executable
    const exe = b.addExecutable(.{
        .name = "snn_lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "snn_lib", .module = mod },
            },
        }),
    });

    if(cmake_step) 
        exe.step.dependOn(&cmake_build.step);
    
    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const test_runner: std.Build.Step.Compile.TestRunner = .{
        .path = b.path("src/test_runner.zig"),
        .mode = @enumFromInt(0),
    };
    
    const mod_tests = b.addTest(.{
        .root_module = mod,
        .test_runner = test_runner,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
        .test_runner = test_runner,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
