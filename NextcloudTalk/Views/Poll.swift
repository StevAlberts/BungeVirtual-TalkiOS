//
//  Polls.swift
//  NextcloudTalk
//
//  Created by StevalbertS on 07/01/2022.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let poll = try Poll(json)

import Foundation

// MARK: - Poll
struct Poll: Codable {
    let id: Int
    let type, title, pollDescription, descriptionSafe: String
    let owner: String
    let created, expire, deleted: Int
    let access: String
    let anonymous: Int
    let allowComment: Bool
    let allowMaybe: Int
    let allowProposals: String
    let proposalsExpire, voteLimit, optionLimit: Int
    let showResults: String
    let adminAccess: Int
    let ownerDisplayName: String
    let important, hideBookedUp, useNo: Int
    let voteType: String
    let notifMins: Int
    let meetingName, meetingID: String
    let openingTime: Int
    let allowAddOptions, allowArchive, allowDelete, allowEdit: Bool
    let allowSeeResults, allowSeeUsernames, allowSubscribe, allowView: Bool
    let allowVote: Bool
    let displayName: String
    let isOwner, loggedIn: Bool
    let pollID: Int
    let token: String
    let userHasVoted: Bool
    let userID: String
    let userIsInvolved, pollExpired: Bool
    let pollExpire: Int

    enum CodingKeys: String, CodingKey {
        case id, type, title
        case pollDescription = "description"
        case descriptionSafe, owner, created, expire, deleted, access, anonymous, allowComment, allowMaybe, allowProposals, proposalsExpire, voteLimit, optionLimit, showResults, adminAccess, ownerDisplayName, important, hideBookedUp, useNo, voteType, notifMins, meetingName
        case meetingID = "meetingId"
        case openingTime, allowAddOptions, allowArchive, allowDelete, allowEdit, allowSeeResults, allowSeeUsernames, allowSubscribe, allowView, allowVote, displayName, isOwner, loggedIn
        case pollID = "pollId"
        case token, userHasVoted
        case userID = "userId"
        case userIsInvolved, pollExpired, pollExpire
    }
}

// MARK: Poll convenience initializers and mutators

extension Poll {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Poll.self, from: data)
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
        type: String? = nil,
        title: String? = nil,
        pollDescription: String? = nil,
        descriptionSafe: String? = nil,
        owner: String? = nil,
        created: Int? = nil,
        expire: Int? = nil,
        deleted: Int? = nil,
        access: String? = nil,
        anonymous: Int? = nil,
        allowComment: Bool? = nil,
        allowMaybe: Int? = nil,
        allowProposals: String? = nil,
        proposalsExpire: Int? = nil,
        voteLimit: Int? = nil,
        optionLimit: Int? = nil,
        showResults: String? = nil,
        adminAccess: Int? = nil,
        ownerDisplayName: String? = nil,
        important: Int? = nil,
        hideBookedUp: Int? = nil,
        useNo: Int? = nil,
        voteType: String? = nil,
        notifMins: Int? = nil,
        meetingName: String? = nil,
        meetingID: String? = nil,
        openingTime: Int? = nil,
        allowAddOptions: Bool? = nil,
        allowArchive: Bool? = nil,
        allowDelete: Bool? = nil,
        allowEdit: Bool? = nil,
        allowSeeResults: Bool? = nil,
        allowSeeUsernames: Bool? = nil,
        allowSubscribe: Bool? = nil,
        allowView: Bool? = nil,
        allowVote: Bool? = nil,
        displayName: String? = nil,
        isOwner: Bool? = nil,
        loggedIn: Bool? = nil,
        pollID: Int? = nil,
        token: String? = nil,
        userHasVoted: Bool? = nil,
        userID: String? = nil,
        userIsInvolved: Bool? = nil,
        pollExpired: Bool? = nil,
        pollExpire: Int? = nil
    ) -> Poll {
        return Poll(
            id: id ?? self.id,
            type: type ?? self.type,
            title: title ?? self.title,
            pollDescription: pollDescription ?? self.pollDescription,
            descriptionSafe: descriptionSafe ?? self.descriptionSafe,
            owner: owner ?? self.owner,
            created: created ?? self.created,
            expire: expire ?? self.expire,
            deleted: deleted ?? self.deleted,
            access: access ?? self.access,
            anonymous: anonymous ?? self.anonymous,
            allowComment: allowComment ?? self.allowComment,
            allowMaybe: allowMaybe ?? self.allowMaybe,
            allowProposals: allowProposals ?? self.allowProposals,
            proposalsExpire: proposalsExpire ?? self.proposalsExpire,
            voteLimit: voteLimit ?? self.voteLimit,
            optionLimit: optionLimit ?? self.optionLimit,
            showResults: showResults ?? self.showResults,
            adminAccess: adminAccess ?? self.adminAccess,
            ownerDisplayName: ownerDisplayName ?? self.ownerDisplayName,
            important: important ?? self.important,
            hideBookedUp: hideBookedUp ?? self.hideBookedUp,
            useNo: useNo ?? self.useNo,
            voteType: voteType ?? self.voteType,
            notifMins: notifMins ?? self.notifMins,
            meetingName: meetingName ?? self.meetingName,
            meetingID: meetingID ?? self.meetingID,
            openingTime: openingTime ?? self.openingTime,
            allowAddOptions: allowAddOptions ?? self.allowAddOptions,
            allowArchive: allowArchive ?? self.allowArchive,
            allowDelete: allowDelete ?? self.allowDelete,
            allowEdit: allowEdit ?? self.allowEdit,
            allowSeeResults: allowSeeResults ?? self.allowSeeResults,
            allowSeeUsernames: allowSeeUsernames ?? self.allowSeeUsernames,
            allowSubscribe: allowSubscribe ?? self.allowSubscribe,
            allowView: allowView ?? self.allowView,
            allowVote: allowVote ?? self.allowVote,
            displayName: displayName ?? self.displayName,
            isOwner: isOwner ?? self.isOwner,
            loggedIn: loggedIn ?? self.loggedIn,
            pollID: pollID ?? self.pollID,
            token: token ?? self.token,
            userHasVoted: userHasVoted ?? self.userHasVoted,
            userID: userID ?? self.userID,
            userIsInvolved: userIsInvolved ?? self.userIsInvolved,
            pollExpired: pollExpired ?? self.pollExpired,
            pollExpire: pollExpire ?? self.pollExpire
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

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
