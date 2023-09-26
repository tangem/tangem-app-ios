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
import CoreMotion

class SensitiveTextVisibilityService: ObservableObject {
    static let shared = SensitiveTextVisibilityService()

    @Published private(set) var isHidden: Bool
    private lazy var manager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 0.3
        return manager
    }()

    private let operationQueue = OperationQueue()
    private var previousIsFaceDown = false
    private var bag: Set<AnyCancellable> = []

    private init() {
        isHidden = AppSettings.shared.isHidingSensitiveInformation
        bind()
    }

    deinit {
        endUpdates()
    }

    func toggleVisibility() {
        AppSettings.shared.isHidingSensitiveInformation.toggle()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.async {
            self.isHidden = AppSettings.shared.isHidingSensitiveInformation
        }
    }
}

private extension SensitiveTextVisibilityService {
    func bind() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink(receiveValue: { [weak self] _ in
                self?.endUpdates()
            })
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink(receiveValue: { [weak self] _ in
                self?.startUpdates()
            })
            .store(in: &bag)

        AppSettings.shared.$isHidingSensitiveAvailable
            .sink { [weak self] isAvailable in
                self?.updateAvailability(isAvailable)
            }
            .store(in: &bag)
    }

    func updateAvailability(_ isAvailable: Bool) {
        if isAvailable {
            startUpdates()
        } else {
            isHidden = false
            AppSettings.shared.isHidingSensitiveInformation = false
            endUpdates()
        }
    }

    func startUpdates() {
        guard AppSettings.shared.isHidingSensitiveAvailable else {
            return
        }

        manager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
            if error != nil {
                self?.endUpdates()
                return
            }

            if let attitude = motion?.attitude {
                self?.motionDidUpdate(attitude: attitude)
            }
        }
    }

    func endUpdates() {
        manager.stopDeviceMotionUpdates()
    }

    func motionDidUpdate(attitude: CMAttitude) {
        let pitch = attitude.pitch
        let roll = attitude.roll

        // The 30° deviation
        let deviation = Double.pi / 6

        // Full the face down orientation it's a Double.pi or almost 180° or -180° in degrees value
        // We're decide that -150° ... 150° range it isn't face down
        let faceUpRange = (-.pi + deviation) ... (.pi - deviation)

        // We need to check that the iPhone isn't portrait
        // Otherwise, we may get false positives
        let isPortrait = pitch > .pi / 4
        let isFaceDown = !faceUpRange.contains(roll) && !isPortrait

        if previousIsFaceDown, !isFaceDown {
            toggleVisibility()
        }

        previousIsFaceDown = isFaceDown
    }
}
