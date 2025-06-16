//
//  Generator+Syntax.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 27/05/2025.
//

import SwiftSyntax
import SwiftParser


func identifierTypeAsExpr(_ t: IdentifierTypeSyntax) -> Generator.ExprProtocol {
    switch SwiftTypes(rawValue: t.name.text) {
        
    case .Int, .Int32, .Int16, .Int8, .UInt, .UInt32, .UInt16, .UInt8:
        Generator.TypeAnnotation(name: "int")
    case .Float, .Double:
        Generator.TypeAnnotation(name: "float")
    case .Bool:
        Generator.TypeAnnotation(name: "bool")
    case .String:
        Generator.TypeAnnotation(name: "str")
    case .Data:
        Generator.TypeAnnotation(name: "bytes")
    case .Error:
        Generator.TypeAnnotation(name: "str")
    case .UUID:
        Generator.TypeAnnotation(name: "str")
    case .PyPointer:
        Generator.TypeAnnotation(name: "object")
    case .Void:
        Generator.TypeAnnotation(name: "None")
    case .none:
        Generator.WrappedType(wrapped: t.trimmedDescription)
    }
    
}
    
func typeSyntaxAsExpr(_ t: TypeSyntax) -> Generator.ExprProtocol {
    switch t.as(TypeSyntaxEnum.self) {
    case .arrayType(let arrayTypeSyntax):
        Generator.ListType(syntax: arrayTypeSyntax)
    case .attributedType(let attributedTypeSyntax):
        typeSyntaxAsExpr(attributedTypeSyntax.baseType)
    case .classRestrictionType(let classRestrictionTypeSyntax):
        fatalError()
    case .compositionType(let compositionTypeSyntax):
        fatalError()
    case .dictionaryType(let dictionaryTypeSyntax):
        Generator.DictType(syntax: dictionaryTypeSyntax)
    case .functionType(let functionTypeSyntax):
        Generator.CallableType(syntax: functionTypeSyntax)
    case .identifierType(let identifierTypeSyntax):
        identifierTypeAsExpr(identifierTypeSyntax)
    case .implicitlyUnwrappedOptionalType(let implicitlyUnwrappedOptionalTypeSyntax):
        fatalError()
    case .memberType(let memberTypeSyntax):
        fatalError()
    case .metatypeType(let metatypeTypeSyntax):
        fatalError()
    case .missingType(let missingTypeSyntax):
        fatalError()
    case .namedOpaqueReturnType(let namedOpaqueReturnTypeSyntax):
        fatalError()
    case .optionalType(let optionalTypeSyntax):
        Generator.OptionalType(syntax: optionalTypeSyntax)
    case .packElementType(let packElementTypeSyntax):
        fatalError()
    case .packExpansionType(let packExpansionTypeSyntax):
        fatalError()
    case .someOrAnyType(let someOrAnyTypeSyntax):
        typeSyntaxAsExpr(someOrAnyTypeSyntax.constraint)
    case .suppressedType(let suppressedTypeSyntax):
        fatalError()
    case .tupleType(let tupleTypeSyntax):
        if tupleTypeSyntax.elements.count == 1 {
            typeSyntaxAsExpr(tupleTypeSyntax.elements.first!.type)
        } else {
            Generator.ListExpr(elements: tupleTypeSyntax.elements.map({typeSyntaxAsExpr($0.type)}))
        }
    }
}

func declSyntaxAsStatement(_ decl: DeclSyntax, indent: Int, cls: Bool) -> Generator.Statement? {
    switch decl.as(DeclSyntaxEnum.self) {
    case .accessorDecl(let accessorDeclSyntax):
        fatalError()
    case .actorDecl(let actorDeclSyntax):
        fatalError()
    case .associatedTypeDecl(let associatedTypeDeclSyntax):
        fatalError()
    case .classDecl(let classDeclSyntax):
        if classDeclSyntax.isPyClass {
            Generator.Class(syntax: classDeclSyntax, indent: indent)
        } else { nil }
    case .deinitializerDecl(let deinitializerDeclSyntax):
        nil
    case .editorPlaceholderDecl(let editorPlaceholderDeclSyntax):
        fatalError()
    case .enumCaseDecl(let enumCaseDeclSyntax):
        fatalError()
    case .enumDecl(let enumDeclSyntax):
        fatalError()
    case .extensionDecl(let extensionDeclSyntax):
        fatalError()
    case .functionDecl(let functionDeclSyntax):
        if functionDeclSyntax.isPyFunction || functionDeclSyntax.isPyMethod || functionDeclSyntax.isPyCall {
            Generator.Function(syntax: functionDeclSyntax, indent: indent, no_self: !cls)
        } else { nil }
    case .ifConfigDecl(let ifConfigDeclSyntax):
        fatalError()
    case .importDecl(let importDeclSyntax):
        fatalError()
    case .initializerDecl(let initializerDeclSyntax):
        if initializerDeclSyntax.isPyInit {
            Generator.Function(indent: indent, name: "__init__", arguments: .init(arguments: ["self","*args", "**kwargs"]))
        } else { nil }
    case .macroDecl(let macroDeclSyntax):
        fatalError()
    case .macroExpansionDecl(let macroExpansionDeclSyntax):
        fatalError()
    case .missingDecl(let missingDeclSyntax):
        fatalError()
    case .operatorDecl(let operatorDeclSyntax):
        fatalError()
    case .poundSourceLocation(let poundSourceLocationSyntax):
        fatalError()
    case .precedenceGroupDecl(let precedenceGroupDeclSyntax):
        fatalError()
    case .protocolDecl(let protocolDeclSyntax):
        fatalError()
    case .structDecl(let structDeclSyntax):
        fatalError()
    case .subscriptDecl(let subscriptDeclSyntax):
        fatalError()
    case .typeAliasDecl(let typeAliasDeclSyntax):
        fatalError()
    case .variableDecl(let variableDeclSyntax):
        if variableDeclSyntax.isPyProperty {
            Generator.AnnAssign(syntax: variableDeclSyntax, indent: indent)
        } else { nil }
    }
}

fileprivate class PyClassByExtensionUnpack {
    
    //var unretained = false
    var functions: [FunctionDeclSyntax] = []
    var properties: [VariableDeclSyntax] = []
    //var type: TypeSyntax
    
    init(arguments: LabeledExprListSyntax) throws {
        for argument in arguments {
            guard let label = argument.label else { continue }
            switch argument.label?.text {
            case "expr":
                if let expr = argument.expression.as(StringLiteralExprSyntax.self) {
                    let statements = Parser.parse(source: expr.segments.description).statements
                    let funcDecls = statements.compactMap { blockItem in
                        let item = blockItem.item
                        return switch item.kind {
                        case .functionDecl: item.as(FunctionDeclSyntax.self)
                        default: nil
                        }
                    }
                    functions = funcDecls
                    
                    let varDecls = statements.compactMap { blockItem in
                        let item = blockItem.item
                        return switch item.kind {
                        case .variableDecl: item.as(VariableDeclSyntax.self)
                        default: nil
                        }
                    }
                    properties = varDecls
                }
            
            default: continue
            }
        
        }
        
    }
    
    struct ArgError: Error {
        
    }
}

extension Generator.Module {
    init(syntax: SourceFileSyntax) {
        body = syntax.statements.compactMap({$0.item.as(DeclSyntax.self)}).compactMap({declSyntaxAsStatement($0, indent: 0, cls: false)})
    }
    
    init(syntax: StructDeclSyntax, classes: [ClassDeclSyntax] = [], classes_ext: [ExtensionDeclSyntax] = []) {
        let functions = syntax.memberBlock.members.compactMap { member -> FunctionDeclSyntax? in
            switch member.decl.as(DeclSyntaxEnum.self) {
            case .functionDecl(let funcDecl):
                guard funcDecl.isPyFunction else { return nil }
                return funcDecl
            default: return nil
            }
        }.map({Generator.Function(syntax: $0, indent: 0)})
        let _classes = classes.map({Generator.Class(syntax: $0, indent: 0)})
        let _classes_ext = classes_ext.compactMap { ext -> Generator.Class? in
            guard
                let expr =  ext.attributes.first(where: \.isPyClassExt),
                let attr = expr.as(AttributeSyntax.self)
            else { return nil }
            let py_ext = try! PyClassByExtensionUnpack(arguments: attr.arguments!.cast(LabeledExprListSyntax.self))
            
            var py_cls = Generator.Class(syntax: ext, indent: 0)
            py_cls.body.append(contentsOf: py_ext.properties.compactMap({Generator.AnnAssign(syntax: $0, indent: 1)}))
            py_cls.body.append(contentsOf: py_ext.functions.map({Generator.Function(syntax: $0, indent: 1, no_self: false)}))
            
            //py_cls.body.append(contentsOf: py_ext.functions.map(AST.FunctionDef.init))
            
            return py_cls
        }
        body = _classes + _classes_ext + functions
    }
    
}

extension Generator.Class {
    init(syntax: ClassDeclSyntax, indent: Int) {
        let body_indent = indent + 1
        self.indent = indent
        name = syntax.name.text
        bases = []
        if syntax.isPyClass && syntax.isPyContainer {
            let pycb = Generator.Class(
                indent: body_indent,
                name: "Callbacks",
                bases: ["Protocol"],
                body: syntax.memberBlock.members.compactMap{ declSyntaxAsStatement($0.decl, indent: body_indent, cls: true)}
            )
            let __init__ = Generator.Function(
                indent: body_indent,
                name: "__init__",
                arguments: .init(arguments: ["self", .init(name: "callback", type: Generator.WrappedType(wrapped: "Callbacks"))])
            )
            body = [__init__, pycb]
        } else {
            body = syntax.memberBlock.members.compactMap{ declSyntaxAsStatement($0.decl, indent: body_indent, cls: true)}
        }
    }
    
    init(syntax: ExtensionDeclSyntax, indent: Int) {
        let body_indent = indent + 1
        self.indent = indent
        name = syntax.extendedType.trimmedDescription
        bases = []
        body = syntax.memberBlock.members.compactMap{ declSyntaxAsStatement($0.decl, indent: body_indent, cls: true)}
    }
}


extension Generator.Function {
    init(syntax: FunctionDeclSyntax, indent: Int, no_self: Bool = true) {
        let signature = syntax.signature
        self.indent = indent
        var no_self = no_self
        name = syntax.name.text
        if !no_self {
            decorators = syntax.isStatic ? ["@staticmethod"] : []
            no_self = syntax.isStatic
        }
        arguments = .init(syntax: signature.parameterClause.parameters, no_self: no_self)
        return_type = if let returnClause = signature.returnClause {
            typeSyntaxAsExpr(returnClause.type)
        } else { nil }
    }
}
extension Generator.Function.Arguments {
    init(syntax: FunctionParameterListSyntax, no_self: Bool = true) {
        var args: [Generator.Function.Argument] = []
        if !no_self {
            args.append("self")
        }
        args.append(contentsOf: syntax.map(Generator.Function.Argument.init))
        arguments = args
    }
}
extension Generator.Function.Argument {
    init(syntax: FunctionParameterSyntax) {
        name = (syntax.secondName ?? syntax.firstName).text
        type = typeSyntaxAsExpr(syntax.type)
    }
}

extension Generator.DictType {
    init(syntax: DictionaryTypeSyntax) {
        key = typeSyntaxAsExpr(syntax.key)
        value = typeSyntaxAsExpr(syntax.value)
    }
}

extension Generator.ListType {
    init(syntax: ArrayTypeSyntax) {
        type = typeSyntaxAsExpr(syntax.element)
    }
}

extension Generator.AnnAssign {
    init(syntax: VariableDeclSyntax, indent: Int) {
        let pattern = syntax.bindings.first!
        self.indent = indent
        name = pattern.pattern.trimmedDescription
        typeAnnotation = if let t = pattern.typeAnnotation?.type {
            typeSyntaxAsExpr(t)
        } else {
            Generator.TypeAnnotation(name: "object")
        }
    }
}

extension Generator.OptionalType {
    init(syntax: OptionalTypeSyntax) {
        wrapped = typeSyntaxAsExpr(syntax.wrappedType)
    }
}

extension Generator.CallableType {
    init(syntax: FunctionTypeSyntax) {
        let parameters = syntax.parameters
        if parameters.count >  1 {
            argument = Generator.ListExpr(elements: parameters.map({typeSyntaxAsExpr($0.type)}))
        } else {
            if parameters.isEmpty {
                argument = Generator.ListExpr(elements: [])
            } else {
                argument = typeSyntaxAsExpr(parameters.first!.type)
            }
        }
        return_type = typeSyntaxAsExpr(syntax.returnClause.type)
    }
}
