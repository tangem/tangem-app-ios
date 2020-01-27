//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `PurgeWalletCommand`.
public struct PurgeWalletResponse {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Current status of the card [1 - Empty, 2 - Loaded, 3- Purged]
    public let status: CardStatus
}

/**
 * This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
 * the card changes state to ‘Empty’ and a new wallet can be created by CREATE_WALLET command.
 * If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
 * ‘Purged’ state is final, it makes the card useless.
 * @property cardId CID, Unique Tangem card ID number.
 */
@available(iOS 13.0, *)
public final class PurgeWalletCommand: CommandSerializer {
    public typealias CommandResponse = PurgeWalletResponse
    /// Unique Tangem card ID number
    let cardId: String
    
    public init(cardId: String) {
        self.cardId = cardId
    }
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let builder = createTlvBuilder(legacyMode: environment.legacyMode)
        try builder.append(.pin, value: environment.pin1)
        try builder.append(.pin2, value: environment.pin2)
        try builder.append(.cardId, value: cardId)
        
        let cApdu = CommandApdu(.purgeWallet, tlv: builder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> PurgeWalletResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return PurgeWalletResponse(
            cardId: try mapper.map(.cardId),
            status: try mapper.map(.status))
    }
}
