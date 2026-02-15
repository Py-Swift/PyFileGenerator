//
//  Swift2Py.swift
//  PyFileGenerator
//
import PySwiftAST
import PySwiftCodeGen
import SwiftSyntax
import SwiftParser

public func generatePythonStub(from swiftCode: String) -> String {
    do {
        // Parse Swift code using SwiftSyntax (like PyFileGenerator)
        let sourceFile = Parser.parse(source: swiftCode)
        
        // Build Python AST from Swift AST
        let pythonAST = try buildPythonAST(from: sourceFile)
        
        // Generate Python code from AST
        let pythonCode = generatePythonCode(from: pythonAST)
        
        return pythonCode
        
    } catch {
        return """
# Error parsing Swift code
# \(error)

# Please check your Swift syntax and PySwiftKit decorators
"""
    }
    
}

fileprivate func buildPythonAST(from sourceFile: SourceFileSyntax) throws -> Module {
    var statements: [Statement] = [.blank(2)]
    
    // Extract all @PyClass decorated classes
    for statement in sourceFile.statements {
        swiftStatement2pyStatement(statement)
        guard
            let decl = statement.item.as(DeclSyntax.self),
            let classDecl = decl.as(ClassDeclSyntax.self),
            classDecl.isPyClass
        else {
            continue
        }
        //let classStmt = try buildClassDef(from: classDecl)
        //statements.append(.classDef(.from(classDecl)))
        
    }
    
    return .module(statements)
}

fileprivate func swiftStatement2pyStatement(_ blockItem: CodeBlockItemSyntax) -> Statement? {
    switch blockItem.item {
        case .decl(let declSyntax):
            switch declSyntax.as(DeclSyntaxEnum.self) {
                case .classDecl(let classDeclSyntax):
                    return nil
                case .extensionDecl(let extensionDeclSyntax):
                    return nil
                case .functionDecl(let functionDeclSyntax):
                    return nil
                case .protocolDecl(let protocolDeclSyntax):
                    return nil
                case .structDecl(let structDeclSyntax):
                    return nil
                case .variableDecl(let variableDeclSyntax):
                    return nil
                default: return nil
            }
        case .stmt(let stmtSyntax):
            return nil
        case .expr(let exprSyntax):
            return nil
    }
    fatalError()
}

enum PyTypes: String {
    case String, Substring
    case Int, Int64, Int32, Int16, Int8
    case UInt, UInt64, UInt32, UInt16, UInt8
    case Double, Float, Float32, Float16, CGFloat
    case Bool
    case Data
    case Date, DateComponents
    case URL
    case Void
    case _Void = "()"
    case PyPointer
    
    var pyType: String {
        switch self {
            case .String, .Substring: "str"
            case .Int, .Int64, .Int32, .Int16, .Int8: "int"
            case .UInt, .UInt64, .UInt32, .UInt16, .UInt8: "int"
            case .Double, .Float, .Float32, .Float16, .CGFloat: "float"
            case .Bool: "bool"
            case .Data: "bytes"
            case .Date, .DateComponents: "datetime.datetime"
            case .URL: "str"
            case .Void, ._Void: "None"
            case .PyPointer: "object"
        }
    }
    
    var nameExpr: Expression {
        .name(Name(
            id: pyType,
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
    
}

extension String {
    var constant: Expression {
        .constant(
            .init(
                value: .string(self),
                kind: nil,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )
        )
    }
}

func swiftTypeToExpression(_ type: TypeSyntax) -> Expression {
    
    switch type.as(TypeSyntaxEnum.self) {
        case .arrayType(let arrayTypeSyntax):
            return swiftArrayToExpression(arrayTypeSyntax)
        case .attributedType(let attributedTypeSyntax):
            break
        case .classRestrictionType(let classRestrictionTypeSyntax):
            break
        case .compositionType(let compositionTypeSyntax):
            break
        case .dictionaryType(let dictionaryTypeSyntax):
            return swiftDictToExpression(dictionaryTypeSyntax)
        case .functionType(let functionTypeSyntax):
            break
        case .identifierType(let identifierTypeSyntax):
            return swiftIdentifierToExpression(identifierTypeSyntax)
        case .implicitlyUnwrappedOptionalType(let implicitlyUnwrappedOptionalTypeSyntax):
            break
        case .memberType(let memberTypeSyntax):
            break
        case .metatypeType(let metatypeTypeSyntax):
            break
        case .missingType(let missingTypeSyntax):
            break
        case .namedOpaqueReturnType(let namedOpaqueReturnTypeSyntax):
            break
        case .optionalType(let optionalTypeSyntax):
            return swiftOptionalToExpression(optionalTypeSyntax)
        case .packElementType(let packElementTypeSyntax):
            break
        case .packExpansionType(let packExpansionTypeSyntax):
            break
        case .someOrAnyType(let someOrAnyTypeSyntax):
            break
        case .suppressedType(let suppressedTypeSyntax):
            break
        case .tupleType(let tupleTypeSyntax):
            break
    }
    
    // Default to "object"
    return .name(Name(
        id: "object",
        ctx: .load,
        lineno: 0,
        colOffset: 0,
        endLineno: nil,
        endColOffset: nil
    ))
}

func swiftTypeToExpression(_ annotation: TypeAnnotationSyntax) -> Expression {
    swiftTypeToExpression(annotation.type)
}


fileprivate func swiftOptionalToExpression(_ type: OptionalTypeSyntax) -> Expression {
    return .subscriptExpr(Subscript(
        value: .name(Name(
            id: "Optional",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )),
        slice: swiftTypeToExpression(type.wrappedType),
        ctx: .load,
        lineno: 0,
        colOffset: 0,
        endLineno: nil,
        endColOffset: nil
    ))
}

fileprivate func swiftIdentifierToExpression(_ type: IdentifierTypeSyntax) -> Expression {
    let typeName = type.name.text
    
    if let pythonType = PyTypes(rawValue: typeName)?.nameExpr {
        return pythonType
    }
    let typeTrimmed = type.trimmedDescription
    
    if let castType = PySerializableFactory.castType(typeTrimmed) {
        //return .constant(.init(value: .string(castType), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))
        return .name(.init(stringLiteral: castType))
    }
    
    if typeName == "Set", let genericArgs = type.genericArgumentClause?.arguments  {
        
        let elts = genericArgs.map { genericArg in
            switch genericArg.argument {
                case .type(let gType):
                    return swiftTypeToExpression(gType)
                default:
                    return .name("object")
            }
        }
        if let first = elts.first {
            return .subscriptExpr(.set(type: first))
        }
    }
    
    return typeName.constant
}

fileprivate func swiftArrayToExpression(_ type: ArrayTypeSyntax) -> Expression {
    let elementType = swiftTypeToExpression(type.element)
    
    // Create list[element_type] subscript expression
    return .subscriptExpr(Subscript(
        value: .name(Name(
            id: "list",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )),
        slice: elementType,
        ctx: .load,
        lineno: 0,
        colOffset: 0,
        endLineno: nil,
        endColOffset: nil
    ))
}

fileprivate func swiftDictToExpression(_ type: DictionaryTypeSyntax) -> Expression {
    let keyType = swiftTypeToExpression(type.key)
    let valueType = swiftTypeToExpression(type.value)
    
    // Create dict[key_type, value_type] subscript expression
    let tupleElts = [keyType, valueType]
    return .subscriptExpr(Subscript(
        value: .name(Name(
            id: "dict",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )),
        slice: .tuple(Tuple(
            elts: tupleElts,
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )),
        ctx: .load,
        lineno: 0,
        colOffset: 0,
        endLineno: nil,
        endColOffset: nil
    ))
}


fileprivate func swiftTupleToExpression(_ type: TupleTypeSyntax) -> Expression {
    let elements = type.elements
    
    switch elements.count {
        case 1:
            return swiftTypeToExpression(elements.first!.type)
        default:
            let elementTypes = elements.map { element in
                swiftTypeToExpression(element.type)
            }
            return .subscriptExpr(.tuple(elts: elementTypes))
    }
}

fileprivate func functionTypeToExpression(_ type: FunctionTypeSyntax) -> Expression {
    let args = type.parameters.map { element in
        swiftTypeToExpression(element.type)
    }
    let rtns = swiftTypeToExpression(type.returnClause.type)
    return .subscriptExpr(
        .callable(
            args: args,
            returns: rtns
        )
    )
}


