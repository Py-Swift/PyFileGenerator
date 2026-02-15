//
//  PyModule.swift
//  PyFileGenerator
//
import PySwiftAST
import SwiftSyntax
import PySwiftCodeGen
import PyFormatters

extension PySwiftAST.Alias: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(name: value, asName: nil)
    }
}

extension PySwiftAST.Module {
    init(syntax: StructDeclSyntax, classes: [ClassDeclSyntax] = [], classes_ext: [ExtensionDeclSyntax] = []) throws {
        let functions: [PySwiftAST.Statement] = syntax.memberBlock.members.compactMap { member -> Statement? in
            switch member.decl.as(DeclSyntaxEnum.self) {
                case .functionDecl(let funcDecl):
                    guard funcDecl.isPyFunction else { return nil }
                    return .functionDef(.from(funcDecl))
                default: return nil
            }
        }
        let _classes: [Statement] = try classes.map { clsDecl in
            return .classDef(try .from(clsDecl))
        }
        let _classes_ext: [Statement] = try classes_ext.compactMap { ext -> Statement? in
            guard
                let expr =  ext.attributes.first(where: \.isPyClassExt),
                let attr = expr.as(AttributeSyntax.self)
            else { return nil }
            
            let py_ext = try! PyClassByExtensionUnpack(arguments: attr.arguments!.cast(LabeledExprListSyntax.self))
            //let py_ext_name = ext.extendedType.trimmedDescription
            //var body = [Statement]()
            //body.append(contentsOf: py_ext.functions.map({.functionDef(.from($0, cls: py_ext_name))}))
            //body.append(contentsOf: py_ext.properties.compactMap(prop))
            return .classDef(
                try .from(ext, ext_data: py_ext)
            )
            
            //var py_cls = Generator.Class(syntax: ext, indent: 0)
            //py_cls.body.append(contentsOf: py_ext.properties.compactMap({Generator.AnnAssign(syntax: $0, indent: 1)}))
            //py_cls.body.append(contentsOf: py_ext.functions.map({Generator.Function(syntax: $0, indent: 1, no_self: false)}))
            
            //py_cls.body.append(contentsOf: py_ext.functions.map(AST.FunctionDef.init))
            
            return nil
        }
        var bodyItems = [Statement]()
        bodyItems.append(
            contentsOf: [
                // from typing import Callable, Protocol
                .importFrom(
                    .init(
                        module: "typing",
                        names: ["Callable", "Protocol", "Optional"],
                        level: 0,
                        lineno: 0,
                        colOffset: 0,
                        endLineno: nil,
                        endColOffset: nil
                    )
                ),
                .importStmt(.init(names: ["datetime"], lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
            ]
        )
        bodyItems.append(contentsOf: functions)
        bodyItems.append(contentsOf: _classes)
        bodyItems.append(contentsOf: _classes_ext)
        //body = _classes + _classes_ext + functions
        self = .module(bodyItems)
    }
}

extension PySwiftAST.Module: CustomStringConvertible {
    public var description: String {
        let formatter = BlackFormatter()
        return generatePythonCode(from: formatter.formatDeep(self))
    }
}
