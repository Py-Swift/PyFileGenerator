//
//  Files.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 02/06/2025.
//
import ArgumentParser
import PathKit
import SwiftSyntax
import SwiftParser

extension ModuleGenerator {
    struct Files: AsyncParsableCommand {
        @Argument var files: [Path]
        @Option var output: Path?
        @Flag(wrappedValue: false) var notoml: Bool
        
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
                if !notoml {
                    let toml_path = output + "../pyproject.toml"
                    try toml_path.write(toml_file(name: module_name), encoding: .utf8)
                }
            }
        }
        
    }
    
}
