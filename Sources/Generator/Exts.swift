//
//  Exts.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 27/05/2025.
//

import SwiftSyntax

extension AttributeListSyntax.Element {
    
    func isAttribute(_ text: String) -> Bool {
        switch self {
        case .attribute(let attributeSyntax):
            attributeSyntax.attributeName.trimmedDescription == text
        case .ifConfigDecl(let ifConfigDeclSyntax):
            false
        }
    }
    
    var isPyFunction: Bool { isAttribute("PyFunction" )}
    var isPyMethod: Bool { isAttribute("PyMethod")}
    var isPyMethodEx: Bool { isAttribute("PyMethodEx") }
    var isPyProperty: Bool { isAttribute("PyProperty") }
    var isPyPropertyEx: Bool { isAttribute("PyPropertyEx") }
    
    var isPyModule: Bool { isAttribute("PyModule") }
    var isPyClass: Bool { isAttribute("PyClass") }
    var isPyClassExt: Bool { isAttribute("PyClassByExtension") }
    var isPyContainer: Bool { isAttribute("PyContainer") }
    var isPyCall: Bool { isAttribute("PyCall") }
    var isPyInit: Bool { isAttribute("PyInit") }
}

extension AttributeListSyntax {
    var isPyFunction: Bool { contains(where: \.isPyFunction) }
    var isPyMethod: Bool { contains(where: \.isPyMethod) }
    var isPyProperty: Bool { contains(where: \.isPyProperty) }
    var isPyModule: Bool { contains(where: \.isPyModule) }
    var isPyClass: Bool { contains(where: \.isPyClass) }
    var isPyClassExt: Bool { contains(where: \.isPyClassExt) }
    var isPyContainer: Bool { contains(where: \.isPyContainer) }
    var isPyCall: Bool { contains(where: \.isPyCall) }
    var isPyInit: Bool { contains(where: \.isPyInit) }
}

extension FunctionDeclSyntax {
    var isPyFunction: Bool { attributes.isPyFunction }
    var isPyMethod: Bool { attributes.isPyMethod }
    var isPyCall: Bool { attributes.isPyCall }
    var isStatic: Bool {
        modifiers.contains(where: { $0.name.text == "static" })
    }
}

extension VariableDeclSyntax {
    var isPyProperty: Bool { attributes.isPyProperty }
}

extension ClassDeclSyntax {
    var isPyClass: Bool { attributes.isPyClass }
    var isPyClassExt: Bool { attributes.isPyClassExt }
    var isPyContainer: Bool { attributes.isPyContainer }
}

extension ExtensionDeclSyntax {
    var isPyClassExt: Bool { attributes.isPyClassExt }
}

extension StructDeclSyntax {
    var isPyModule: Bool { attributes.isPyModule }
}

extension InitializerDeclSyntax {
    var isPyInit: Bool { attributes.isPyInit }
}
