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
    private var previousDeviceOrientation: UIDeviceOrientation?
    private var orientationDidChangeBag: AnyCancellable?
    private var serviceAvailableListenerBag: AnyCancellable?

    private init() {
        isHidden = AppSettings.shared.isHidingSensitiveInformation
        bind()
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func turnOn() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    func turnOff() {
        isHidden = false
        AppSettings.shared.isHidingSensitiveInformation = false
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func toggleVisibility() {
        AppSettings.shared.isHidingSensitiveInformation.toggle()
        isHidden = AppSettings.shared.isHidingSensitiveInformation
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private extension SensitiveTextVisibilityService {
    func bind() {
        orientationDidChangeBag = NotificationCenter
            .default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.orientationDidChange()
            }

        serviceAvailableListenerBag = AppSettings.shared.$isHidingSensitiveAvailable
            .withWeakCaptureOf(self)
            .sink { obj, isAvailable in
                isAvailable ? obj.turnOn() : obj.turnOff()
            }
    }

    func orientationDidChange() {
        if previousDeviceOrientation == .faceDown {
            toggleVisibility()
        }

        previousDeviceOrientation = UIDevice.current.orientation
    }
}
