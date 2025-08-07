//
//  HotAccessCodeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemAssets
import TangemLocalization
import TangemHotSdk
import class TangemSdk.BiometricsUtil

final class HotAccessCodeViewModel: ObservableObject {
    @Published var accessCode: String = .empty

    @Published private(set) var unlockItem: UnlockItem?
    @Published private(set) var infoState: InfoState?
    @Published private(set) var isAccessCodeAvailable = true
    @Published private(set) var isSuccessful: Bool?

    let title = Localization.accessCodeCheckTitle
    let accessCodeLength: Int = 6

    var pinColor: Color {
        guard let isSuccessful, accessCode.count == accessCodeLength else {
            return Colors.Text.primary1
        }
        return isSuccessful ? Colors.Text.accent : Colors.Text.warning
    }

    var resultPublisher: AnyPublisher<HotAccessCodeResult, Never> {
        resultSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private let manager: HotAccessCodeManager
    private let useBiometrics: Bool

    private let resultSubject: CurrentValueSubject<HotAccessCodeResult?, Never> = .init(nil)
    private var bag: Set<AnyCancellable> = []

    init(manager: HotAccessCodeManager, useBiometrics: Bool) {
        self.manager = manager
        self.useBiometrics = useBiometrics
        bind()
        setupUnlockItemIfNeeded()
    }
}

// MARK: - Internal methods

extension HotAccessCodeViewModel {
    func onCloseTap() {
        onResult(.closed)
    }

    func onDisappear() {
        if resultSubject.value == nil {
            onResult(.dismissed)
        }
    }
}

// MARK: - Private methods

private extension HotAccessCodeViewModel {
    func bind() {
        $accessCode
            .dropFirst()
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, accessCode in
                viewModel.validate(accessCode: accessCode)
            }
            .store(in: &bag)

        manager.statePublisher
            .receive(on: RunLoop.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                viewModel.handle(state: state)
            }
            .store(in: &bag)
    }

    func validate(accessCode: String) {
        guard accessCode.count == accessCodeLength else {
            return
        }
        manager.validate(accessCode: accessCode)
    }
}

// MARK: - Unlocking

private extension HotAccessCodeViewModel {
    func setupUnlockItemIfNeeded() {
        // [REDACTED_TODO_COMMENT]
        guard useBiometrics, BiometricsUtil.isAvailable else {
            return
        }

        unlockItem = UnlockItem(
            title: Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name),
            action: weakify(self, forFunction: HotAccessCodeViewModel.unlockWithBiometry)
        )
    }

    func unlockWithBiometry() {
        onResult(.biometricsRequest)
    }
}

// MARK: - State handlers

private extension HotAccessCodeViewModel {
    func handle(state: HotAccessCodeState) {
        switch state {
        case .available(let availableState):
            handleAvailableState(availableState)
        case .locked(let lockedState):
            handleLockedState(lockedState)
        case .valid(let context):
            handleValidState(context: context)
        case .unavailable(let unavailableState):
            handleUnavailableState(unavailableState)
        }
    }

    func handleAvailableState(_ state: HotAccessCodeState.AvailableState) {
        clearAccessCode()
        isAccessCodeAvailable = true
        isSuccessful = nil

        switch state {
        case .normal:
            infoState = nil
        case .beforeLock(let remaining):
            let item = InfoWarningItem(title: Localization.accessCodeCheckWariningLock(remaining))
            infoState = .warning(item)
        case .beforeWarning:
            infoState = nil
        case .beforeDelete(let remaining):
            let item = InfoWarningItem(title: Localization.accessCodeCheckWariningDelete(remaining))
            infoState = .warning(item)
        }
    }

    func handleLockedState(_ state: HotAccessCodeState.LockedState) {
        isAccessCodeAvailable = false
        isSuccessful = false

        let timeoutInterval = switch state {
        case .beforeWarning(_, let timeout): timeout
        case .beforeDelete(_, let timeout): timeout
        }

        let seconds = Int(ceil(timeoutInterval))

        let item = InfoWarningItem(title: Localization.accessCodeCheckWariningWait(seconds))
        infoState = .warning(item)
    }

    func handleValidState(context: MobileWalletContext) {
        isAccessCodeAvailable = false
        isSuccessful = true
        infoState = nil
        onResult(.accessCodeSuccessfull(context))
    }

    func handleUnavailableState(_ state: HotAccessCodeState.UnavailableState) {
        isAccessCodeAvailable = false
        isSuccessful = false
        infoState = nil

        switch state {
        case .needsToDelete:
            onResult(.unavailableDueToDeletion)
        }
    }

    func clearAccessCode() {
        accessCode = .empty
    }
}

// MARK: - Result

private extension HotAccessCodeViewModel {
    func onResult(_ result: HotAccessCodeResult) {
        resultSubject.send(result)
    }
}

// MARK: - Types

extension HotAccessCodeViewModel {
    enum InfoState {
        case warning(InfoWarningItem)
    }

    struct InfoWarningItem {
        let title: String
    }

    struct UnlockItem {
        let title: String
        let action: () -> Void
    }
}
