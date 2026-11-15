//
//  MCPSessionMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import Foundation
import TangemFoundation

enum MCPSessionMapper {
    static func mapToDomain(_ response: MCPSessionsDTO.Get.Response) throws(DecodingError) -> [MCPSession] {
        try response.map(mapSessionDTO)
    }

    static func mapToDeleteQueryParameters(_ userWalletID: UserWalletId) -> MCPSessionsDTO.Delete.Request.QueryParameters {
        MCPSessionsDTO.Delete.Request.QueryParameters(walletID: userWalletID.value.base64URLEncodedString)
    }

    private static func mapSessionDTO(_ sessionDTO: MCPSessionsDTO.Get.Session) throws(DecodingError) -> MCPSession {
        guard let userWalletID = mapUserWalletID(from: sessionDTO.walletId) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Session \(sessionDTO.id) has a wallet ID that is not 32 bytes of hex."
                )
            )
        }

        return MCPSession(
            id: sessionDTO.id,
            userWalletID: userWalletID,
            agent: MCPAgentMapper.mapToDomain(sessionDTO),
            createdAt: sessionDTO.createdAt
        )
    }

    // [REDACTED_TODO_COMMENT]
    private static func mapUserWalletID(from hexString: String) -> UserWalletId? {
        let hexCharactersInSingleByte = 2
        let requiredLengthInBytes = 32
        let requiredLengthInHexCharacters = requiredLengthInBytes * hexCharactersInSingleByte

        guard hexString.count == requiredLengthInHexCharacters, hexString.allSatisfy(\.isHexDigit) else {
            return nil
        }

        var value = Data(capacity: requiredLengthInBytes)
        var index = hexString.startIndex

        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: hexCharactersInSingleByte)

            guard let byte = UInt8(hexString[index ..< nextIndex], radix: 16) else {
                return nil
            }

            value.append(byte)
            index = nextIndex
        }

        return UserWalletId(value: value)
    }
}
