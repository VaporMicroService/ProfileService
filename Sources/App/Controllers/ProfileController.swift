import Foundation
import FluentPostgreSQL
import FluentPostGIS
import Vapor

struct ProfileController {
    // MARK: Content
    struct ProfileRequest: Content {
        var coordinates: GeoPoint?
        var userName: String?
        var firstName: String?
        var lastName: String?
        var birthday: Date?
        var gender: Gender?
        var bio: String?
    }
    
    struct ParameterRequest: Content {
        var type: String
        var value: [String]
    }
    
    struct LocationRequest: Content {
        let longitude: Double
        let latitude: Double
        let distance: Double
        let offset: Int?
    }
    
    var decoderJSON: JSONDecoder = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    // MARK: Boot
    func boot(router: Router) throws {
        let route = router.grouped("profiles")
        
        route.get("/", Int.parameter, use: get)
        route.put("/", use: put)
        route.delete("/", Int.parameter, use: delete)
        route.get("page", use: getProfiles)
        route.put("/", Int.parameter, "preferences", use: getPreference)
        route.put("/", Int.parameter, "preferences", use: putPreference)
    }
    
    //MARK: Preference
    func getPreference(_ req: Request) throws -> Future<[Preference]> {
        return Profile.find(try req.parameters.next(), on: req).flatMap { profile -> EventLoopFuture<[Preference]> in
            guard let profile = profile else { throw Abort(.notFound) }
            return try profile.preference.query(on: req).all()
        }
    }
    
    func putPreference(_ req: Request) throws -> EventLoopFuture<Preference> {
        return try req.content.decode(json: ParameterRequest.self, using: decoderJSON).flatMap { update -> EventLoopFuture<Preference> in
            return Profile.find(try req.parameters.next(), on: req).flatMap { profile -> EventLoopFuture<Preference> in
                guard let profile = profile else { throw Abort(.notFound) }
                return try profile.preference.query(on: req).filter(\.type == update.type).first().flatMap({ preference -> EventLoopFuture<Preference> in
                    guard let preference = preference else {
                        let newPreference = Preference(profileID: try profile.requireID(), type: update.type, value: update.value)
                        newPreference.update(request: update)
                        return newPreference.save(on: req)
                    }
                    preference.update(request: update)
                    return preference.save(on: req)
                })
            }
        }
    }
    
    //MARK: Profile
    func get(_ req: Request) throws -> Future<Profile> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return Profile.find(try req.parameters.next(), on: req).map { profile -> Profile in
            guard let profile = profile else { throw Abort(.notFound) }
            guard profile.ownerID == ownerId else { throw Abort(.forbidden) }
            return profile
        }
    }
    
    func put(_ req: Request) throws -> Future<Profile> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return try req.content.decode(json: ProfileRequest.self, using: decoderJSON).flatMap { update -> Future<Profile> in
            return Profile.query(on: req).filter(\.ownerID == ownerId).first().flatMap({ profile -> EventLoopFuture<Profile> in
                guard let profile = profile else {
                    let newProfile = Profile(ownerID: ownerId)
                    newProfile.update(request: update)
                    return newProfile.save(on: req)
                }
                profile.update(request: update)
                return profile.save(on: req)
            })
        }
    }
    
    func delete(_ req: Request) throws -> Future<HTTPResponseStatus> {
        guard let ownerId = req.http.headers.firstValue(name: .contentID) else { throw Abort(.unauthorized) }
        return Profile.find(try req.parameters.next(), on: req).flatMap { profile -> EventLoopFuture<HTTPResponseStatus> in
            guard let profile = profile else { throw Abort(.notFound) }
            guard profile.ownerID == ownerId else { throw Abort(.forbidden) }
            return profile.delete(on: req).transform(to: .ok)
        }
    }
    
    func getProfiles(_ req: Request) throws -> Future<[Profile]> {
        let query = try req.query.decode(LocationRequest.self)
        let searchLocation = GeographicPoint2D(longitude: query.longitude, latitude: query.latitude)
        let offset = query.offset ?? 0
        return Profile.query(on: req)
            .filter(\Profile.location != nil)
            .filterGeometryDistanceWithin(\Profile.location!, searchLocation, query.distance)
            .range((1*offset)...(50*offset))
            .all()
    }
}
