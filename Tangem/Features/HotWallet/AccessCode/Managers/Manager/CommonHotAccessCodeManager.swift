//
//  CommonHotAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonHotAccessCodeManager {
    private let storageManager = CommonHotAccessCodeStorageManager()
    private let stateSubject = CurrentValueSubject<HotAccessCodeState, Never>(.available(.normal))
    private let stateCommandSubject = PassthroughSubject<StateCommand, Never>()

    private var attemptsToLockLimit: Int { configuration.attemptsToLockLimit }
    private var attemptsBeforeWarningLimit: Int { configuration.attemptsBeforeWarningLimit }
    private var attemptsBeforeDeleteLimit: Int { configuration.attemptsBeforeDeleteLimit }
    private var lockedTimeout: TimeInterval { configuration.lockedTimeout }

    private var currentUptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private let userWalletModel: UserWalletModel
    private let configuration: HotAccessCodeConfiguration
    private weak var delegate: CommonHotAccessCodeManagerDelegate?

    private var bag: Set<AnyCancellable> = []
    private var timersBag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        configuration: HotAccessCodeConfiguration = .default,
        delegate: CommonHotAccessCodeManagerDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.configuration = configuration
        self.delegate = delegate
        bind()
        getInitialState()
    }
}

// MARK: - Private methods

private extension CommonHotAccessCodeManager {
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

private extension CommonHotAccessCodeManager {
    func makeStatePublisher(command: StateCommand) -> AnyPublisher<HotAccessCodeState, Never> {
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

    func makeStatePublisher(store: HotWrongAccessCodeStore) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsLockIntervals = store.lockIntervals
        let failedAttemptsCount = failedAttemptsLockIntervals.count

        guard failedAttemptsCount != 0 else {
            let state: HotAccessCodeState = .available(.normal)
            return Just(state).eraseToAnyPublisher()
        }

        if failedAttemptsCount >= attemptsBeforeDeleteLimit {
            return Just(.unavailable).eraseToAnyPublisher()
        } else if failedAttemptsCount >= attemptsBeforeWarningLimit {
            return makeBeforeDeleteStatePublisher(failedAttemptsLockIntervals: failedAttemptsLockIntervals)
        } else if failedAttemptsCount >= attemptsToLockLimit {
            return makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: failedAttemptsLockIntervals)
        } else {
            let remaining = attemptsToLockLimit - failedAttemptsCount
            let state: HotAccessCodeState = .available(.beforeLock(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeDeleteStatePublisher(failedAttemptsLockIntervals: [TimeInterval]) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsLockIntervals.count
        let remaining = attemptsBeforeDeleteLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsLockIntervals: failedAttemptsLockIntervals) {
            let timer = LockedTimer(
                type: .beforeDelete(remaining: remaining),
                duration: lockDuration
            )
            return makeLockedTimerPublisher(timer: timer)
        } else {
            let state: HotAccessCodeState = .available(.beforeDelete(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeWarningStatePublisher(failedAttemptsLockIntervals: [TimeInterval]) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsLockIntervals.count
        let remaining = attemptsBeforeWarningLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsLockIntervals: failedAttemptsLockIntervals) {
            let timer = LockedTimer(
                type: .beforeWarning(remaining: remaining),
                duration: lockDuration
            )
            return makeLockedTimerPublisher(timer: timer)
        } else {
            let state: HotAccessCodeState = .available(.beforeWarning(remaining: remaining))
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

private extension CommonHotAccessCodeManager {
    func makeLockedTimerPublisher(timer: LockedTimer) -> AnyPublisher<HotAccessCodeState, Never> {
        let endUptime = currentUptime + timer.duration
        return makeCountdownPublisher(endUptime: endUptime)
            .withWeakCaptureOf(self)
            .map { manager, countdown in
                manager.makeAccessCodeState(countdown: countdown, timerType: timer.type)
            }
            .eraseToAnyPublisher()
    }

    func makeAccessCodeState(countdown: TimeInterval, timerType: LockedTimerType) -> HotAccessCodeState {
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

// MARK: - HotAccessCodeManager

extension CommonHotAccessCodeManager: HotAccessCodeManager {
    var statePublisher: AnyPublisher<HotAccessCodeState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func validate(accessCode: String) throws {
        switch stateSubject.value {
        case .available(let availableState):
            let isValid = isValid(accessCode: accessCode)

            let command: StateCommand
            if isValid {
                handleAccessCodeSuccessful()
                command = makeValidCommand()
            } else {
                storeWrongAccessCodeAttempt()
                command = makeInvalidCommand(availableState: availableState)
            }
            stateCommandSubject.send(command)

        case .locked:
            throw HotAccessCodeError.validationLocked

        case .valid, .unavailable:
            break
        }
    }

    private func makeInvalidCommand(availableState: HotAccessCodeState.AvailableState) -> StateCommand {
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
                handleAccessCodeDelete()
                return makeUnavailableCommand()
            }
        }
    }
}

// MARK: - Commands maker

private extension CommonHotAccessCodeManager {
    // Available commands

    func makeAvailableBeforeLockCommand(remaining: Int) -> StateCommand {
        let state: HotAccessCodeState = .available(.beforeLock(remaining: remaining))
        return .update(state)
    }

    func makeAvailableBeforeWarningCommand(remaining: Int) -> StateCommand {
        let state: HotAccessCodeState = .available(.beforeWarning(remaining: remaining))
        return .update(state)
    }

    func makeAvailableBeforeDeleteCommand(remaining: Int) -> StateCommand {
        let state: HotAccessCodeState = .available(.beforeDelete(remaining: remaining))
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

    func makeUnavailableCommand() -> StateCommand {
        return .update(.unavailable)
    }

    func makeValidCommand() -> StateCommand {
        return .update(.valid)
    }
}

// MARK: - Validation

extension CommonHotAccessCodeManager {
    func isValid(accessCode: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        accessCode == "111111"
    }
}

// MARK: - Storing

extension CommonHotAccessCodeManager {
    func getWrongAccessCodeStore() -> HotWrongAccessCodeStore {
        storageManager.getWrongAccessCodeStore(userWalletModel: userWalletModel)
    }

    func storeWrongAccessCodeAttempt() {
        let lockInterval = currentUptime + lockedTimeout
        storageManager.storeWrongAccessCode(userWalletModel: userWalletModel, lockInterval: lockInterval)
    }
}

// MARK: - Handlers

extension CommonHotAccessCodeManager {
    func handleAccessCodeSuccessful() {
        storageManager.clearWrongAccessCode(userWalletModel: userWalletModel)
        delegate?.handleAccessCodeSuccessful(userWalletModel: userWalletModel)
    }

    func handleAccessCodeDelete() {
        storageManager.clearWrongAccessCode(userWalletModel: userWalletModel)
        delegate?.handleAccessCodeDelete(userWalletModel: userWalletModel)
    }
}

// MARK: - Types

private extension CommonHotAccessCodeManager {
    enum StateCommand {
        case load
        case update(HotAccessCodeState)
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
