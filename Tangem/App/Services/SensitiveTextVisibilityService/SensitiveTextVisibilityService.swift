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
    private var bag: Set<AnyCancellable> = []

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
        NotificationCenter
            .default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.orientationDidChange()
            }
            .store(in: &bag)

        AppSettings.shared.$isHidingSensitiveAvailable
            .sink { [weak self] isAvailable in
                isAvailable ? self?.turnOn() : self?.turnOff()
            }
            .store(in: &bag)
    }

    func orientationDidChange() {
        if previousDeviceOrientation == .faceDown {
            toggleVisibility()
        }

        previousDeviceOrientation = UIDevice.current.orientation
    }
}
