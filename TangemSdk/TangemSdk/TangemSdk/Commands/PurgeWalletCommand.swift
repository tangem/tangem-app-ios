//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `PurgeWalletCommand`.
public struct PurgeWalletResponse: TlvCodable {
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
public final class PurgeWalletCommand: Command {
    public typealias CommandResponse = PurgeWalletResponse
    
    public init() {}
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.pin2, value: environment.pin2)
            .append(.cardId, value: environment.cardId)
        
        let cApdu = CommandApdu(.purgeWallet, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> PurgeWalletResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.deserializeApduFailed
        }
        
        let mapper = TlvDecoder(tlv: tlv)
        return PurgeWalletResponse(
            cardId: try mapper.decode(.cardId),
            status: try mapper.decode(.status))
    }
}
