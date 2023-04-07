////
////  DummyConfig.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2022 Tangem AG. All rights reserved.
////
//
// import Foundation
// import TangemSdk
// import BlockchainSdk
//
// struct DummyConfig: UserWalletConfig {
//    var cardSetLabel: String? { nil }
//
//    var cardsCount: Int {
//        1
//    }
//
//    var cardName: String { "" }
//
//    var defaultCurve: EllipticCurve? { nil }
//
//    var onboardingSteps: OnboardingSteps { .wallet([]) }
//
//    var backupSteps: OnboardingSteps? { nil }
//
//    var supportedBlockchains: Set<Blockchain> { Blockchain.supportedBlockchains }
//
//    var defaultBlockchains: [StorageEntry] { [] }
//
//    var persistentBlockchains: [StorageEntry]? { nil }
//
//    var embeddedBlockchain: StorageEntry? { nil }
//
//    var warningEvents: [WarningEvent] { [] }
//
//    var tangemSigner: TangemSigner { .init(with: nil) }
//
//    var emailData: [EmailCollectedData] {
//        []
//    }
//
//    var userWalletIdSeed: Data? { nil }
//
//    var productType: Analytics.ProductType {
//        .other
//    }
//
//    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
//        return .available
//    }
//
//    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
//        throw CommonError.notImplemented
//    }
//
//    func makeOnboardingStepsBuilder(backupService: BackupService) -> OnboardingStepsBuilder {
//
//    }
// }
//
//
