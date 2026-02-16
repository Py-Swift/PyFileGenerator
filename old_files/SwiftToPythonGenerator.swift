////
////  SwiftToPythonGenerator.swift
////  PyFileGenerator
////
////  Created by CodeBuilder on 14/02/2026.
////
//
//
//import PySwiftAST
//import PySwiftCodeGen
//import SwiftSyntax
//import SwiftParser
//
///// Swift to Python code generator using SwiftSyntax and PySwiftAST
//public enum SwiftToPythonGenerator {
//    
//    /// Generate Python stub code from Swift source
//    public static func generatePythonStub(from swiftCode: String) -> String {
//        do {
//            // Parse Swift code using SwiftSyntax (like PyFileGenerator)
//            let sourceFile = Parser.parse(source: swiftCode)
//            
//            // Build Python AST from Swift AST
//            let pythonAST = try buildPythonAST(from: sourceFile)
//            
//            // Generate Python code from AST
//            let pythonCode = generatePythonCode(from: pythonAST)
//            
//            return pythonCode
//            
//        } catch {
//            return """
//# Error parsing Swift code
//# \(error)
//
//# Please check your Swift syntax and PySwiftKit decorators
//"""
//        }
//    }
//    
//    /// Build Python AST from Swift SourceFileSyntax using PySwiftAST
//    private static func buildPythonAST(from sourceFile: SourceFileSyntax) throws -> Module {
//        var statements: [Statement] = []
//        
//        // Extract all @PyClass decorated classes
//        for statement in sourceFile.statements {
//            guard let decl = statement.item.as(DeclSyntax.self),
//                  let classDecl = decl.as(ClassDeclSyntax.self) else {
//                continue
//            }
//            
//            // Check for @PyClass attribute (like PyFileGenerator does)
//            let hasPyClass = classDecl.attributes.contains { attr in
//                attr.trimmedDescription.contains("@PyClass")
//            }
//            
//            if hasPyClass {
//                // Add blank line between classes (if not first)
//                if !statements.isEmpty {
//                    statements.append(.blank(2))
//                }
//                let classStmt = try buildClassDef(from: classDecl)
//                statements.append(classStmt)
//            }
//        }
//        
//        return .module(statements)
//    }
//    
//    /// Build ClassDef from ClassDeclSyntax
//    private static func buildClassDef(from classDecl: ClassDeclSyntax) throws -> Statement {
//        let className = classDecl.name.text
//        var body: [Statement] = []
//        var addedAnyMember = false
//        
//        // Parse class members
//        for member in classDecl.memberBlock.members {
//            let decl = member.decl
//            var memberAdded = false
//            
//            // Handle @PyInit (constructors -> __init__)
//            if let initDecl = decl.as(InitializerDeclSyntax.self) {
//                let hasPyInit = initDecl.attributes.contains { attr in
//                    attr.trimmedDescription.contains("@PyInit")
//                }
//                if hasPyInit {
//                    // Add blank line before this member (if not first)
//                    if addedAnyMember {
//                        body.append(.blank())
//                    }
//                    let initFunc = try buildInitFunction(from: initDecl)
//                    body.append(initFunc)
//                    memberAdded = true
//                }
//            }
//            
//            // Handle @PyMethod (methods)
//            if let funcDecl = decl.as(FunctionDeclSyntax.self), !memberAdded {
//                let hasPyMethod = funcDecl.attributes.contains { attr in
//                    attr.trimmedDescription.contains("@PyMethod")
//                }
//                if hasPyMethod {
//                    // Add blank line before this member (if not first)
//                    if addedAnyMember {
//                        body.append(.blank())
//                    }
//                    let method = try buildMethodFunction(from: funcDecl)
//                    body.append(method)
//                    memberAdded = true
//                }
//            }
//            
//            // Handle @PyProperty (properties)
//            if let varDecl = decl.as(VariableDeclSyntax.self), !memberAdded {
//                let hasPyProperty = varDecl.attributes.contains { attr in
//                    attr.trimmedDescription.contains("@PyProperty")
//                }
//                if hasPyProperty {
//                    // Add blank line before this member (if not first)
//                    if addedAnyMember {
//                        body.append(.blank())
//                    }
//                    let propertyStatements = try buildPropertyStatements(from: varDecl)
//                    body.append(contentsOf: propertyStatements)
//                    memberAdded = true
//                }
//            }
//            
//            if memberAdded {
//                addedAnyMember = true
//            }
//        }
//        
//        // Add default pass if body is empty
//        if body.isEmpty {
//            body.append(.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil)))
//        }
//        
//        return .classDef(ClassDef(
//            name: className,
//            body: body
//        ))
//    }
//    
//    /// Build __init__ FunctionDef from InitializerDeclSyntax
//    private static func buildInitFunction(from initDecl: InitializerDeclSyntax) throws -> Statement {
//        let signature = initDecl.signature
//        var args: [Arg] = []
//        
//        // Add 'self' parameter
//        args.append(._self)
//        
//        // Add parameters
//        for param in signature.parameterClause.parameters {
//            let paramName = (param.secondName ?? param.firstName).text
//            let annotation = swiftTypeToExpression(param.type)
//            
//            args.append(Arg(
//                arg: paramName
//            ))
//        }
//        
//        let arguments = Arguments(
//            args: args
//        )
//        
//        return .functionDef(FunctionDef(
//            name: "__init__",
//            args: arguments
//        ))
//    }
//    
//    /// Build method FunctionDef from FunctionDeclSyntax
//    private static func buildMethodFunction(from funcDecl: FunctionDeclSyntax) throws -> Statement {
//        let methodName = funcDecl.name.text
//        let signature = funcDecl.signature
//        var args: [Arg] = []
//        var decorators: [Expression] = []
//        
//        // Check if static method
//        let isStatic = funcDecl.modifiers.contains { modifier in
//            modifier.name.text == "static"
//        }
//        
//        if isStatic {
//            decorators.append(.name(.staticmethod))
//        } else {
//            // Add 'self' parameter for instance methods
//            args.append(._self)
//        }
//        
//        // Add parameters
//        for param in signature.parameterClause.parameters {
//            let paramName = (param.secondName ?? param.firstName).text
//            let annotation = swiftTypeToExpression(param.type)
//            
//            args.append(Arg(
//                arg: paramName,
//                annotation: annotation
//            ))
//        }
//        
//        let arguments = Arguments(
//            args: args
//        )
//        
//        // Parse return type
//        let returnType = signature.returnClause.map { returnClause in
//            swiftTypeToExpression(returnClause.type)
//        }
//        
//        return .functionDef(FunctionDef(
//            name: methodName,
//            args: arguments,
//            decoratorList: decorators,
//            returns: returnType
//        ))
//    }
//    
//    /// Build property FunctionDef(s) from VariableDeclSyntax
//    /// Handles getter-only and getter+setter detection like PyFileGenerator
//    /// Returns array of statements (getter, and optionally setter with blank line)
//    private static func buildPropertyStatements(from varDecl: VariableDeclSyntax) throws -> [Statement] {
//        guard let binding = varDecl.bindings.first,
//              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
//            throw ParserError.invalidProperty
//        }
//        
//        let propertyName = pattern.identifier.text
//        let annotation = binding.typeAnnotation.map { typeAnnotation in
//            swiftTypeToExpression(typeAnnotation.type)
//        }
//        
//        // Determine if property is getter-only or getter+setter
//        let propertyType = detectPropertyType(binding: binding, varDecl: varDecl)
//        
//        var statements: [Statement] = []
//        
//        // Always create getter
//        statements.append(.functionDef(FunctionDef(
//            name: propertyName,
//            args: .init(args: [._self]),
//            decoratorList: [.name(.property)],
//            returns: annotation
//        )))
//        
//        // Add setter if property is not getter-only
//        if propertyType == .getterAndSetter {
//            statements.append(.blank())
//            
//            let setterArgs = Arguments(
//                args: [
//                    ._self,
//                    Arg(arg: "value", annotation: annotation)
//                ]
//            )
//            
//            // Create @propertyName.setter decorator
//            let setterDecorator: Expression = .attribute(Attribute(
//                value: .name(Name(
//                    id: propertyName
//                )),
//                attr: "setter",
//                ctx: .load
//            ))
//            
//            statements.append(.functionDef(FunctionDef(
//                name: propertyName,
//                args: setterArgs,
//                decoratorList: [setterDecorator],
//                returns: nil
//            )))
//        }
//        
//        return statements
//    }
//    
//    /// Detect if property is getter-only or getter+setter
//    /// Based on PyFileGenerator logic
//    private static func detectPropertyType(binding: PatternBindingSyntax, varDecl: VariableDeclSyntax) -> PropertyType {
//        // 1. Check for 'if let' binding → getter only
//        if let _ = binding.pattern.as(OptionalBindingConditionSyntax.self) {
//            return .getterOnly
//        }
//        
//        // 2. Check if it's 'let' declaration → getter only
//        if varDecl.bindingSpecifier.tokenKind == .keyword(.let) {
//            return .getterOnly
//        }
//        
//        // 3. Check for computed property with accessors
//        if let accessorBlock = binding.accessorBlock {
//            switch accessorBlock.accessors {
//            case .accessors(let accessors):
//                // Check if there's a setter accessor
//                let hasSetter = accessors.contains { accessor in
//                    accessor.accessorSpecifier.tokenKind == .keyword(.set)
//                }
//                return hasSetter ? .getterAndSetter : .getterOnly
//                
//            case .getter:
//                // Getter-only computed property
//                return .getterOnly
//            }
//        }
//        
//        // 4. Regular 'var' without explicit accessors → getter + setter
//        if varDecl.bindingSpecifier.tokenKind == .keyword(.var) {
//            return .getterAndSetter
//        }
//        
//        // Default to getter-only for safety
//        return .getterOnly
//    }
//    
//    enum PropertyType {
//        case getterOnly
//        case getterAndSetter
//    }
//    
//    /// Convert Swift TypeSyntax to Python Expression
//    /// Based on PySwiftKit TYPE_CONVERSIONS.md comprehensive reference
//    private static func swiftTypeToExpression(_ type: TypeSyntax) -> Expression {
//        // Handle identifier types (String, Int, etc.)
//        if let identType = type.as(IdentifierTypeSyntax.self) {
//            let typeName = identType.name.text
//            
//            
//            // Handle Optional<Type> generic syntax (treat same as Type?)
//            if typeName == "Optional", let genericArgs = identType.genericArgumentClause {
//                if genericArgs.arguments.count == 1,
//                   case let .type(wrappedType) = genericArgs.arguments.first!.argument {
//                    // Return wrapped_type | None
//                    return buildOptionalExpression(swiftTypeToExpression(wrappedType))
//                }
//            }
//            
//            // Handle generic arguments (Array<Element>, Set<Element>, Dictionary<Key, Value>)
//            if let genericArgs = identType.genericArgumentClause {
//                return buildGenericTypeExpression(typeName, genericArgs: genericArgs.arguments)
//            }
//            
//            let pythonType = swiftTypeToPython(typeName)
//            
//            return .name(Name(
//                id: pythonType
//            ))
//        }
//        
//        // Handle optional types (String? -> str | None)
//        if let optType = type.as(OptionalTypeSyntax.self) {
//            let wrapped = swiftTypeToExpression(optType.wrappedType)
//            return buildOptionalExpression(wrapped)
//        }
//        
//        // Handle array types ([String] -> list[str])
//        if let arrayType = type.as(ArrayTypeSyntax.self) {
//            let elementType = swiftTypeToExpression(arrayType.element)
//            
//            // Create list[element_type] subscript expression
//            return .subscriptExpr(Subscript(
//                value: .name(.list),
//                slice: elementType
//            ))
//        }
//        
//        // Handle dictionary types ([String: Int] -> dict[str, int])
//        if let dictType = type.as(DictionaryTypeSyntax.self) {
//            let keyType = swiftTypeToExpression(dictType.key)
//            let valueType = swiftTypeToExpression(dictType.value)
//            
//            // Create dict[key_type, value_type] subscript expression
//            let tupleElts = [keyType, valueType]
//            return .subscriptExpr(Subscript(
//                value: .name(.dict),
//                slice: .tuple(Tuple(
//                    elts: tupleElts
//                ))
//            ))
//        }
//        
//        // Handle tuple types ((Int, String) -> tuple[int, str])
//        if let tupleType = type.as(TupleTypeSyntax.self) {
//            let elementTypes = tupleType.elements.map { element in
//                swiftTypeToExpression(element.type)
//            }
//            
//            return .subscriptExpr(Subscript(
//                value: .name(.tuple),
//                slice: .tuple(Tuple(
//                    elts: elementTypes,
//                    ctx: .load,
//                    lineno: 0,
//                    colOffset: 0,
//                    endLineno: nil,
//                    endColOffset: nil
//                ))
//            ))
//        }
//        
//        // Default to "object"
//        return .name(.object)
//    }
//    
//    /// Build optional type expression (Type -> Optional[Type])
//    /// Using typing.Optional for cleaner output without parentheses
//    private static func buildOptionalExpression(_ wrappedType: Expression) -> Expression {
//        // Use Optional[Type] from typing module for clean output
//        return .subscriptExpr(Subscript(
//            value: .name("Optional"),
//            slice: wrappedType
//        ))
//    }
//    
//    /// Build generic type expression (Array<T> -> list[T], Set<T> -> set[T], Dictionary<K,V> -> dict[K,V])
//    private static func buildGenericTypeExpression(_ typeName: String, genericArgs: GenericArgumentListSyntax) -> Expression {
//        let pythonBaseType = swiftTypeToPython(typeName)
//        
//        // Convert generic arguments to Python type expressions
//        let argExpressions = genericArgs.map { arg in
//            // arg.argument is GenericArgumentSyntax.Argument which is TypeSyntax
//            if case let .type(typeSyntax) = arg.argument {
//                return swiftTypeToExpression(typeSyntax)
//            }
//            // Fallback to object
//            return .name(.object)
//        }
//        
//        // Single generic argument (Array, Set)
//        if argExpressions.count == 1 {
//            return .subscriptExpr(Subscript(
//                value: .name(Name(
//                    id: pythonBaseType
//                )),
//                slice: argExpressions[0]
//            ))
//        }
//        
//        // Multiple generic arguments (Dictionary<K, V>)
//        if argExpressions.count > 1 {
//            return .subscriptExpr(Subscript(
//                value: .name(Name(id: pythonBaseType)),
//                slice: .tuple(Tuple(
//                    elts: argExpressions
//                ))
//            ))
//        }
//        
//        // Fallback: just return the base type
//        return .name(Name(id: pythonBaseType))
//    }
//    
//    /// Map Swift type names to Python type names
//    /// Based on PySwiftKit TYPE_CONVERSIONS.md comprehensive reference
//    private static func swiftTypeToPython(_ swiftType: String) -> String {
//        switch swiftType {
//        // String types → str
//        case "String", "Substring":
//            return "str"
//        
//        // Signed integers → int
//        case "Int", "Int64", "Int32", "Int16", "Int8":
//            return "int"
//        
//        // Unsigned integers → int
//        case "UInt", "UInt64", "UInt32", "UInt16", "UInt8":
//            return "int"
//        
//        // Floating point → float
//        case "Double", "Float", "Float32", "Float16", "CGFloat":
//            return "float"
//        
//        // Boolean → bool
//        case "Bool":
//            return "bool"
//        
//        // Binary data → bytes
//        case "Data":
//            return "bytes"
//        
//        // Date/Time → datetime.datetime
//        case "Date":
//            return "datetime.datetime"
//        
//        case "DateComponents":
//            return "datetime.datetime"
//        
//        // URL → str
//        case "URL":
//            return "str"
//        
//        // Collections
//        case "Array":
//            return "list"
//        
//        case "Set":
//            return "set"
//        
//        case "Dictionary":
//            return "dict"
//        
//        // Range types → range
//        case "Range", "ClosedRange":
//            return "range"
//        
//        // Void/None
//        case "Void", "()":
//            return "None"
//        
//        // PyPointer (raw Python object)
//        case "PyPointer":
//            return "object"
//        
//        // Default to object for unknown types
//        default:
//            return "object"
//        }
//    }
//    
//    enum ParserError: Error {
//        case invalidClass
//        case invalidProperty
//    }
//}
//
//// Helper extension to check if Statement is blank
//extension Statement {
//    var isBlank: Bool {
//        if case .blank = self {
//            return true
//        }
//        return false
//    }
//}
