//
//  AVWalletConnectCameraAccessProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import class AVFoundation.AVCaptureDevice

struct AVWalletConnectCameraAccessProvider: WalletConnectCameraAccessProvider {
    func checkIfCameraAccessDenied() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .denied
    }
}
