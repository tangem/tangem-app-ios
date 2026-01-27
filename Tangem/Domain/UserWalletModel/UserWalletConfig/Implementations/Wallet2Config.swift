//
//  Wallet2Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemFoundation
import TangemSdk
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
struct Wallet2Config {
    let card: CardDTO
    private let isDemo: Bool

    init(card: CardDTO, isDemo: Bool) {
        self.card = card
        self.isDemo = isDemo
    }
}

extension Wallet2Config: UserWalletConfig {
    var cardsCount: Int {
        if let backupCardsCount = card.backupStatus?.backupCardsCount {
            return backupCardsCount + 1
        } else {
            return 1
        }
    }

    var defaultName: String {
        "Wallet"
    }

    var createWalletCurves: [EllipticCurve] {
        if card.settings.maxWalletsCount == 1, let curve = card.supportedCurves.first {
            return [curve]
        }

        return [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var derivationStyle: DerivationStyle? {
        guard hasFeature(.hdWallets) else {
            return nil
        }

        return .v3
    }

    var canSkipBackup: Bool {
        if isDemo {
            return true
        }

        return false
    }

    var isWalletsCreated: Bool {
        return !card.wallets.isEmpty
    }

    var canImportKeys: Bool {
        card.settings.isKeysImportAllowed
    }

    var supportedBlockchains: Set<Blockchain> {
        SupportedBlockchains(version: .v2)
            .blockchains()
            .filter(supportedBlockchainFilter(for:))
    }

    var defaultBlockchains: [TokenItem] {
        if persistentBlockchains.isNotEmpty {
            return persistentBlockchains
        }

        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

        let entries: [TokenItem] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return TokenItem.blockchain(network)
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return TokenItem.blockchain(network)
        }

        return entries
    }

    var persistentBlockchains: [TokenItem] {
        guard isDemo else { return [] }

        let blockchainIds = DemoUtil().getDemoBlockchains(isTestnet: AppEnvironment.current.isTestnet)
            .filter { card.walletCurves.contains($0.curve) }
            .map { $0.coinId }

        let entries: [TokenItem] = blockchainIds.compactMap { coinId in
            guard let blockchain = supportedBlockchains.first(where: { $0.coinId == coinId }) else {
                return nil
            }

            if let derivationStyle = derivationStyle {
                let derivationPath = blockchain.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
                return TokenItem.blockchain(network)
            }

            let network = BlockchainNetwork(blockchain, derivationPath: nil)
            return TokenItem.blockchain(network)
        }

        return entries
    }

    var embeddedBlockchain: TokenItem? {
        return nil
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if isDemo, !AppEnvironment.current.isTestnet {
            notifications.append(.demoCard)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        isDemo ? .demoWallet : .wallet2
    }

    var cardHeaderImage: ImageType? {
        // Case with broken backup (e.g. CardLinked) and demo notes as wallets with maxWalletsCount == 1
        if cardsCount == 1 {
            return card.settings.maxWalletsCount == 1 ? Assets.Cards.wallet2Double : nil
        }

        // Wallet 2.0 cards can't be used without backup, so min number of cards = 2
        // and there can't be more than 3 cards.
        switch card.batchId {
        // Tron 37X cards
        case "AF07":
            return cardsCount == 2 ? Assets.Cards.tronDouble : Assets.Cards.tronTriple
        // Kaspa cards
        case "AF08":
            return cardsCount == 2 ? Assets.Cards.kaspaDouble : Assets.Cards.kaspaTriple
        // BAD Idea cards
        case "AF09":
            return cardsCount == 2 ? Assets.Cards.badIdeaDouble : Assets.Cards.badIdeaTriple
        // Wallet white
        case "AF15":
            return cardsCount == 2 ? Assets.Cards.wallet2WhiteDouble : Assets.Cards.wallet2WhiteTriple
        // Wallet traillant
        case "AF16":
            return cardsCount == 2 ? Assets.Cards.walletTraillantDouble : Assets.Cards.walletTraillantTriple
        // Wallet avrora
        case "AF18":
            return cardsCount == 2 ? Assets.Cards.walletAvroraDouble : Assets.Cards.walletAvroraTriple
        // Wallet JR
        case "AF14":
            return cardsCount == 2 ? Assets.Cards.jrDouble : Assets.Cards.jrTriple
        // Wallet grim
        case "AF13":
            return cardsCount == 2 ? Assets.Cards.grimDouble : Assets.Cards.grimTriple
        // Wallet satoshi friends
        case "AF19":
            return cardsCount == 2 ? Assets.Cards.satoshiFriendsDouble : Assets.Cards.satoshiFriendsTriple
        // New World Elite (NWE)
        case "AF26":
            return cardsCount == 2 ? Assets.Cards.newWorldEliteDouble : Assets.Cards.newWorldEliteTriple
        // Vechain
        case "AF29":
            return cardsCount == 2 ? Assets.Cards.vechainWalletDouble : Assets.Cards.vechainWalletTriple
        // Pizza Day Wallet
        case "AF33":
            return cardsCount == 2 ? Assets.Cards.pizzaDayWalletDouble : Assets.Cards.pizzaDayWalletTriple
        // Red panda
        case "AF34":
            return cardsCount == 2 ? Assets.Cards.redPandaDouble : Assets.Cards.redPandaTriple
        // Cryptoseth
        case "AF32":
            return cardsCount == 2 ? Assets.Cards.cryptosethDouble : Assets.Cards.cryptosethTriple
        // Kishu
        case "AF52":
            return cardsCount == 2 ? Assets.Cards.kishuDouble : Assets.Cards.kishuTriple
        // Baby Doge
        case "AF51":
            return cardsCount == 2 ? Assets.Cards.babyDogeDouble : Assets.Cards.babyDogeTriple
        // TG-COQ
        case "AF28":
            return cardsCount == 2 ? Assets.Cards.tgDouble : Assets.Cards.tgTriple
        // Coin Metrica
        case "AF27":
            return cardsCount == 2 ? Assets.Cards.coinMetricaDouble : Assets.Cards.coinMetricaTriple
        // Volt Inu
        case "AF35":
            return cardsCount == 2 ? Assets.Cards.voltInuDouble : Assets.Cards.voltInuTriple
        // Kaspa 2
        case "AF25", "AF61", "AF72":
            return cardsCount == 2 ? Assets.Cards.kaspa2Double : Assets.Cards.kaspa2Triple
        // Kaspa reseller
        case "AF31":
            return cardsCount == 2 ? Assets.Cards.kaspaResellerDouble : Assets.Cards.kaspaResellerTriple
        // Vivid: Lemon, Aqua, Grapefruit
        case "AF40", "AF41", "AF42", "AF75", "AF76", "AF77":
            return Assets.Cards.lemonAquaGrapefruit
        // Peach, Air, Glass
        case "AF43", "AF44", "AF45", "AF78", "AF79", "AF80":
            return Assets.Cards.peachAirGlass
        // Kaspa Mint
        case "AF73":
            return cardsCount == 2 ? Assets.Cards.kaspaMint2 : Assets.Cards.kaspaMint3
        // BTC Gold
        case "AF71", "AF990016", "AF990009":
            return cardsCount == 2 ? Assets.Cards.btcNew2 : Assets.Cards.btcNew3
        // Stealth wallet
        case "AF60", "AF74", "AF88":
            return cardsCount == 2 ? Assets.Cards.stealthWalletSET2 : Assets.Cards.stealthWalletSET3
        // Crypto Org
        case "AF57":
            return cardsCount == 2 ? Assets.Cards.cryptorgSet2 : Assets.Cards.cryptorgSet3
        // CryptoCasey
        case "AF21", "AF22", "AF23":
            return cardsCount == 2 ? Assets.Cards.cryptoCaseySet2 : Assets.Cards.cryptoCaseySet3
        // Konan
        case "AF93":
            return cardsCount == 2 ? Assets.Cards.konanDouble : Assets.Cards.konanTriple
        // Kaspy
        case "AF95":
            return cardsCount == 2 ? Assets.Cards.kaspyDouble : Assets.Cards.kaspyTriple
        // Kasper
        case "AF96":
            return cardsCount == 2 ? Assets.Cards.kasperDouble : Assets.Cards.kasperTriple
        // BTC365
        case "AF97":
            return cardsCount == 2 ? Assets.Cards.btc365Double : Assets.Cards.btc365Triple
        // Neiro on ETH
        case "AF98":
            return cardsCount == 2 ? Assets.Cards.neiroDouble : Assets.Cards.neiroTriple
        // Winter 2
        case "AF85", "AF86", "AF87", "AF990011", "AF990012", "AF990013":
            return cardsCount == 2 ? Assets.Cards.winter2Double : Assets.Cards.winter2Triple
        // USA
        case "AF91", "AF990017", "AF990056":
            return cardsCount == 2 ? Assets.Cards.usaDouble : Assets.Cards.usaTriple
        // Gets Mine
        case "BB000008":
            return cardsCount == 2 ? Assets.Cards.getsmineDouble : Assets.Cards.getsmineTriple
        // ChangeNow
        case "BB000013":
            return cardsCount == 2 ? Assets.Cards.changeNowDouble : Assets.Cards.changeNowTriple
        // Sin City
        case "BB000010":
            return cardsCount == 2 ? Assets.Cards.sinCityDouble : Assets.Cards.sinCityTriple
        // Rizo
        case "BB000012":
            return cardsCount == 2 ? Assets.Cards.rizoDouble : Assets.Cards.rizoTriple
        // Kroak
        case "BB000011":
            return cardsCount == 2 ? Assets.Cards.kroakDouble : Assets.Cards.kroakTriple
        // Kango
        case "BB000006":
            return cardsCount == 2 ? Assets.Cards.kangoDouble : Assets.Cards.kangoTriple
        // Wild Goat
        case "BB000001":
            return cardsCount == 2 ? Assets.Cards.wildGoatDouble : Assets.Cards.wildGoatTriple
        // Passim Pay
        case "BB000007":
            return cardsCount == 2 ? Assets.Cards.passimPayDouble : Assets.Cards.passimPayTriple
        // VNISH
        case "BB000005":
            return cardsCount == 2 ? Assets.Cards.vnishDouble : Assets.Cards.vnishTriple
        // Cash Club Gold
        case "BB000004":
            return cardsCount == 2 ? Assets.Cards.cashClubGoldDouble : Assets.Cards.cashClubGoldTriple
        // HODL (dreams come true)
        case "BB000009":
            return cardsCount == 2 ? Assets.Cards.hodlDouble : Assets.Cards.hodlTriple
        // Locked Money
        case "AF63":
            return cardsCount == 2 ? Assets.Cards.lockedMoneyDouble : Assets.Cards.lockedMoneyTriple
        // Ghoad
        case "AF89":
            return cardsCount == 2 ? Assets.Cards.ghoadDouble : Assets.Cards.ghoadTriple
        // Spring Bloom
        case "AF990001", "AF990002", "AF990004":
            return cardsCount == 2 ? Assets.Cards.springBloomDouble : Assets.Cards.springBloomTriple
        // Sun Drop
        case "AF990003", "AF990005":
            return cardsCount == 2 ? Assets.Cards.sunDropDouble : Assets.Cards.sunDropTriple
        // Chiliz
        case "BB000016":
            return cardsCount == 2 ? Assets.Cards.chilizDouble : Assets.Cards.chilizTriple
        // Ramen Cat
        case "AF990006", "AF990007", "AF990008":
            return cardsCount == 2 ? Assets.Cards.ramenCatDouble : Assets.Cards.ramenCatTriple
        // Sakura
        case "AF990029", "AF990030", "AF990031":
            return cardsCount == 2 ? Assets.Cards.sakuraDouble : Assets.Cards.sakuraTriple
        // Bitcoin Pizza
        case "AF990019":
            return cardsCount == 2 ? Assets.Cards.bitcoinPizzaDouble : Assets.Cards.bitcoinPizzaTriple
        // Keiro
        case "BB000017":
            return cardsCount == 2 ? Assets.Cards.keiroDouble : Assets.Cards.keiroTriple
        // Ubit
        case "BB000019":
            return cardsCount == 2 ? Assets.Cards.ubitDouble : Assets.Cards.ubitTriple
        // Pepecoin
        case "BB000015":
            return cardsCount == 2 ? Assets.Cards.pepeDouble : Assets.Cards.pepeTriple
        // Blush Sky summer collection
        case "AF990020", "AF990021", "AF990022":
            return cardsCount == 2 ? Assets.Cards.blushSkyDouble : Assets.Cards.blushSkyTriple
        // Electra Sea summer collection
        case "AF990023", "AF990024", "AF990025":
            return cardsCount == 2 ? Assets.Cards.electraSeaDouble : Assets.Cards.electraSeaTriple
        // Hyper Blue summer collection
        case "AF990026", "AF990027", "AF990028", "AF990050", "AF990051", "AF990052":
            return cardsCount == 2 ? Assets.Cards.hyperBlueDouble : Assets.Cards.hyperBlueTriple
        // Winter Sakura
        case "AF990053", "AF990054", "AF990055":
            return cardsCount == 2 ? Assets.Cards.winterSakuraDouble : Assets.Cards.winterSakuraTriple
        // Lunar
        case "AF990057", "AF990058", "AF990059":
            return cardsCount == 2 ? Assets.Cards.lunarDouble : Assets.Cards.lunarTriple
        // Tangem Wallet 2.0
        default:
            var isUserWalletWithRing = false

            if let userWalletIdSeed {
                let userWalletId = UserWalletId(with: userWalletIdSeed).stringValue
                isUserWalletWithRing = AppSettings.shared.userWalletIdsWithRing.contains(userWalletId)
            }

            if isUserWalletWithRing || RingUtil().isRing(batchId: card.batchId) {
                return cardsCount == 2 ? Assets.Cards.ring1card : Assets.Cards.ring2cards
            }

            return cardsCount == 2 ? Assets.Cards.wallet2Double : Assets.Cards.wallet2Triple
        }
    }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "card"]
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            if card.settings.isSettingAccessCodeAllowed {
                return .available
            }

            return .disabled()
        case .passcode:
            return .hidden
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .signing:
            return .available
        case .longHashes:
            return .available
        case .backup:
            if isDemo {
                return .demoStub
            }

            if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
                return .available
            }

            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            if isDemo {
                return .demoStub
            }

            return .available
        case .walletConnect:
            if isDemo {
                return .demoStub
            }

            return .available
        case .multiCurrency:
            return .available
        case .resetToFactory:
            if isDemo {
                return .demoStub
            }

            return .available
        case .hdWallets:
            return card.settings.isHDWalletAllowed ? .available : .hidden
        case .staking:
            if isDemo {
                return .demoStub
            }

            return .available
        case .referralProgram:
            if isDemo {
                return .demoStub
            }

            return .available
        case .swapping:
            if isDemo {
                return .demoStub
            }

            return .available
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .available
        case .nft:
            return .available
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
            return card.settings.isHDWalletAllowed ? .available : .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        if isDemo {
            return DemoWalletModelsFactory(config: self, userWalletId: userWalletId)
        }

        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        if hasFeature(.hdWallets) {
            return GenericWalletManagerFactory()
        } else {
            return SimpleWalletManagerFactory()
        }
    }
}

// MARK: - WalletOnboardingStepsBuilderFactory

extension Wallet2Config: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Wallet2Config {
    func supportedBlockchainFilter(for blockchain: Blockchain) -> Bool {
        if case .quai = blockchain {
            return hasFeature(.hdWallets)
        }

        return true
    }
}

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}

private extension CardDTO {
    var hasImportedWallets: Bool {
        wallets.contains(where: { $0.isImported == true })
    }
}
