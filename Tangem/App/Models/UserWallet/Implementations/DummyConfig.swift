//
//  DummyConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct DummyConfig: UserWalletConfig {
    var emailConfig: EmailConfig { .default }

    var touURL: URL? { nil }

    var cardSetLabel: String? { nil }

    var cardIdDisplayFormat: CardIdDisplayFormat { .full }

    var features: Set<UserWalletFeature> { [] }

    var defaultCurve: EllipticCurve? { nil }

    var onboardingSteps: OnboardingSteps { .wallet([]) }

    var backupSteps: OnboardingSteps? { nil }

    var supportedBlockchains: Set<Blockchain> { Blockchain.supportedBlockchains }

    var defaultBlockchains: [StorageEntry] { [] }

    var persistentBlockchains: [StorageEntry]? { nil }
    
    var embeddedBlockchain: StorageEntry? { nil }
    
    var disabledFeatureReason: String? { nil }
}
