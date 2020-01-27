//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CreateWalletResponse {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Current status of the card [1 - Empty, 2 - Loaded, 3- Purged]
    public let status: CardStatus
    /// Public key of a newly created blockchain wallet.
    public let walletPublicKey: Data
}

/**
 * This command will create a new wallet on the card having ‘Empty’ state.
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of [CreateWalletCommand] or [ReadCommand]
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by [SignCommand] and [CheckWalletCommand].
 * RemainingSignature is set to MaxSignatures.
 *
 * @property cardId CID, Unique Tangem card ID number.
 */
@available(iOS 13.0, *)
public final class CreateWalletCommand: CommandSerializer {
    public typealias CommandResponse = CreateWalletResponse
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
        
        if let cvc = environment.cvc {
            try builder.append(.cvc, value: cvc)
        }
        
        let cApdu = CommandApdu(.createWallet, tlv: builder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return CreateWalletResponse(
            cardId: try mapper.map(.cardId),
            status: try mapper.map(.status),
            walletPublicKey: try mapper.map(.walletPublicKey))
    }
}
