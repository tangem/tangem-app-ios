//
//  MobileBackupSeedPhraseTypeDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

protocol MobileBackupSeedPhraseTypeDelegate: AnyObject {
    func onSeedPhraseBackup() async
    func onSeedPhraseReveal(context: MobileWalletContext) async
}
