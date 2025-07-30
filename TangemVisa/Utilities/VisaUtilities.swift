//
//  VisaUtilities.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

public enum VisaUtilities {}

public extension VisaUtilities {
    // [REDACTED_TODO_COMMENT]
    // Right now dApp is not ready, so we don't have actual page
    static let walletConnectURL = URL(string: "https://tangem.com/pay")!

    static var mandatoryCurve: EllipticCurve {
        .secp256k1
    }

    static var tokenId: String {
        "tether"
    }

    static var mockToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: tokenId
        )
    }

    static var visaBatchPrefix: String { "AE" }

    static var visaAdditionalBatches: [String] {
        [
            "FFFC",
        ]
    }

    static func visaBlockchain(isTestnet: Bool) -> Blockchain {
        .polygon(testnet: isTestnet)
    }

    static func makeCustomerWalletSigningRequestMessage(nonce: String) -> String {
        // This message format is defined by backend
        "Tangem Pay wants to sign in with your account. Nonce: \(nonce)"
    }

    static func makeEIP191Message(content: String) -> String {
        "\u{19}Ethereum Signed Message:\n\(content.count)\(content)"
    }

    static func isVisaCard(_ card: Card) -> Bool {
        return isVisaCard(firmwareVersion: card.firmwareVersion, batchId: card.batchId)
    }

    static func isVisaCard(firmwareVersion: FirmwareVersion, batchId: String) -> Bool {
        return FirmwareVersion.visaRange.contains(firmwareVersion.doubleValue)
            && (batchId.starts(with: visaBatchPrefix) || visaAdditionalBatches.contains(batchId))
    }
}

public extension VisaUtilities {
    static func makeAddressService(isTestnet: Bool) -> AddressService {
        AddressServiceFactory(
            blockchain: VisaUtilities.visaBlockchain(isTestnet: isTestnet)
        )
        .makeAddressService()
    }

    static func makeAddress(walletPublicKey: Data, isTestnet: Bool) throws(VisaUtilitiesError) -> Address {
        do {
            let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: nil)
            let walletAddress = try makeAddressService(isTestnet: isTestnet).makeAddress(for: publicKey, with: .default)
            return walletAddress
        } catch {
            throw .failedToCreateAddress(error)
        }
    }

    static func makeAddress(publicKey: Wallet.PublicKey, isTestnet: Bool) throws(VisaUtilitiesError) -> Address {
        do {
            let walletAddress = try makeAddressService(isTestnet: isTestnet).makeAddress(for: publicKey, with: .default)
            return walletAddress
        } catch {
            throw .failedToCreateAddress(error)
        }
    }

    static func makeAddress(using cardActivationResponse: CardActivationResponse, isTestnet: Bool) throws -> Address {
        guard let wallet = cardActivationResponse.signedActivationOrder.cardSignedOrder.wallets.first(where: { $0.curve == mandatoryCurve }) else {
            throw VisaActivationError.missingWallet
        }

        return try makeAddress(walletPublicKey: wallet.publicKey, isTestnet: isTestnet)
    }
}

/// - NOTE: We need to use this isTestnet = false, because in BlockchainSdk we have if for testnet `DerivationPath` generation
/// that didn't work properly, and for Visa we must generate derive keys using polygon derivation
public extension VisaUtilities {
    static var visaDefaultDerivationStyle: DerivationStyle {
        .v3
    }

    static var visaDefaultDerivationPath: DerivationPath? {
        VisaUtilities.visaBlockchain(isTestnet: false).derivationPath(for: visaDefaultDerivationStyle)
    }

    static func visaDerivationPath(style: DerivationStyle) -> DerivationPath? {
        VisaUtilities.visaBlockchain(isTestnet: false).derivationPath(for: style)
    }
}
