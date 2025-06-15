import PackagePlugin
import Foundation



@main
struct SetupPyGenerator: CommandPlugin {
    // Entry point for command plugins applied to Swift Packages.
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        
        guard var src = arguments.first else { return }
        
        if src == "--target" {
            src = "./"
        }
        for product in context.package.products {
            for source in product.sourceModules {
                
                let swiftFiles = source.sourceFiles.compactMap { file in
                    file.type == .source ? file.path.string : nil
                }
                
                
                try await Process.GenerateModule(
                    tool: .init(filePath: try context.tool(named: "Generator").path.string),
                    files: swiftFiles,
                    output: src
                )

            }
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SetupPyGenerator: XcodeCommandPlugin {
    // Entry point for command plugins applied to Xcode projects.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        print("Hello, World!")
    }
}

#endif


extension Process {
    static func GenerateModule(tool: URL, files: [String], output: String) async throws {
        let proc = Process()
        proc.executableURL = tool
        
        var arguments: [String] = ["setup-py"]
        arguments.append(contentsOf: files + [
            "--destination",
            output
        ])
        proc.arguments = arguments
        print("SetupPyGenerator PyAstParser", arguments)
        try proc.run()
        proc.waitUntilExit()
        print("finished SetupPyGenerator", files)
    }
}
