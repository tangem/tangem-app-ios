//
//  MobileSocialWalletInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSocialAuthentication

struct MobileSocialWalletInput {
    let credentials: TangemSocialAuthentication.SocialAuthCredentials
    let hasBackup: Bool
    let source: MobileSocialLoginSource
}
