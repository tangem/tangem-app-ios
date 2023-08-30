//
//  SensitiveTextVisibilityService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class SensitiveTextVisibilityService: ObservableObject {
    static let shared = SensitiveTextVisibilityService()

    @Published private(set) var isHidden: Bool
    private var orientationDidChangeBag: AnyCancellable?

    private init() {
        isHidden = AppSettings.shared.isHideSensitiveInformation
        bind()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func toggleIsConceal() {
        isHidden.toggle()
        AppSettings.shared.isHideSensitiveInformation = isHidden
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private extension SensitiveTextVisibilityService {
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
