//
//  VoteResult.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 12/01/2022.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let voteResult = try VoteResult(json)

import Foundation

// MARK: - VoteResult
struct PollVoteResult: Codable {
    let id, pollID: Int
    let userID: String
    let voteOptionID: Int
    let voteOptionText, voteAnswer: String
    let isNoUser: Bool
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case pollID = "pollId"
        case userID = "userId"
        case voteOptionID = "voteOptionId"
        case voteOptionText, voteAnswer, isNoUser, displayName
    }
}

// MARK: VoteResult convenience initializers and mutators

extension PollVoteResult {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PollVoteResult.self, from: data)
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
        voteOptionID: Int? = nil,
        voteOptionText: String? = nil,
        voteAnswer: String? = nil,
        isNoUser: Bool? = nil,
        displayName: String? = nil
    ) -> PollVoteResult {
        return PollVoteResult(
            id: id ?? self.id,
            pollID: pollID ?? self.pollID,
            userID: userID ?? self.userID,
            voteOptionID: voteOptionID ?? self.voteOptionID,
            voteOptionText: voteOptionText ?? self.voteOptionText,
            voteAnswer: voteAnswer ?? self.voteAnswer,
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

func resultJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func resultJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

