//
//  CardWalletUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

class CardWalletUnlocker: UserWalletModelUnlocker {
    var canUnlockAutomatically: Bool { false }
    var canShowUnlockUIAutomatically: Bool { false }

    private let userWalletId: UserWalletId
    private let scanner: UserWalletCardScanner

    init(userWalletId: UserWalletId, config: UserWalletConfig) {
        self.userWalletId = userWalletId

        let scanParameters = CardScannerParameters(
            shouldAskForAccessCodes: false,
            performDerivations: false,
            sessionFilter: config.cardSessionFilter
        )

        let cardScanner = CardScannerFactory().makeScanner(
            with: config.makeTangemSdk(),
            parameters: scanParameters
        )

        scanner = UserWalletCardScanner(scanner: cardScanner)
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        let scanResult = await scanner.scanCard()
        switch scanResult {
        case .onboarding:
            return .error(UserWalletRepositoryError.cardWithWrongUserWalletIdScanned)

        case .error(let error):
            return .error(error)

        case .scanTroubleshooting:
            return .scanTroubleshooting

        case .success(let cardInfo):
            let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

            guard let userWalletId = UserWalletId(config: config),
                  let encryptionKey = UserWalletEncryptionKey(config: config) else {
                return .error(UserWalletRepositoryError.cantUnlockWallet)
            }

            if userWalletId != self.userWalletId {
                return .error(UserWalletRepositoryError.cardWithWrongUserWalletIdScanned)
            }

            return .success(userWalletId: userWalletId, encryptionKey: encryptionKey)
        }
    }
}
