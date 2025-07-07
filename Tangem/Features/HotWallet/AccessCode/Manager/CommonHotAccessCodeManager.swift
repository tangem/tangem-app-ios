//
//  CommonHotAccessCodeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonHotAccessCodeManager {
    private let stateSubject = CurrentValueSubject<HotAccessCodeState, Never>(.available(.normal))
    private let stateCommandSubject = PassthroughSubject<StateCommand, Never>()

    private let storage: HotAccessCodeStorage
    private let validator: HotAccessCodeValidator
    private let configuration: HotAccessCodeConfiguration
    private weak var delegate: CommonHotAccessCodeManagerDelegate?

    private var attemptsToLockLimit: Int { configuration.attemptsToLockLimit }
    private var attemptsBeforeWarningLimit: Int { configuration.attemptsBeforeWarningLimit }
    private var attemptsBeforeDeleteLimit: Int { configuration.attemptsBeforeDeleteLimit }
    private var lockedTimeout: TimeInterval { configuration.lockedTimeout }

    private var bag: Set<AnyCancellable> = []
    private var timersBag: Set<AnyCancellable> = []

    init(
        storage: HotAccessCodeStorage,
        validator: HotAccessCodeValidator,
        configuration: HotAccessCodeConfiguration = .default,
        delegate: CommonHotAccessCodeManagerDelegate
    ) {
        self.storage = storage
        self.validator = validator
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
            let store = storage.getWrongAccessCodeStore()
            return makeStatePublisher(store: store)

        case .update(let state):
            return Just(state).eraseToAnyPublisher()

        case .startTimer(let timer):
            return makeLockedTimerPublisher(timer: timer)
        }
    }

    func makeStatePublisher(store: HotWrongAccessCodeStore) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsDates = store.dates
        let failedAttemptsCount = failedAttemptsDates.count

        guard failedAttemptsCount != 0 else {
            let state: HotAccessCodeState = .available(.normal)
            return Just(state).eraseToAnyPublisher()
        }

        if failedAttemptsCount >= attemptsBeforeDeleteLimit {
            return Just(.unavailable).eraseToAnyPublisher()
        } else if failedAttemptsCount >= attemptsBeforeWarningLimit {
            return makeBeforeDeleteStatePublisher(failedAttemptsDates: failedAttemptsDates)
        } else if failedAttemptsCount >= attemptsToLockLimit {
            return makeBeforeWarningStatePublisher(failedAttemptsDates: failedAttemptsDates)
        } else {
            let remaining = attemptsToLockLimit - failedAttemptsCount
            let state: HotAccessCodeState = .available(.beforeLock(remaining: remaining))
            return Just(state).eraseToAnyPublisher()
        }
    }

    func makeBeforeDeleteStatePublisher(failedAttemptsDates: [Date]) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsDates.count
        let remaining = attemptsBeforeDeleteLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsDates: failedAttemptsDates) {
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

    func makeBeforeWarningStatePublisher(failedAttemptsDates: [Date]) -> AnyPublisher<HotAccessCodeState, Never> {
        let failedAttemptsCount = failedAttemptsDates.count
        let remaining = attemptsBeforeWarningLimit - failedAttemptsCount

        if let lockDuration = calculateAccessCodeLockDuration(failedAttemptsDates: failedAttemptsDates) {
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

    func calculateAccessCodeLockDuration(failedAttemptsDates: [Date]) -> TimeInterval? {
        let lastFailedAttemptDate = failedAttemptsDates.sorted(by: <).last

        if let lastFailedAttemptDate {
            let elapsedTime = Date().timeIntervalSince(lastFailedAttemptDate)

            if elapsedTime > lockedTimeout {
                return nil
            } else {
                return lockedTimeout - elapsedTime
            }
        } else {
            return nil
        }
    }
}

// MARK: - Timers

private extension CommonHotAccessCodeManager {
    func makeLockedTimerPublisher(timer: LockedTimer) -> AnyPublisher<HotAccessCodeState, Never> {
        let beginDate = Date()
        let endDate = beginDate.addingTimeInterval(timer.duration)

        return makeEverySecondPublisher(beginDate: beginDate, endDate: endDate)
            .withWeakCaptureOf(self)
            .map { manager, date in
                manager.makeAccessCodeState(
                    timerDate: date,
                    endDate: endDate,
                    timerType: timer.type
                )
            }
            .eraseToAnyPublisher()
    }

    func makeAccessCodeState(
        timerDate: Date,
        endDate: Date,
        timerType: LockedTimerType
    ) -> HotAccessCodeState {
        let remainingTimeout = endDate.timeIntervalSince(timerDate)
        let isTimeoutFinished = remainingTimeout <= 0

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
                return .locked(.beforeWarning(remaining: remaining, timeout: remainingTimeout))
            case .beforeDelete(let remaining):
                return .locked(.beforeDelete(remaining: remaining, timeout: remainingTimeout))
            }
        }
    }

    func makeEverySecondPublisher(beginDate: Date, endDate: Date) -> AnyPublisher<Date, Never> {
        Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .prepend(beginDate)
            .prefix { currentDate in
                currentDate <= endDate
            }
            .append(endDate)
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
            let isValid = validator.isValid(accessCode: accessCode)

            let command: StateCommand
            if isValid {
                storage.clearWrongAccessCodeStore()
                command = makeValidCommand()
            } else {
                storage.storeWrongAccessCodeAttempt(date: Date())
                command = makeInvalidCommand(availableState: availableState)
            }
            stateCommandSubject.send(command)

        case .locked:
            throw HotAccessCodeError.hotAccessCodeStateLocked

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
                storage.clearWrongAccessCodeStore()
                delegate?.needDeleteWallet()
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

// MARK: - Errors

enum HotAccessCodeError: LocalizedError {
    case hotAccessCodeStateLocked
}
