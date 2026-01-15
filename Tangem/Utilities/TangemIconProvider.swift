//
//  TangemIconProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI
import TangemAssets

protocol TangemIconProvider {
    func getMainButtonIcon() -> MainButton.Icon?
}

class CommonTangemIconProvider: TangemIconProvider {
    private let icon: MainButton.Icon?

    convenience init(config: UserWalletConfig) {
        self.init(hasNFCInteraction: config.hasFeature(.nfcInteraction))
    }

    convenience init(signer: TangemSigner) {
        self.init(hasNFCInteraction: signer.hasNFCInteraction)
    }

    init(hasNFCInteraction: Bool) {
        icon = hasNFCInteraction ? .trailing(Assets.tangemIcon) : nil
    }

    func getMainButtonIcon() -> MainButton.Icon? {
        icon
    }
}
