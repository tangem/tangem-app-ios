//
//  SessionMobileAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemMobileWalletSdk

final class SessionMobileAccessCodeManager {
    private let stateSubject = CurrentValueSubject<MobileAccessCodeState, Never>(.available(.normal))
    private let stateCommandSubject = PassthroughSubject<StateCommand, Never>()

    private var attemptsToLockLimit: Int { configuration.attemptsToLockLimit }
    private var lockedTimeout: TimeInterval { configuration.lockedTimeout }

    private var currentUptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletId: UserWalletId
    private let configuration: MobileAccessCodeConfiguration
    private let storageManager: MobileAccessCodeStorageManager

    private var bag: Set<AnyCancellable> = []
    private var timersBag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        configuration: MobileAccessCodeConfiguration,
        storageManager: MobileAccessCodeStorageManager
    ) {
        self.userWalletId = userWalletId
        self.configuration = configuration
        self.storageManager = storageManager
        bind()
        getInitialState()
    }
}

// MARK: - Private methods

private extension SessionMobileAccessCodeManager {
    func bind() {
        stateCommandSubject
            .withWeakCaptureOf(self)
            .flatMap { manager, command in
                manager.makeStatePublisher(command: command)
            }
            .subscribe(stateSubject)
            .store(in: &bag)
    }

    func getInitialState() {
        stateCommandSubject.send(.load)
    }
}

// MARK: - State methods

private extension SessionMobileAccessCodeManager {
    func makeStatePublisher(command: StateCommand) -> AnyPublisher<MobileAccessCodeState, Never> {
        switch command {
        case .load:
            let store = getWrongAccessCodeStore()
            return makeStatePublisher(store: store)

        case .update(let state):
            return Just(state).eraseToAnyPublisher()

        case .startTimer(let timer):
            return makeLockedTimerPublisher(timer: timer)
        }
    }

    func makeStatePublisher(store: MobileWrongAccessCodeStore) -> AnyPublisher<MobileAccessCodeState, Never> {
        let failedAttemptsLockIntervals = store.lockIntervals
        let failedAttemptsCount = failedAttemptsLockIntervals.count

        guard failedAttemptsCount != 0 else {
            let state: MobileAccessCodeState = .available(.normal)
            return Just(state).eraseToAnyPublisher()
        }

        if failedAttemptsCount >= attemptsToLockLimit {
            return makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: failedAttemptsLockIntervals)
        } else {
            let remaining = attemptsToLockLimit - failedAttemptsCount
            let state: MobileAccessCodeState = .available(.beforeLock(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: [TimeInterval]) -> AnyPublisher<MobileAccessCodeState, Never> {
        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsLockIntervals: failedAttemptsLockIntervals) {
            let timer = LockedTimer(duration: lockDuration)
            return makeLockedTimerPublisher(timer: timer)
        } else {
            let state: MobileAccessCodeState = .available(.beforeWarning(remaining: 0))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func calculateAccessCodeLockDuration(failedAttemptsLockIntervals: [TimeInterval]) -> TimeInterval? {
        let lockTime = failedAttemptsLockIntervals.last

        if let lockTime {
            let remainingTime = lockTime - currentUptime

            guard remainingTime > 0 else {
                return nil
            }

            return remainingTime
        } else {
            return nil
        }
    }
}

// MARK: - Timers

private extension SessionMobileAccessCodeManager {
    func makeLockedTimerPublisher(timer: LockedTimer) -> AnyPublisher<MobileAccessCodeState, Never> {
        let endUptime = currentUptime + timer.duration
        return makeCountdownPublisher(endUptime: endUptime)
            .withWeakCaptureOf(self)
            .map { manager, countdown in
                manager.makeAccessCodeState(countdown: countdown)
            }
            .eraseToAnyPublisher()
    }

    func makeAccessCodeState(countdown: TimeInterval) -> MobileAccessCodeState {
        let isTimeoutFinished = (countdown == 0)

        if isTimeoutFinished {
            return .available(.beforeWarning(remaining: 0))
        } else {
            return .locked(.beforeWarning(remaining: 0, timeout: countdown))
        }
    }

    func makeCountdownPublisher(endUptime: TimeInterval) -> AnyPublisher<TimeInterval, Never> {
        Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .scan(endUptime + 1) { remaining, _ in
                let currentUptime = ProcessInfo.processInfo.systemUptime
                return endUptime - currentUptime
            }
            .prefix(while: { $0 > 0 })
            .append(0)
            .eraseToAnyPublisher()
    }
}

// MARK: - MobileAccessCodeManager

extension SessionMobileAccessCodeManager: MobileAccessCodeManager {
    var statePublisher: AnyPublisher<MobileAccessCodeState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func validate(accessCode: String) {
        switch stateSubject.value {
        case .available(let availableState):
            let command: StateCommand
            do {
                let context = try mobileWalletSdk.validate(auth: .accessCode(accessCode), for: userWalletId)
                cleanWrongAccessCodeStore()
                command = makeValidCommand(context: context)
            } catch {
                storeWrongAccessCode()
                command = makeInvalidCommand(availableState: availableState)
            }
            stateCommandSubject.send(command)

        case .locked, .valid, .unavailable:
            break
        }
    }

    func cleanWrongAccessCodes() {
        cleanWrongAccessCodeStore()
    }

    private func makeInvalidCommand(availableState: MobileAccessCodeState.AvailableState) -> StateCommand {
        switch availableState {
        case .normal:
            let remaining = attemptsToLockLimit - 1
            return makeAvailableBeforeLockCommand(remaining: remaining)

        case .beforeLock(let lastRemaining):
            let remaining = lastRemaining - 1

            if remaining > 0 {
                return makeAvailableBeforeLockCommand(remaining: remaining)
            } else {
                return makeLockedTimerCommand(duration: lockedTimeout)
            }

        case .beforeWarning:
            return makeLockedTimerCommand(duration: lockedTimeout)

        case .beforeDelete:
            assertionFailure("Unexpected state: .beforeDelete should never happen.")
            return makeLockedTimerCommand(duration: lockedTimeout)
        }
    }
}

// MARK: - Commands maker

private extension SessionMobileAccessCodeManager {
    // Available commands

    func makeAvailableBeforeLockCommand(remaining: Int) -> StateCommand {
        let state: MobileAccessCodeState = .available(.beforeLock(remaining: remaining))
        return .update(state)
    }

    // Timer commands

    func makeLockedTimerCommand(duration: TimeInterval) -> StateCommand {
        let timer = LockedTimer(duration: duration)
        return .startTimer(timer)
    }

    // Other commands

    func makeUnavailableCommand(state: MobileAccessCodeState.UnavailableState) -> StateCommand {
        return .update(.unavailable(state))
    }

    func makeValidCommand(context: MobileWalletContext) -> StateCommand {
        return .update(.valid(context))
    }
}

// MARK: - Storing

extension SessionMobileAccessCodeManager {
    func getWrongAccessCodeStore() -> MobileWrongAccessCodeStore {
        storageManager.getWrongAccessCodeStore(userWalletId: userWalletId)
    }

    func storeWrongAccessCode() {
        let lockInterval = currentUptime + lockedTimeout
        storageManager.storeWrongAccessCode(userWalletId: userWalletId, lockInterval: lockInterval)
    }

    func cleanWrongAccessCodeStore() {
        storageManager.removeWrongAccessCode(userWalletId: userWalletId)
    }
}

// MARK: - Types

private extension SessionMobileAccessCodeManager {
    enum StateCommand {
        case load
        case update(MobileAccessCodeState)
        case startTimer(LockedTimer)
    }

    struct LockedTimer {
        let duration: TimeInterval
    }
}
