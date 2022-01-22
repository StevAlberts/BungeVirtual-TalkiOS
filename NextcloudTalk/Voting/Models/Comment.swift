//
//  Comment.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 17/01/2022.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let comment = try Comment(json)

import Foundation

// MARK: - Comment
struct Comment: Codable {
    let id, pollID: Int
    let userID: String
    let timestamp: Int
    let comment: String
    let isNoUser: Bool
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case pollID = "pollId"
        case userID = "userId"
        case timestamp, comment, isNoUser, displayName
    }
}

// MARK: Comment convenience initializers and mutators

extension Comment {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Comment.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        id: Int? = nil,
        pollID: Int? = nil,
        userID: String? = nil,
        timestamp: Int? = nil,
        comment: String? = nil,
        isNoUser: Bool? = nil,
        displayName: String? = nil
    ) -> Comment {
        return Comment(
            id: id ?? self.id,
            pollID: pollID ?? self.pollID,
            userID: userID ?? self.userID,
            timestamp: timestamp ?? self.timestamp,
            comment: comment ?? self.comment,
            isNoUser: isNoUser ?? self.isNoUser,
            displayName: displayName ?? self.displayName
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders

//func newJSONDecoder() -> JSONDecoder {
//    let decoder = JSONDecoder()
//    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
//        decoder.dateDecodingStrategy = .iso8601
//    }
//    return decoder
//}
//
//func newJSONEncoder() -> JSONEncoder {
//    let encoder = JSONEncoder()
//    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
//        encoder.dateEncodingStrategy = .iso8601
//    }
//    return encoder
//}

 
