//
//  PyTypeRepresentation.swift
//  PyFileGenerator
//
import PySwiftAST
import SwiftSyntax
import SwiftParser

extension PySwiftAST.Name: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(
            id: value,
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
}

extension PySwiftAST.List: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: PySwiftAST.Expression...) {
        self.init(elts: elements, ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil)
    }
    
    public init(_ elements: [PySwiftAST.Expression]) {
        self.init(elts: elements, ctx: .load, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil)
    }
}

extension PySwiftAST.Name {
    static func none(
        ctx: ExprContext = .load,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) -> Self {
        .init(
            id: "None",
            ctx: ctx,
            lineno: lineno,
            colOffset: colOffset,
            endLineno: endLineno,
            endColOffset: endColOffset
        )
    }
}

extension PySwiftAST.Subscript {
    static func tuple(
        elts: [Expression],
        ctx: ExprContext = .load,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) -> Self {
        return .init(
            value: .name("tuple"),
            slice: .tuple(Tuple(
                elts: elts,
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )),
            ctx: ctx,
            lineno: lineno,
            colOffset: colOffset,
            endLineno: endLineno,
            endColOffset: endColOffset
        )
    }
    
    static func callable(
        args: [Expression],
        returns: Expression? = nil,
        ctx: ExprContext = .load,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) -> Self {
        
        return .init(
            value: .name("Callable"),
            slice: .list([
                .list(.init(args)),
                returns ?? .name(.none())
            ]),
            ctx: ctx,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
    
    static func set(
        type: Expression,
        ctx: ExprContext = .load,
        lineno: Int = 0,
        colOffset: Int = 0,
        endLineno: Int? = nil,
        endColOffset: Int? = nil
    ) -> Self {
        
        return .init(
            value: .name("set"),
            slice: type,
            ctx: ctx,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
}

extension InitializerDeclSyntax {
    func functionDef() -> FunctionDef {
        let signature = signature
        var args: [Arg] = []
        
        // Add 'self' parameter
        args.append(Arg(
            arg: "self",
            annotation: nil,
            typeComment: nil
        ))
        
        // Add parameters
        for param in signature.parameterClause.parameters {
            let paramName = (param.secondName ?? param.firstName).text
            let annotation = swiftTypeToExpression(param.type)
            
            args.append(Arg(
                arg: paramName,
                annotation: annotation,
                typeComment: nil
            ))
        }
        
        let arguments = Arguments(
            posonlyArgs: [],
            args: args,
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        return FunctionDef(
            name: "__init__",
            args: arguments,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: [],
            returns: nil,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
    
    /// Build method FunctionDef from FunctionDeclSyntax
    private static func buildMethodFunction(from funcDecl: FunctionDeclSyntax) throws -> Statement {
        let methodName = funcDecl.name.text
        let signature = funcDecl.signature
        var args: [Arg] = []
        var decorators: [Expression] = []
        
        // Check if static method
        let isStatic = funcDecl.modifiers.contains { modifier in
            modifier.name.text == "static"
        }
        
        if isStatic {
            decorators.append(.name(Name(
                id: "staticmethod",
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )))
        } else {
            // Add 'self' parameter for instance methods
            args.append(Arg(
                arg: "self",
                annotation: nil,
                typeComment: nil
            ))
        }
        
        // Add parameters
        for param in signature.parameterClause.parameters {
            let paramName = (param.secondName ?? param.firstName).text
            let annotation = swiftTypeToExpression(param.type)
            
            args.append(Arg(
                arg: paramName,
                annotation: annotation,
                typeComment: nil
            ))
        }
        
        let arguments = Arguments(
            posonlyArgs: args,
            args: [],
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        // Parse return type
        let returnType = signature.returnClause.map { returnClause in
            swiftTypeToExpression(returnClause.type)
        }
        
        return .functionDef(FunctionDef(
            name: methodName,
            args: arguments,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: decorators,
            returns: returnType,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
    }
}

extension PySwiftAST.ClassDef {
    static func from(_ classDecl: ClassDeclSyntax) throws -> Self {
        let className = classDecl.name.text
        let members = classDecl.memberBlock.members
        var body: [Statement] = if members.count > 0 {
            []
        } else {
            [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))]
        }
        
        for member in classDecl.memberBlock.members {
            switch member.decl.as(DeclSyntaxEnum.self) {
                case .classDecl(let classDecl):
                    guard classDecl.isPyClass || classDecl.isPyContainer else { continue }
                    //body.append(.blank(2))
                    body.append(.classDef(try .from(classDecl)))
                case .initializerDecl(let initializerDecl):
                    guard initializerDecl.isPyInit else { continue }
                    //body.append(.blank())
                    body.append(.functionDef(initializerDecl.functionDef()))
                case .functionDecl(let functionDecl):
                    guard functionDecl.isPyMethod || functionDecl.isPyCall else { continue }
                    //body.append(.blank())
                    body.append(.functionDef(.from(functionDecl, cls: className)))
                case .variableDecl(let variableDecl):
                    guard variableDecl.isPyProperty else { continue }
                    //body.append(.blank())
                    body.append(contentsOf: try buildPropertyStatements(from: variableDecl))
                    
                default: continue
            }
        }
        

        
        return .init(
            name: className,
            bases: [],
            keywords: [],
            body: body,
            decoratorList: [],
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
    
    static func from(_ extDecl: ExtensionDeclSyntax, ext_data: PyClassByExtensionUnpack) throws -> Self {
        let className = extDecl.extendedType.trimmedDescription
        let members = extDecl.memberBlock.members
        
        let itemsCount = members.count + ext_data.functions.count  + ext_data.properties.count
        
        var body: [Statement] = if itemsCount > 0 {
            []
        } else {
            [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))]
        }
        
        body.append(contentsOf: try ext_data.properties.flatMap(buildPropertyStatements))
        body.append(contentsOf: ext_data.functions.map({.functionDef(.from($0, cls: className))}))
        
        for member in extDecl.memberBlock.members {
            switch member.decl.as(DeclSyntaxEnum.self) {
                case .classDecl(let classDecl):
                    guard classDecl.isPyClass || classDecl.isPyContainer else { continue }
                    //body.append(.blank(2))
                    body.append(.classDef(try .from(classDecl)))
                case .initializerDecl(let initializerDecl):
                    guard initializerDecl.isPyInit else { continue }
                    //body.append(.blank())
                    body.append(.functionDef(initializerDecl.functionDef()))
                case .functionDecl(let functionDecl):
                    guard functionDecl.isPyMethod else { continue }
                    //body.append(.blank())
                    body.append(.functionDef(.from(functionDecl, cls: className)))
                case .variableDecl(let variableDecl):
                    guard variableDecl.isPyProperty else { continue }
                    //body.append(.blank())
                    body.append(contentsOf: try buildPropertyStatements(from: variableDecl))
                    
                default: continue
            }
        }
        
        
        
        return .init(
            name: className,
            bases: [],
            keywords: [],
            body: body,
            decoratorList: [],
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
    
    private static func buildPropertyStatements(from varDecl: VariableDeclSyntax) throws -> [Statement] {
        guard let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw ParserError.invalidProperty
        }
        
        let propertyName = pattern.identifier.text
        let annotation = binding.typeAnnotation.map(swiftTypeToExpression)
        
        // Determine if property is getter-only or getter+setter
        let propertyType = detectPropertyType(binding: binding, varDecl: varDecl)
        
        var statements: [Statement] = []
        
        // Always create getter
        let getterArgs = Arguments(
            posonlyArgs: [],
            args: [Arg(arg: "self", annotation: nil, typeComment: nil)],
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        let propertyDecorator: Expression = .name(Name(
            id: "property",
            ctx: .load,
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        ))
        
        statements.append(.functionDef(FunctionDef(
            name: propertyName,
            args: getterArgs,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: [propertyDecorator],
            returns: annotation,
            typeComment: nil,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )))
        
        // Add setter if property is not getter-only
        if propertyType == .getterAndSetter {
            statements.append(.blank())
            
            let setterArgs = Arguments(
                posonlyArgs: [],
                args: [
                    Arg(arg: "self", annotation: nil, typeComment: nil),
                    Arg(arg: "value", annotation: annotation, typeComment: nil)
                ],
                vararg: nil,
                kwonlyArgs: [],
                kwDefaults: [],
                kwarg: nil,
                defaults: []
            )
            
            // Create @propertyName.setter decorator
            let setterDecorator: Expression = .attribute(Attribute(
                value: .name(Name(
                    id: propertyName,
                    ctx: .load,
                    lineno: 0,
                    colOffset: 0,
                    endLineno: nil,
                    endColOffset: nil
                )),
                attr: "setter",
                ctx: .load,
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            ))
            
            statements.append(.functionDef(FunctionDef(
                name: propertyName,
                args: setterArgs,
                body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
                decoratorList: [setterDecorator],
                returns: nil,
                typeComment: nil,
                typeParams: [],
                lineno: 0,
                colOffset: 0,
                endLineno: nil,
                endColOffset: nil
            )))
        }
        
        return statements
    }
    
    /// Detect if property is getter-only or getter+setter
    /// Based on PyFileGenerator logic
    private static func detectPropertyType(binding: PatternBindingSyntax, varDecl: VariableDeclSyntax) -> PropertyType {
        // 1. Check for 'if let' binding → getter only
        if let _ = binding.pattern.as(OptionalBindingConditionSyntax.self) {
            return .getterOnly
        }
        
        // 2. Check if it's 'let' declaration → getter only
        if varDecl.bindingSpecifier.tokenKind == .keyword(.let) {
            return .getterOnly
        }
        
        // 3. Check for computed property with accessors
        if let accessorBlock = binding.accessorBlock {
            switch accessorBlock.accessors {
                case .accessors(let accessors):
                    // Check if there's a setter accessor
                    let hasSetter = accessors.contains { accessor in
                        accessor.accessorSpecifier.tokenKind == .keyword(.set)
                    }
                    return hasSetter ? .getterAndSetter : .getterOnly
                    
                case .getter:
                    // Getter-only computed property
                    return .getterOnly
            }
        }
        
        // 4. Regular 'var' without explicit accessors → getter + setter
        if varDecl.bindingSpecifier.tokenKind == .keyword(.var) {
            return .getterAndSetter
        }
        
        // Default to getter-only for safety
        return .getterOnly
    }
}




enum PropertyType {
    case getterOnly
    case getterAndSetter
}

enum ParserError: Error {
    case invalidClass
    case invalidProperty
}


extension PySwiftAST.FunctionDef {
    static func from(_ decl: FunctionDeclSyntax, cls: String? = nil) -> Self {
        let methodName = decl.name.text
        let signature = decl.signature
        var args: [Arg] = []
        var decorators: [Expression] = [
//            .call(
//                .init(
//                    fun: .name("swiftName"),
//                    args: [.constant(.init(value: .string("\(decl.root.as(SourceFileSyntax.self))"), kind: nil, lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
//                    keywords: [],
//                    lineno: 0,
//                    colOffset: 0,
//                    endLineno: nil,
//                    endColOffset: nil
//                )
//            )
        ]
        
        if let _ = cls {
            let isStatic = decl.isStatic
            
            if isStatic {
                decorators.append(.name(Name(
                    id: "staticmethod",
                    ctx: .load,
                    lineno: 0,
                    colOffset: 0,
                    endLineno: nil,
                    endColOffset: nil
                )))
            } else {
                // Add 'self' parameter for instance methods
                args.append(Arg(
                    arg: "self",
                    annotation: nil,
                    typeComment: nil
                ))
            }
        }
        
        for param in signature.parameterClause.parameters {
            let paramName = (param.secondName ?? param.firstName).text
            let annotation = swiftTypeToExpression(param.type)
            
            args.append(Arg(
                arg: paramName,
                annotation: annotation,
                typeComment: nil
            ))
        }
        
        let arguments = Arguments(
            posonlyArgs: [],
            args: args,
            vararg: nil,
            kwonlyArgs: [],
            kwDefaults: [],
            kwarg: nil,
            defaults: []
        )
        
        // Parse return type
        let returnType = signature.returnClause.map { returnClause in
            swiftTypeToExpression(returnClause.type)
        }
        
        return .init(
            name: methodName,
            args: arguments,
            body: [.pass(Pass(lineno: 0, colOffset: 0, endLineno: nil, endColOffset: nil))],
            decoratorList: decorators,
            returns: returnType,
            typeComment: methodName,
            typeParams: [],
            lineno: 0,
            colOffset: 0,
            endLineno: nil,
            endColOffset: nil
        )
    }
}
