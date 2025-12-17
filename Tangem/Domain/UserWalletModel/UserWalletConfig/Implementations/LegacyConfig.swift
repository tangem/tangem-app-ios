//
//  LegacyConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemSdk
import BlockchainSdk
import TangemFoundation

/// V3 Config
struct LegacyConfig: CardContainer {
    let card: CardDTO
    private let walletData: WalletData?

    private var defaultBlockchain: Blockchain? {
        guard let walletData = walletData else { return nil }

        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])
    }

    private var isMultiwallet: Bool {
        card.supportedCurves.contains(.secp256k1)
    }

    private var defaultToken: BlockchainSdk.Token? {
        guard let token = walletData?.token else { return nil }

        return .init(
            name: token.name,
            symbol: token.symbol,
            contractAddress: token.contractAddress,
            decimalCount: token.decimals
        )
    }

    init(card: CardDTO, walletData: WalletData?) {
        self.card = card
        self.walletData = walletData
    }
}

extension LegacyConfig: UserWalletConfig {
    var cardsCount: Int {
        1
    }

    var defaultName: String {
        "Tangem Card"
    }

    var createWalletCurves: [EllipticCurve] {
        if let defaultBlockchain {
            return [defaultBlockchain.curve]
        }

        // old white multiwallet
        if card.settings.maxWalletsCount > 1 {
            return [.secp256k1, .ed25519]
        }

        // should not be the case
        return []
    }

    var supportedBlockchains: Set<Blockchain> {
        if isMultiwallet || defaultBlockchain == nil {
            return SupportedBlockchains(version: .v1)
                .blockchains()
                .filter(supportedBlockchainFilter(for:))
        } else {
            return [defaultBlockchain!]
        }
    }

    var defaultBlockchains: [TokenItem] {
        if let defaultBlockchain = defaultBlockchain {
            let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
            if let defaultToken {
                return [TokenItem.token(defaultToken, network)]
            }

            return [TokenItem.blockchain(network)]
        } else {
            guard isMultiwallet else { return [] }

            let isTestnet = AppEnvironment.current.isTestnet
            let blockchains = [
                Blockchain.bitcoin(testnet: isTestnet),
                Blockchain.ethereum(testnet: isTestnet),
            ]

            return blockchains.map {
                let network = BlockchainNetwork($0, derivationPath: nil)
                return TokenItem.blockchain(network)
            }
        }
    }

    var persistentBlockchains: [TokenItem] {
        if isMultiwallet {
            return []
        }

        return defaultBlockchains
    }

    var embeddedBlockchain: TokenItem? {
        return defaultBlockchains.first
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if !hasFeature(.signing) {
            notifications.append(.oldCard)
        }

        if card.firmwareVersion.doubleValue < 2.28,
           NFCUtils.isPoorNfcQualityDevice {
            notifications.append(.oldDeviceOldCard)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .other
    }

    var cardHeaderImage: ImageType? {
        if walletData == nil {
            let multiWalletWhiteBatch = "CB79"
            let devKitBatch = "CB83"

            switch card.batchId {
            case multiWalletWhiteBatch:
                return Assets.Cards.multiWalletWhite
            case devKitBatch:
                return Assets.Cards.developer
            default:
                break
            }
        }

        return nil
    }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "card"]
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .disabled()
        case .passcode:
            return .disabled()
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .signing:
            if card.firmwareVersion.doubleValue >= 2.28
                || card.settings.securityDelay <= 15000 {
                return .available
            }

            return .disabled()
        case .longHashes:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect, .multiCurrency:
            if isMultiwallet {
                return .available
            } else {
                return .hidden
            }
        case .resetToFactory:
            if card.wallets.contains(where: { $0.settings.isPermanent }) {
                return .hidden
            }

            return .available
        case .hdWallets:
            return .hidden
        case .staking:
            return .available
        case .swapping,
             .nft:
            return isMultiwallet ? .available : .hidden
        case .referralProgram:
            return .hidden
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .iCloudBackup:
            return .hidden
        case .mnemonicBackup:
            return .hidden
        case .userWalletAccessCode:
            return .hidden
        case .userWalletBackup:
            return .hidden
        case .isBalanceRestrictionActive:
            return .hidden
        case .userWalletUpgrade:
            return .hidden
        case .cardSettings:
            return .available
        case .nfcInteraction:
            return .available
        case .transactionPayloadLimit:
            return .available
        case .tangemPay:
            return .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - SingleCardOnboardingStepsBuilderFactory

extension LegacyConfig: SingleCardOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension LegacyConfig {
    func supportedBlockchainFilter(for blockchain: Blockchain) -> Bool {
        if case .quai = blockchain {
            return false
        }

        return card.walletCurves.contains(blockchain.curve)
    }
}
