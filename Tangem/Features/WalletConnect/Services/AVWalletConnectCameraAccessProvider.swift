//
//  AVWalletConnectCameraAccessProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import AVFoundation

struct AVWalletConnectCameraAccessProvider: WalletConnectCameraAccessProvider {
    func checkCameraAccess() -> WalletConnectCameraAccess {
        AVCaptureDevice.authorizationStatus(for: .video).toWalletConnectCameraAccess
    }

    func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { accessGranted in
                continuation.resume(returning: accessGranted)
            }
        }
    }
}

private extension AVAuthorizationStatus {
    var toWalletConnectCameraAccess: WalletConnectCameraAccess {
        switch self {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default:
            .notDetermined
        }
    }
}
