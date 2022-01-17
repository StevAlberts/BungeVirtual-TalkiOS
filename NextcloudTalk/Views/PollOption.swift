//
//  PollOption.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 07/01/2022.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let pollOption = try PollOption(json)

import Foundation

// MARK: - PollOption
struct PollOption: Codable {
    let id, pollID: Int
    let owner, ownerDisplayName: String
    let ownerIsNoUser: Bool
    let released: Int
    let pollOptionText: String
    let timestamp, order, confirmed, duration: Int
    let rank, no, yes, maybe: Int
    let realNo, votes: Int
    let isBookedUp: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case pollID = "pollId"
        case owner, ownerDisplayName, ownerIsNoUser, released, pollOptionText, timestamp, order, confirmed, duration, rank, no, yes, maybe, realNo, votes, isBookedUp
    }
}

// MARK: PollOption convenience initializers and mutators

extension PollOption {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PollOption.self, from: data)
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
        owner: String? = nil,
        ownerDisplayName: String? = nil,
        ownerIsNoUser: Bool? = nil,
        released: Int? = nil,
        pollOptionText: String? = nil,
        timestamp: Int? = nil,
        order: Int? = nil,
        confirmed: Int? = nil,
        duration: Int? = nil,
        rank: Int? = nil,
        no: Int? = nil,
        yes: Int? = nil,
        maybe: Int? = nil,
        realNo: Int? = nil,
        votes: Int? = nil,
        isBookedUp: Bool? = nil
    ) -> PollOption {
        return PollOption(
            id: id ?? self.id,
            pollID: pollID ?? self.pollID,
            owner: owner ?? self.owner,
            ownerDisplayName: ownerDisplayName ?? self.ownerDisplayName,
            ownerIsNoUser: ownerIsNoUser ?? self.ownerIsNoUser,
            released: released ?? self.released,
            pollOptionText: pollOptionText ?? self.pollOptionText,
            timestamp: timestamp ?? self.timestamp,
            order: order ?? self.order,
            confirmed: confirmed ?? self.confirmed,
            duration: duration ?? self.duration,
            rank: rank ?? self.rank,
            no: no ?? self.no,
            yes: yes ?? self.yes,
            maybe: maybe ?? self.maybe,
            realNo: realNo ?? self.realNo,
            votes: votes ?? self.votes,
            isBookedUp: isBookedUp ?? self.isBookedUp
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

func newJSONDecoders() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}
 
func newJSONEncoders() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

