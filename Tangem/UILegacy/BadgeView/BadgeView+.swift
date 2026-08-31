//
//  BadgeView+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

// MARK: - Badges

extension BadgeView.Item {
    static let noBackup = Self(title: Localization.hwBackupNoBackup, style: .error)
    static let done = Self(title: Localization.commonDone, style: .accent)
    static let recommended = Self(title: Localization.commonRecommended, style: .accent)
    static let actionRequired = Self(title: Localization.hwCloudBackupStatusActionRequired, style: .warning)
}

extension BadgeView {
    static let noBackup = Self(item: .noBackup)
    static let done = Self(item: .done)
    static let recommended = Self(item: .recommended)
}
