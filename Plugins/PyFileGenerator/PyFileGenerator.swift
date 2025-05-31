import PackagePlugin
import Foundation



let fm = FileManager.default
@main
struct PyFileGenerator: CommandPlugin {
    // Entry point for command plugins applied to Swift Packages.
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let firstArgument = arguments.first
        let targetDir = if let firstArgument {
            URL(filePath: firstArgument)
        } else {
            URL(filePath: context.package.directory.string)
        }
        
        let src = targetDir.appending(path: "src")
        if !fm.fileExists(atPath: src.path()) {
            try fm.createDirectory(at: src, withIntermediateDirectories: true)
        }
        print("PyFileGenerator:", src)
        for product in context.package.products {
            for source in product.sourceModules {
                
                let swiftFiles = source.sourceFiles.compactMap { file in
                    file.type == .source ? file.path.string : nil
                }
                
                
                try await Process.GenerateModule(
                    tool: .init(filePath: try context.tool(named: "Generator").path.string),
                    files: swiftFiles,
                    output: src.path(),
                    notoml: firstArgument != nil
                )
//                    try! Process.run(.init(filePath: "/Users/codebuilder/.swiftpm/bin/PyAstParser"), arguments: [
//                        file.path.string,
//                        src.path()
//                    ]).waitUntilExit()
                
            }
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension PyFileGenerator: XcodeCommandPlugin {
    // Entry point for command plugins applied to Xcode projects.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        print("Hello, World!")
    }
}

#endif


extension Process {
    static func GenerateModule(tool: URL, files: [String], output: String, notoml: Bool) async throws {
        let proc = Process()
        proc.executableURL = tool
        
        var arguments: [String] = ["files"]
        arguments.append(contentsOf:
            files + [
                "--output",
                output
            ]
        )
        if notoml {
            arguments.append("--notoml")
        }
        proc.arguments = arguments
        print("running GenerateModule", files)
        try proc.run()
        proc.waitUntilExit()
        print("finished GenerateModule", files)
    }
}
