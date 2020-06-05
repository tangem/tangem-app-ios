//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `CheckWalletCommand`.
public struct CreateWalletResponse: ResponseCodable {
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
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand`or `ReadCommand`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `CheckWalletCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
@available(iOS 13.0, *)
public final class CreateWalletCommand: Command {
    public typealias CommandResponse = CreateWalletResponse
    
    public init() {}
    
    deinit {
        print ("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if let status = card.status {
            switch status {
            case .empty:
                  break
            case .loaded:
                return .alreadyCreated
            case .notPersonalized:
                return .notPersonalized
            case .purged:
                return .cardIsPurged
            }
        }
        
        if card.isActivated {
            return .notActivated
        }
        
        return nil
    }
    
    func performAfterCheck(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError? {
        if error == .invalidParams {
            return .pin2OrCvcRequired
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.pin2, value: environment.pin2)
            .append(.cardId, value: environment.card?.cardId)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return CreateWalletResponse(
            cardId: try decoder.decode(.cardId),
            status: try decoder.decode(.status),
            walletPublicKey: try decoder.decode(.walletPublicKey))
    }
}
