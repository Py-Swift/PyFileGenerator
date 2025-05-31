//
//  SetupPy.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 02/06/2025.
//
import ArgumentParser
import PathKit
import SwiftSyntax
import SwiftParser

extension ModuleGenerator {
    
    struct SetupPy: AsyncParsableCommand {
        @Argument var files: [Path]
        @Option var destination: Path?
        
        
        func run() async throws {
            guard let destination else { return }
            
            let decls = files.declSyntax()
            
            let py_modules = decls.compactMap { decl in
                switch decl.as(DeclSyntaxEnum.self) {
                case .structDecl(let structDecl):
                    structDecl
                default: nil
                }
            }
            
            guard let py_module = py_modules.first else { return }
            
            let module_name = py_module.name.text.camelCaseToSnakeCase()
            
            let setup_py = destination + "setup.py"
            try setup_py.write(setup_py_file(), encoding: .utf8)
            
            let toml_path = destination + "pyproject.toml"
            try toml_path.write(toml_file(name: module_name, setup_py: true), encoding: .utf8)
        }
    }
    
}
