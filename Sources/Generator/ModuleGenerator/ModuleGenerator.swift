//
//  main.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 27/05/2025.
//

import ArgumentParser
import PathKit
import SwiftSyntax
import SwiftParser

extension Path: ArgumentParser.ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}

@main
struct ModuleGenerator: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration = .init(subcommands: [
        Files.self,
        SetupPy.self
    ])
    
}





import Foundation


func toml_file(name: String, setup_py: Bool = false) -> String {
    
    let extra = if setup_py {
        """
        
        [build-system]
        requires = [
            "setuptools>=61",
            "sh"
        ]
        build-backend = "setuptools.build_meta"
        """
    } else { "" }
    
    return """
    [project]
    name = "\(name)"
    version = "0.1.0"
    description = "Add your description here"
      
    requires-python = ">=3.11"
    dependencies = []
    \(extra)
    """
}

func setup_py_file() -> String {
    return """
    from setuptools import setup, Extension
    from setuptools.command.build_ext import build_ext
    import subprocess

    class SPWExtension(Extension):
        def __init__(self):
            #super().__init__("", [os.fspath(Path("").resolve())])
            super().__init__("spw", ["./"])

    class BuildSwiftPackage(build_ext):
        
        def build_extension(self, ext: SPWExtension):
            print("Generating Pip Files:", ext.sources)
            cwd = self.build_lib
            subprocess.run([
                "swift", "package", "plugin",
                "--allow-writing-to-package-directory",# cwd,
                "PyFileGenerator", cwd
                
            ])

    setup(
        ext_modules=[SPWExtension()],
        cmdclass={
            "build_ext": BuildSwiftPackage,
        }
    )

    """.replacingOccurrences(of: "    ", with: "\t")
}


extension String {
    public func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?.lowercased() ?? self.lowercased()
    }
    
    fileprivate func processCamalCaseRegex(pattern: String) -> String? {
        //let regex = try? Regex(pattern)
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

extension PathKit.Path {
    var fileSyntax: SourceFileSyntax? {
        guard exists, self.extension == "swift" else { return nil }
        return Parser.parse(source: try! read())
    }
}



extension SwiftSyntax.SourceFileSyntax {
    func py_module() -> Generator.Module {
        .init(syntax: self)
    }
    
}

public extension Array where Element == PathKit.Path {
    
    func statements() -> [CodeBlockItemSyntax.Item] {
        lazy.compactMap(\.fileSyntax).compactMap({ file -> [CodeBlockItemSyntax.Item] in
            file.statements.map(\.item)
        }).flatMap(\.self)
    }
    
    func declSyntax() -> [DeclSyntax] {
        statements().compactMap { member in
            switch member {
            case .decl(let declSyntax):
                switch declSyntax.as(DeclSyntaxEnum.self) {
                case .classDecl(let classDecl):
                    if classDecl.attributes.contains(where: {["@PyClass"].contains($0.trimmedDescription)})
                    {
                        return .init(classDecl)
                    }
                case .structDecl(let structDecl):
                    if structDecl.attributes.contains(where: {$0.trimmedDescription == "@PyModule"})
                    {
                        return .init(structDecl)
                    }
                case .extensionDecl(let extensionDecl):
                    if extensionDecl.attributes.contains(where: {$0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "PyClassByExtension"})
                    {
                        return .init(extensionDecl)
                    }
                default: break
                }
            case .stmt(let stmtSyntax):
                break
            case .expr(let exprSyntax):
                break
            }
            return nil
        }
    }
    func py_modules() throws -> [(String, String)] {
        
        let statements = statements()
        
        let module_structs = statements.compactMap { item in
            switch item.kind {
            case .structDecl:
                if
                    let structDecl = item.as(StructDeclSyntax.self),
                    structDecl.attributes.contains(where: {$0.trimmedDescription == "@PyModule"})
                {
                    return structDecl
                }
                return nil
            default: return nil
            }
        }
        
        let pyclassDecls = statements.compactMap { item in
            switch item.kind {
            case .classDecl:
                if
                    let classDecl = item.as(ClassDeclSyntax.self),
                    classDecl.attributes.contains(where: {["@PyClass", "@PyClassByExtension"].contains($0.trimmedDescription)})
                {
                    return classDecl
                }
                return nil
            default: return nil
            }
        }
        
        return try lazy.compactMap(\.fileSyntax).compactMap { file -> (String, String)? in
            let is_pymodule = file.statements.contains { blockitem in
                let item = blockitem.item
                switch item.kind {
                case .structDecl:
                    return item.cast(StructDeclSyntax.self).attributes.contains(where: {$0.trimmedDescription == "@PyModule"})
                default: return false
                }
            }
            if is_pymodule {
                let ast = file.py_module()
                let py_code = ast.description
                //let py_code = try Decompiler().decompile(ast: ast).replacingOccurrences(of: ", /)", with: ")")
                return ("ast.name", "py_code")
            }
            
            return nil
        }
    }
}
