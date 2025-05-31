import PackagePlugin
import Foundation



let fm = FileManager.default
@main
struct PyFileGenerator: CommandPlugin {
    // Entry point for command plugins applied to Swift Packages.
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        
        let packageDir = URL(filePath: context.package.directory.string)
        let src = packageDir.appending(path: "src")
        if !fm.fileExists(atPath: src.path()) {
            try fm.createDirectory(at: src, withIntermediateDirectories: true)
        }
        print( packageDir.appending(component: "Sources", directoryHint: .isDirectory).path() )
        for product in context.package.products {
            for source in product.sourceModules {
                
                let swiftFiles = source.sourceFiles.compactMap { file in
                    file.type == .source ? file.path.string : nil
                }
                
                
                try await Process.GenerateModule(
                    tool: .init(filePath: try context.tool(named: "Generator").path.string),
                    files: swiftFiles,
                    output: src.path()
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
    static func PyAstParser(files: [String], output: String) async throws {
        let proc = Process()
        proc.executableURL = .init(filePath: "/Users/codebuilder/Library/Developer/Xcode/DerivedData/PyAstParser-ajnoqfuupnzmcuaamqbohnyspfsz/Build/Products/Debug/PyAstParser")
        
        proc.arguments = files + [
            "--output",
            output
        ]
        print("running PyAstParser", files)
        try proc.run()
        proc.waitUntilExit()
        print("finished PyAstParser", files)
    }
    
    static func GenerateModule(tool: URL, files: [String], output: String) async throws {
        let proc = Process()
        proc.executableURL = tool
        
        proc.arguments = files + [
            "--output",
            output
        ]
        print("running PyAstParser", files)
        try proc.run()
        proc.waitUntilExit()
        print("finished PyAstParser", files)
    }
}
