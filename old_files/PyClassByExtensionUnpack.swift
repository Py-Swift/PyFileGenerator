////
////  PyClassByExtensionUnpack.swift
////  PyFileGenerator
////
//import PySwiftAST
//import SwiftSyntax
//import SwiftParser
//
//
//class PyClassByExtensionUnpack {
//    
//    //var unretained = false
//    var functions: [FunctionDeclSyntax] = []
//    var properties: [VariableDeclSyntax] = []
//    var typeAliases: [TypeAliasDeclSyntax] = []
//    //var type: TypeSyntax
//    
//    init(arguments: LabeledExprListSyntax) throws {
//        for argument in arguments {
//            guard let label = argument.label else { continue }
//            switch argument.label?.text {
//            case "expr":
//                if let expr = argument.expression.as(StringLiteralExprSyntax.self) {
//                    let statements = Parser.parse(source: expr.segments.description).statements
//                    
//                    for blockItem in statements {
//                        let item = blockItem.item
//                        switch item {
//                            case .decl(let declSyntax):
//                                switch declSyntax.as(DeclSyntaxEnum.self) {
//                                    case .variableDecl(let variableDecl):
//                                        properties.append(variableDecl)
//                                    case .functionDecl(let functionDecl):
//                                        functions.append(functionDecl)
//                                    case .typeAliasDecl(let typeAliasDecl):
//                                        typeAliases.append(typeAliasDecl)
//                                    default:
//                                        continue
//                                }
//                            case .stmt(let stmtSyntax):
//                                continue
//                            case .expr(let exprSyntax):
//                                continue
//                        }
//                    }
//                    
////                    let funcDecls = statements.compactMap { blockItem in
////                        let item = blockItem.item
////                        return switch item.kind {
////                        case .functionDecl: item.as(FunctionDeclSyntax.self)
////                        default: nil
////                        }
////                    }
////                    functions = funcDecls
////                    
////                    let varDecls = statements.compactMap { blockItem in
////                        let item = blockItem.item
////                        return switch item.kind {
////                        case .variableDecl: item.as(VariableDeclSyntax.self)
////                        default: nil
////                        }
////                    }
////                    properties = varDecls
//                }
//            
//            default: continue
//            }
//        
//        }
//        
//    }
//    
//    struct ArgError: Error {
//        
//    }
//}
