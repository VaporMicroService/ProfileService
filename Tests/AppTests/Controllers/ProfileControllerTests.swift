//
//  ProfileControllerTests.swift
//  AppTests
//
//  Created by Szymon Lorenz on 25/11/19.
//

import Foundation
import Vapor
import XCTest
import FluentPostgreSQL
@testable import App

extension Profile {
    static func create(on connection: PostgreSQLConnection) throws -> Profile {
        let profile = Profile(ownerID: "1234")
        profile.gender = .male
        profile.name = "Test"
        profile.firstName = "Testing"
        profile.lastName = "Tester"
        profile.birthday = Date()
        profile.bio = "hdska csakjch fhewg vdsjlhvgds"
        return try profile.save(on: connection).wait()
    }
}

class ProfileControllerTests: XCTestCase {
    static let allTests = [
        ("testGetProfile", testGetProfile),
        ("testCreateProfile", testCreateProfile),
        ("testUpdateProfile", testUpdateProfile),
        ("testDeleteProfile", testDeleteProfile),
    ]
    
    let uri = "/profiles/"
    var app: Application!
    var conn: PostgreSQLConnection!
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()
    }
    
    func testGetProfile() throws {
        let profile = try Profile.create(on: conn)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(uri)/\(profile.id!)", method: .GET, headers: headers)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Profile.self)
        
        XCTAssertEqual(fetch.gender, profile.gender)
        XCTAssertEqual(fetch.name, profile.name)
        XCTAssertEqual(fetch.firstName, profile.firstName)
        XCTAssertEqual(fetch.lastName, profile.lastName)
        XCTAssertEqual(fetch.bio, profile.bio)
        XCTAssert(fetch.geoPoint?.longitude == profile.geoPoint?.longitude)
        XCTAssert(fetch.geoPoint?.latitude == profile.geoPoint?.latitude)
        XCTAssertEqual(formatter.string(from: fetch.birthday!), formatter.string(from: profile.birthday!))
        XCTAssertNotNil(fetch)
    }

    func testCreateProfile() throws {
        var profile = ProfileController.ProfileRequest()
        profile.gender = .male
        profile.userName = "Test"
        profile.firstName = "Testing"
        profile.lastName = "Tester"
        profile.birthday = Date()
        profile.bio = "hdska csakjch fhewg vdsjlhvgds"
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(uri)", method: .PUT, headers: headers, body: profile)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Profile.self)
        XCTAssertEqual(fetch.ownerID, "1234")
        XCTAssertEqual(fetch.gender, profile.gender)
        XCTAssertEqual(fetch.name, profile.userName)
        XCTAssertEqual(fetch.firstName, profile.firstName)
        XCTAssertEqual(fetch.lastName, profile.lastName)
        XCTAssertEqual(fetch.bio, profile.bio)
        XCTAssert(fetch.geoPoint?.longitude == profile.coordinates?.longitude)
        XCTAssert(fetch.geoPoint?.latitude == profile.coordinates?.latitude)
        XCTAssertEqual(formatter.string(from: fetch.birthday!), formatter.string(from: profile.birthday!))
        XCTAssertNotNil(fetch)
    }
    
    func testUpdateProfile() throws {
        _ = try Profile.create(on: conn)
        
        var profile = ProfileController.ProfileRequest()
        profile.gender = .male
        profile.userName = "Update"
        profile.firstName = "Updateing"
        profile.lastName = "Updateer"
        profile.birthday = Date()
        profile.bio = "fgdsjklavbzx,cmn sajgkdf weytufoq"
        
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(uri)", method: .PUT, headers: headers, body: profile)
        XCTAssertEqual(response.http.status.code, 200)
        
        let fetch = try response.content.syncDecode(Profile.self)
        XCTAssertEqual(fetch.ownerID, "1234")
        XCTAssertEqual(fetch.gender, profile.gender)
        XCTAssertEqual(fetch.name, profile.userName)
        XCTAssertEqual(fetch.firstName, profile.firstName)
        XCTAssertEqual(fetch.lastName, profile.lastName)
        XCTAssertEqual(fetch.bio, profile.bio)
        XCTAssert(fetch.geoPoint?.longitude == profile.coordinates?.longitude)
        XCTAssert(fetch.geoPoint?.latitude == profile.coordinates?.latitude)
        XCTAssertEqual(formatter.string(from: fetch.birthday!), formatter.string(from: profile.birthday!))
        XCTAssertNotNil(fetch)
    }
    
    func testDeleteProfile() throws {
        let profile = try Profile.create(on: conn)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentID, value: "1234")
        let response = try app.sendRequest(to: "\(uri)/\(profile.id!)", method: .DELETE, headers: headers)
        XCTAssertEqual(response.http.status.code, 200)
    }
    
}
