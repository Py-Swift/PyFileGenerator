//
//  PySerializableFactory.swift
//  PyFileGenerator
//
//  Created by CodeBuilder on 15/02/2026.
//

final class PySerializableFactory {
    static let shared: PySerializableFactory = .init()
    
    var registeredTypes: [String:String] = [:]
    
    init() {
        
    }
    
    static func registerType(_ type: PySerializableInfo) {
        shared.registeredTypes[type.swiftType] = type.pyType
    }
    
    static func registerType(_ swiftType: String, pyType: String) {
        shared.registeredTypes[swiftType] = pyType
    }
    
    static func castType(_ type: String) -> String? {
        shared.registeredTypes[type]
    }
}
