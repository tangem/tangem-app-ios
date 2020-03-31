//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CreateWalletResponse: TlvCodable {
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
public final class CreateWalletCommand: Command {
    public typealias CommandResponse = CreateWalletResponse
    
    public init() {}
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.pin2, value: environment.pin2)
            .append(.cardId, value: environment.card?.cardId)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        let cApdu = CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let mapper = TlvDecoder(tlv: tlv)
        return CreateWalletResponse(
            cardId: try mapper.decode(.cardId),
            status: try mapper.decode(.status),
            walletPublicKey: try mapper.decode(.walletPublicKey))
    }
}
