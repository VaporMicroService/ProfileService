//
//  Preference.swift
//  App
//
//  Created by Szymon Lorenz on 21/11/19.
//

import Foundation
import Foundation
import FluentPostgreSQL
import Vapor

final class Preference: PostgreSQLModel {
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    
    var id: Int?
    var profileID: Profile.ID
    var createdAt: Date?
    var updatedAt: Date?
    var type: String
    var value: [String]?
    
    init(profileID: Profile.ID, type: String, value: [String]) {
        self.type = type
        self.value = value
        self.profileID = profileID
    }
    
    func update(request: ProfileController.ParameterRequest) {
        self.type = request.type
        self.value = request.value
    }
}

extension Preference {
    var profile: Parent<Preference, Profile> {
        return parent(\.profileID)
    }
}

extension Preference: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(Preference.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.profileID)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.type)
            builder.field(for: \.value)
            
            builder.reference(from: \.profileID, to: \Profile.id, onDelete: .cascade)
            builder.unique(on: \.id)
            builder.unique(on: \.type)
        }
    }
}

extension Preference: Content { }
extension Preference: Parameter { }
