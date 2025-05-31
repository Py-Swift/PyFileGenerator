//
//  Generator.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 27/05/2025.
//



public struct Generator {
    
    
    
    public protocol Statement: CustomStringConvertible {
        var indent: Int { get }
    }
    public protocol ExprProtocol: CustomStringConvertible {
        
    }
}

extension Generator.Statement {
    func indented(_ n: Int = 0) -> String {
        [String](repeating: "\t", count: indent + n).joined()
    }
}


extension Generator {
    
    struct Module: CustomStringConvertible {
        var body: [any Statement]
        
        var description: String {
            """
            from typing import Callable, Protocol
            
            \(body.map(\.description).joined(separator: "\n\n"))
            """
        }
    }
}

extension Generator {
        
    struct Class: Statement {
        var indent: Int
        var name: String
        var bases: [any CustomStringConvertible]
        var body: [Statement]
        
        
        
        var description: String {
            let bases = bases.map(\.description).joined(separator: ", ")
            return """
            class \(name)(\(bases)):
            \(indented(1))\(body.map(\.description).joined(separator:  "\n\n" + indented(1) ))
            """
        }
    }
    
    struct ClassBase: CustomStringConvertible {
        var base: any ExprProtocol
        
        var description: String {
            base.description
        }
    }
}

extension Generator {
    struct AnyExpr: Statement {
        var indent: Int
        var expression: any ExprProtocol
        
        
        
        var description: String {
            expression.description
        }
    }
}

extension Generator {
    struct Function: Statement {
        var indent: Int
        var name: String
        var arguments: Arguments
        var return_type: ExprProtocol?
        
        
        struct Arguments: CustomStringConvertible{
            var arguments: [Argument]
            
            var description: String {
                "(\(arguments.map(\.description).joined(separator: ", ")))"
            }
        }
        
        struct Argument: CustomStringConvertible, ExpressibleByStringLiteral {
            var name: String
            var type: ExprProtocol?
            
            var description: String {
                if let type {
                    "\(name): \(type)"
                } else {
                    name
                }
            }
            init(name: String, type: ExprProtocol? = nil) {
                self.name = name
                self.type = type
            }
            
            init(stringLiteral value: StringLiteralType) {
                name = value
            }
        }
        
        
        
        var description: String {
            let returning = if let return_type {" -> \(return_type)"} else {""}
            return """
            def \(name)\(arguments)\(returning): ...
            """
        }
    }
    
    
}

extension Generator {
    struct AnnAssign: Statement {
        var indent: Int
        var name: String
        var typeAnnotation: any ExprProtocol
        
        var description: String {
            "\(name): \(typeAnnotation)"
        }
    }
    
    struct PropertyFunction: Statement {
        var indent: Int
        var name: String
        var typeAnnotation: any ExprProtocol
        
        var description: String {
            """
            @property
            \(indented())def \(name) -> \(typeAnnotation): ...
            """
        }
    }
    
    struct DictType: ExprProtocol {
        var key: ExprProtocol
        var value: ExprProtocol
        
        var description: String {
            "dict[\(key), \(value)]"
        }
    }
    
    struct DictExpr {
        
    }
    
    struct ListType: ExprProtocol {
        var type: any ExprProtocol
        
        var description: String {
            "list[\(type)]"
        }
    }
    
    struct ListExpr: ExprProtocol {
        var elements: [any ExprProtocol]
        
        var description: String {
            "[\(elements.map(\.description).joined(separator: ", "))]"
        }
    }
    
    struct TupleType {
        
    }
    
    struct TupleExpr {
        
    }
    
    struct OptionalType: ExprProtocol {
        let wrapped: any ExprProtocol
        
        var description: String {
            if let wrap = wrapped as? Generator.WrappedType {
                "\"\(wrap.wrapped) | None\""
            } else {
                "\(wrapped) | None"
            }
            
        }
    }
    
    struct TypeAnnotation: ExprProtocol {
        let name: String
        var description: String {
            name
        }
    }
    
    struct WrappedType: ExprProtocol {
        let wrapped: String
        
        var description: String { "\"\(wrapped)\""}
    }
    
    struct CallableType: ExprProtocol {
        var argument: ExprProtocol
        var return_type: ExprProtocol
        
        var description: String {
            return "Callable[\(argument), \(return_type)]"
        }
    }
    
    
}

extension Optional: Generator.ExprProtocol, Swift.CustomStringConvertible where Wrapped: Generator.ExprProtocol {
    public var description: String {
        switch self {
        case .none:
            "None"
        case .some(let wrapped):
            "(\(wrapped) | None)"
        }
    }
}


