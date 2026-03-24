import PackagePlugin
import Foundation

nonisolated(unsafe) let pyi_fm = FileManager.default

/// Generates `.pyi` type stub files for each Swift product in the package.
///
/// Invoked by pyswiftkit-builder automatically after `swift build` if this
/// plugin is present in the consumer's dependency graph.
///
/// Usage (manual):
///   swift package plugin --allow-writing-to-package-directory PyiFileGenerator [<output-base-dir>]
///
/// If <output-base-dir> is omitted it defaults to the package's `src/` directory.
/// The plugin writes one `.pyi` file per product into:
///   <output-base-dir>/<product-name>/<module-name>.pyi
@main
struct PyiFileGenerator: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let baseDir: URL
        if let first = arguments.first, first != "--target" {
            baseDir = URL(filePath: first)
        } else {
            baseDir = context.package.directoryURL.appending(path: "src")
        }

        let tool = try context.tool(named: "Generator").url

        for product in context.package.products {
            for source in product.sourceModules {
                let swiftFiles = source.sourceFiles.compactMap { file in
                    file.type == .source ? file.url.path() : nil
                }
                guard !swiftFiles.isEmpty else { continue }

                // Write .pyi flat into baseDir alongside the .so — no per-product subdir.
                let productDir = baseDir
                if !pyi_fm.fileExists(atPath: productDir.path()) {
                    try pyi_fm.createDirectory(at: productDir, withIntermediateDirectories: true)
                }

                print("PyiFileGenerator: \(product.name) → \(productDir.path())")
                try await Process.generatePyi(
                    tool: tool,
                    files: swiftFiles,
                    output: productDir.path()
                )
            }
        }
    }
}

// #if canImport(XcodeProjectPlugin)
// import XcodeProjectPlugin

// extension PyiFileGenerator: XcodeCommandPlugin {
//     func performCommand(context: XcodePluginContext, arguments: [String]) throws {
//         print("PyiFileGenerator: Xcode support not yet implemented")
//     }
// }
// #endif

extension Process {
    /// Invoke `Generator files --pyi --notoml --output <output>` for the given Swift source files.
    static func generatePyi(tool: URL, files: [String], output: String) async throws {
        let proc = Process()
        proc.executableURL = tool
        proc.arguments = ["files"] + files + ["--output", output, "--notoml", "--pyi"]
        print("PyiFileGenerator: Generator", proc.arguments ?? [])
        try proc.run()
        proc.waitUntilExit()
    }
}
