//
//  CommonMobileAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemMobileWalletSdk

final class CommonMobileAccessCodeManager {
    private let stateSubject = CurrentValueSubject<MobileAccessCodeState, Never>(.available(.normal))
    private let stateCommandSubject = PassthroughSubject<StateCommand, Never>()

    private var attemptsToLockLimit: Int { configuration.attemptsToLockLimit }
    private var attemptsBeforeWarningLimit: Int { configuration.attemptsBeforeWarningLimit }
    private var attemptsBeforeDeleteLimit: Int { configuration.attemptsBeforeDeleteLimit }
    private var lockedTimeout: TimeInterval { configuration.lockedTimeout }
    private var currentLockInterval: TimeInterval { currentUptime + lockedTimeout }

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

private extension CommonMobileAccessCodeManager {
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

private extension CommonMobileAccessCodeManager {
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

        if failedAttemptsCount >= attemptsBeforeDeleteLimit {
            return Just(.unavailable(.needsToDelete)).eraseToAnyPublisher()
        } else if failedAttemptsCount >= attemptsBeforeWarningLimit {
            return makeBeforeDeleteStatePublisher(failedAttemptsLockIntervals: failedAttemptsLockIntervals)
        } else if failedAttemptsCount >= attemptsToLockLimit {
            return makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: failedAttemptsLockIntervals)
        } else {
            let remaining = attemptsToLockLimit - failedAttemptsCount
            let state: MobileAccessCodeState = .available(.beforeLock(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeDeleteStatePublisher(failedAttemptsLockIntervals: [TimeInterval]) -> AnyPublisher<MobileAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsLockIntervals.count
        let remaining = attemptsBeforeDeleteLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsLockIntervals: failedAttemptsLockIntervals) {
            let timer = LockedTimer(
                type: .beforeDelete(remaining: remaining),
                duration: lockDuration
            )
            return makeLockedTimerPublisher(timer: timer)
        } else {
            let state: MobileAccessCodeState = .available(.beforeDelete(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: [TimeInterval]) -> AnyPublisher<MobileAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsLockIntervals.count
        let remaining = attemptsBeforeWarningLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsLockIntervals: failedAttemptsLockIntervals) {
            let timer = LockedTimer(
                type: .beforeWarning(remaining: remaining),
                duration: lockDuration
            )
            return makeLockedTimerPublisher(timer: timer)
        } else {
            let state: MobileAccessCodeState = .available(.beforeWarning(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func calculateAccessCodeLockDuration(failedAttemptsLockIntervals: [TimeInterval]) -> TimeInterval? {
        let lockTime = failedAttemptsLockIntervals.last

        if let lockTime {
            let remainingTime = lockTime - currentUptime

            // If device restart is detected, check timeout delta from current uptime.
            guard remainingTime <= lockedTimeout else {
                let timeoutDelta = lockedTimeout - currentUptime
                return timeoutDelta > 0 ? timeoutDelta : nil
            }

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

private extension CommonMobileAccessCodeManager {
    func makeLockedTimerPublisher(timer: LockedTimer) -> AnyPublisher<MobileAccessCodeState, Never> {
        let endUptime = currentUptime + timer.duration
        return makeCountdownPublisher(endUptime: endUptime)
            .withWeakCaptureOf(self)
            .map { manager, countdown in
                manager.makeAccessCodeState(countdown: countdown, timerType: timer.type)
            }
            .eraseToAnyPublisher()
    }

    func makeAccessCodeState(countdown: TimeInterval, timerType: LockedTimerType) -> MobileAccessCodeState {
        let isTimeoutFinished = (countdown == 0)

        if isTimeoutFinished {
            switch timerType {
            case .beforeWarning(let remaining):
                return .available(.beforeWarning(remaining: remaining))
            case .beforeDelete(let remaining):
                return .available(.beforeDelete(remaining: remaining))
            }
        } else {
            switch timerType {
            case .beforeWarning(let remaining):
                return .locked(.beforeWarning(remaining: remaining, timeout: countdown))
            case .beforeDelete(let remaining):
                return .locked(.beforeDelete(remaining: remaining, timeout: countdown))
            }
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

extension CommonMobileAccessCodeManager: MobileAccessCodeManager {
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
                return makeBeforeWarningTimerCommand(
                    remaining: attemptsBeforeWarningLimit - attemptsToLockLimit,
                    duration: lockedTimeout
                )
            }

        case .beforeWarning(let lastRemaining):
            let remaining = lastRemaining - 1

            if remaining > 0 {
                return makeBeforeWarningTimerCommand(
                    remaining: remaining,
                    duration: lockedTimeout
                )
            } else {
                return makeBeforeDeleteTimerCommand(
                    remaining: attemptsBeforeDeleteLimit - attemptsBeforeWarningLimit,
                    duration: lockedTimeout
                )
            }

        case .beforeDelete(let lastRemaining):
            let remaining = lastRemaining - 1

            if remaining > 0 {
                return makeBeforeDeleteTimerCommand(
                    remaining: remaining,
                    duration: lockedTimeout
                )
            } else {
                return makeUnavailableCommand(state: .needsToDelete)
            }
        }
    }
}

// MARK: - Commands maker

private extension CommonMobileAccessCodeManager {
    // Available commands

    func makeAvailableBeforeLockCommand(remaining: Int) -> StateCommand {
        let state: MobileAccessCodeState = .available(.beforeLock(remaining: remaining))
        return .update(state)
    }

    func makeAvailableBeforeWarningCommand(remaining: Int) -> StateCommand {
        let state: MobileAccessCodeState = .available(.beforeWarning(remaining: remaining))
        return .update(state)
    }

    func makeAvailableBeforeDeleteCommand(remaining: Int) -> StateCommand {
        let state: MobileAccessCodeState = .available(.beforeDelete(remaining: remaining))
        return .update(state)
    }

    // Timer commands

    func makeBeforeWarningTimerCommand(remaining: Int, duration: TimeInterval) -> StateCommand {
        let timer = LockedTimer(
            type: .beforeWarning(remaining: remaining),
            duration: duration
        )
        return .startTimer(timer)
    }

    func makeBeforeDeleteTimerCommand(remaining: Int, duration: TimeInterval) -> StateCommand {
        let timer = LockedTimer(
            type: .beforeDelete(remaining: remaining),
            duration: duration
        )
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

extension CommonMobileAccessCodeManager {
    func getWrongAccessCodeStore() -> MobileWrongAccessCodeStore {
        do {
            let store = try storageManager.getWrongAccessCodeStore(userWalletId: userWalletId)
            return store
        } catch {
            AppLogger.error("Failed to get wrong access code storage", error: error)
            let lockIntervals: [TimeInterval] = .init(repeating: currentLockInterval, count: attemptsToLockLimit)
            return MobileWrongAccessCodeStore(lockIntervals: lockIntervals)
        }
    }

    func storeWrongAccessCode() {
        storageManager.storeWrongAccessCode(
            userWalletId: userWalletId,
            lockInterval: currentLockInterval,
            replaceLast: false
        )
    }

    func cleanWrongAccessCodeStore() {
        storageManager.removeWrongAccessCode(userWalletId: userWalletId)
    }
}

// MARK: - Types

private extension CommonMobileAccessCodeManager {
    enum StateCommand {
        case load
        case update(MobileAccessCodeState)
        case startTimer(LockedTimer)
    }

    struct LockedTimer {
        let type: LockedTimerType
        let duration: TimeInterval
    }

    enum LockedTimerType {
        case beforeWarning(remaining: Int)
        case beforeDelete(remaining: Int)
    }
}
