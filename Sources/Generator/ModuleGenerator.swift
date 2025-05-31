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
    
    @Argument var files: [Path]
    @Option var output: Path?
    
    func run() async throws {
        guard let output else { return }
        
        let decls = files.declSyntax()
        
        let py_classes = decls.compactMap { decl in
            switch decl.as(DeclSyntaxEnum.self) {
            case .classDecl(let classDecl):
                classDecl
            default: nil
            }
        }
        
        let py_classes_ext = decls.compactMap { decl in
            switch decl.as(DeclSyntaxEnum.self) {
            case .extensionDecl(let extensionDecl):
                extensionDecl
            default: nil
            }
        }
        
        let py_modules = decls.compactMap { decl in
            switch decl.as(DeclSyntaxEnum.self) {
            case .structDecl(let structDecl):
                structDecl
            default: nil
            }
        }
        
        
        
        
        for py_module in py_modules {
            var included_classes: [ClassDeclSyntax] = []
            var included_classes_ext: [ExtensionDeclSyntax] = []
            for member in py_module.memberBlock.members {
                switch member.decl.as(DeclSyntaxEnum.self) {
                case .variableDecl(let variableDecl):
                    if let binding = variableDecl.bindings.first {
                        switch binding.initializer?.value.as(ExprSyntaxEnum.self) {
                        case .arrayExpr(let arrayExpr):
                            switch binding.pattern.as(PatternSyntaxEnum.self) {
                            case .expressionPattern(let expressionPattern):
                                break
                            case .identifierPattern(let identifierPattern):
                                if identifierPattern.identifier.trimmed.text == "py_classes" {
                                    let classes = arrayExpr.elements.compactMap { element in
                                       switch element.expression.as(ExprSyntaxEnum.self) {
                                       case .memberAccessExpr(let memberAccessExpr):
                                           switch memberAccessExpr.base?.as(ExprSyntaxEnum.self) {
                                           case .declReferenceExpr(let declReferenceExpr):
                                               return py_classes.first { cls in
                                                   cls.name.trimmedDescription == declReferenceExpr.baseName.text
                                               }
                                           default: return nil
                                           }
                                       default: return nil
                                        }
                                    }
                                    included_classes.append(contentsOf: classes)
                                    let classes_ext = arrayExpr.elements.compactMap { element in
                                        switch element.expression.as(ExprSyntaxEnum.self) {
                                        case .memberAccessExpr(let memberAccessExpr):
                                            switch memberAccessExpr.base?.as(ExprSyntaxEnum.self) {
                                            case .declReferenceExpr(let declReferenceExpr):
                                                return py_classes_ext.first { cls in
                                                    cls.extendedType.trimmedDescription == declReferenceExpr.baseName.text
                                                }
                                            default: return nil
                                            }
                                        default: return nil
                                         }
                                     }
                                    included_classes_ext.append(contentsOf: classes_ext)
                                }
                            default: break
                            }
                        default: break
                        }
                    }
                
                default: break
                }
            }
            let module = Generator.Module(
                syntax: py_module,
                classes: included_classes.filter(\.isPyClass),
                classes_ext: included_classes_ext.filter(\.isPyClassExt)
            )
            let py_code = module.description.replacingOccurrences(of: "    ", with: "\t")
//            let py_code = try Decompiler().decompile(ast: ast_module)
            let module_name = py_module.name.text.camelCaseToSnakeCase()
            let dest = (output + "\(module_name).py")
//            print("PyAstParser:",dest)
            try dest.write(py_code, encoding: .utf8)
            let toml = output + "../pyproject.toml"
            try toml.write(toml_file(name: module_name), encoding: .utf8)
        }
    }
    
}



import Foundation


func toml_file(name: String) -> String {
    """
    [project]
    name = "\(name)"
    version = "0.1.0"
    description = "Add your description here"
      
    requires-python = ">=3.11"
    dependencies = []
    """
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
