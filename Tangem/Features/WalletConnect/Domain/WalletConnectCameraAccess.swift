//
//  WalletConnectCameraAccess.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectCameraAccess {
    /// A status that indicates the user hasn’t yet granted or denied authorization.
    case notDetermined

    /// A status that indicates the app isn’t permitted to use media capture devices.
    case restricted

    /// A status that indicates the user has explicitly denied an app permission to capture media.
    case denied

    /// A status that indicates the user has explicitly granted an app permission to capture media.
    case authorized
}
