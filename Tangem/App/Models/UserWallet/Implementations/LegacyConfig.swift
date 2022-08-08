//
//  LegacyConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import WalletConnectSwift

/// V3 Config
struct LegacyConfig {
    private let card: Card
    private let walletData: WalletData

    private var defaultBlockchain: Blockchain {
        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var isTestnet: Bool {
        defaultBlockchain.isTestnet
    }

    private var defaultToken: BlockchainSdk.Token? {
        guard let token = walletData.token else { return nil }

        return .init(name: token.name,
                     symbol: token.symbol,
                     contractAddress: token.contractAddress,
                     decimalCount: token.decimals)
    }

    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }
}

extension LegacyConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardSetLabel: String? {
        nil
    }

    var cardIdDisplayFormat: CardIdDisplayFormat {
        .full
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .singleWallet([.createWallet, .success])
        }

        return .singleWallet([])
    }

    var backupSteps: OnboardingSteps? {
        nil
    }

    var supportedBlockchains: Set<Blockchain> {
        if hasFeature(.manageTokens) {
            let allBlockchains = isTestnet ? Blockchain.supportedTestnetBlockchains
                : Blockchain.supportedBlockchains

            return allBlockchains.filter { card.supportedCurves.contains($0.curve) }
        } else {
            return [defaultBlockchain]
        }
    }

    var defaultBlockchains: [StorageEntry] {
        let derivationPath = defaultBlockchain.derivationPath(for: .legacy)
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: derivationPath)
        let tokens = defaultToken.map { [$0] } ?? []
        let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        var warnings = getBaseWarningEvents(for: card)

        if !hasFeature(.signing) {
            warnings.append(.oldCard)
        }

        if card.firmwareVersion.doubleValue < 2.28,
           NFCUtils.isPoorNfcQualityDevice {
            warnings.append(.oldDeviceOldCard)
        }

        if isTestnet {
            warnings.append(.testnetCard)
        }

        return warnings
    }

    func selectBlockchain(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork? {
        guard hasFeature(.walletConnect) else { return nil }

        guard let blockchain = WalletConnectNetworkParserUtility.parse(dAppInfo: dAppInfo,
                                                                       isTestnet: isTestnet) else {
            return nil
        }

        let derivationPath = blockchain.derivationPath(for: card.derivationStyle)
        let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
        return network
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .disabled()
        case .passcode:
            return .disabled()
        case .signing:
            if card.firmwareVersion.doubleValue >= 2.28
                || card.settings.securityDelay <= 15000 {
                return .available
            }

            return .disabled()
        case .longHashes:
            return .unavailable
        case .signedHashesCounter:
            if card.supportedCurves.contains(.secp256k1) {
                return .unavailable
            } else {
                return .available
            }
        case .backup:
            return .unavailable
        case .twinning:
            return .unavailable
        case .sendingToPayID:
            return .available
        case .exchange:
            return .available
        case .walletConnect, .manageTokens, .tokensSearch:
            if card.supportedCurves.contains(.secp256k1) {
                return .available
            } else {
                return .unavailable
            }
        case .activation:
            return .unavailable
        case .resetToFactory:
            return .available
        case .showAddress:
            return .available
        case .withdrawal:
            return .available
        }
    }
}
