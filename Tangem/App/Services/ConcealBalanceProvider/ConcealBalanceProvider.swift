//
//  ConcealBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class ConcealBalanceProvider: ObservableObject {
    static let shared = ConcealBalanceProvider()

    @Published private(set) var isConceal: Bool
    private var orientationDidChangeBag: AnyCancellable?

    private init() {
        isConceal = AppSettings.shared.isHideSensitiveInformation
        bind()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func toggleIsConceal() {
        isConceal.toggle()
        AppSettings.shared.isHideSensitiveInformation = isConceal
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private extension ConcealBalanceProvider {
    func bind() {
        orientationDidChangeBag = NotificationCenter
            .default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.orientationDidChange()
            }
    }

    func orientationDidChange() {
        switch UIDevice.current.orientation {
        case .faceDown:
            toggleIsConceal()
        default:
            break
        }
    }
}
