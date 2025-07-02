//
//  WalletConnectDAppDomainVerificationViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct SwiftUI.Color
import TangemAssets
import TangemLocalization

struct WalletConnectDAppDomainVerificationViewState {
    let severity: Severity
    let iconAsset: ImageType
    let title: String
    let body: String
    let badge: String?

    var buttons: [Button]
}

extension WalletConnectDAppDomainVerificationViewState {
    enum Severity {
        case verified
        case attention
        case critical
    }

    struct Button: Hashable {
        enum Style: Hashable {
            case primary
            case secondary
        }

        enum Role: Hashable {
            case done
            case cancel
            case connectAnyway
        }

        let title: String
        let style: Style
        let role: Role
        var isLoading: Bool

        static let done = Button(title: Localization.commonDone, style: .secondary, role: .done, isLoading: false)
        static let cancel = Button(title: Localization.commonCancel, style: .primary, role: .cancel, isLoading: false)
        static let connectAnyway = Button(title: Localization.wcAlertConnectAnyway, style: .secondary, role: .connectAnyway, isLoading: false)
    }
}
