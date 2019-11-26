import Foundation
import FluentPostgreSQL
import FluentPostGIS
import Vapor

struct GeoPoint: Codable {
    let longitude: Double
    let latitude: Double
}

enum Gender: Int, PostgreSQLRawEnum {
    case male
    case female
    case other
}

final class Profile: PostgreSQLModel {
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    
    var id: Int?
    var createdAt: Date?
    var updatedAt: Date?
    var name: String?
    var firstName: String?
    var lastName: String?
    var birthday: Date?
    var gender: Gender?
    var bio: String?
    var location: GeographicPoint2D?
    
    var geoPoint: GeoPoint? {
        get {
            if let geoPoint = location {
                return GeoPoint(longitude: geoPoint.longitude, latitude: geoPoint.latitude)
            }
            return nil
        }
        set {
            if let geoPoint = newValue {
                location = GeographicPoint2D(longitude: geoPoint.longitude,
                                             latitude: geoPoint.latitude)
            } else {
                location = nil
            }
        }
    }
    
    func update(request: ProfileController.ProfileRequest) {
        if let gender = request.gender { self.gender = gender }
        if let userName = request.userName { self.name = userName }
        if let firstName = request.firstName { self.firstName = firstName }
        if let lastName = request.lastName { self.lastName = lastName }
        if let birthday = request.birthday { self.birthday = birthday }
        if let bio = request.bio { self.bio = bio }
        if let geoPoint = request.coordinates {
            location = GeographicPoint2D(longitude: geoPoint.longitude,
                                         latitude: geoPoint.latitude)
        }
    }
}

extension Profile {
    var preference: Children<Profile, Preference> {
        return children(\.profileID)
    }
}

extension Profile: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(Profile.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
            builder.field(for: \.name)
            builder.field(for: \.firstName)
            builder.field(for: \.lastName)
            builder.field(for: \.birthday)
            builder.field(for: \.gender)
            builder.field(for: \.bio)
            builder.field(for: \.location)
            
            builder.unique(on: \.id)
        }
    }
}

extension Profile: Content { }
extension Profile: Parameter { }
