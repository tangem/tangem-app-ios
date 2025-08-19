//
//  HotUnlockViewModel.swift
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
import TangemMobileWalletSdk
import class TangemSdk.BiometricsUtil

final class HotUnlockViewModel: ObservableObject {
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

    var actionPublisher: AnyPublisher<Action, Never> {
        actionSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let actionSubject: CurrentValueSubject<Action?, Never> = .init(nil)
    private var bag: Set<AnyCancellable> = []

    private let userWalletId: UserWalletId
    private let accessCodeManager: HotAccessCodeManager

    init(userWalletId: UserWalletId, accessCodeManager: HotAccessCodeManager) {
        self.userWalletId = userWalletId
        self.accessCodeManager = accessCodeManager
        bind()
        setupUnlockItemIfNeeded()
    }
}

// MARK: - Internal methods

extension HotUnlockViewModel {
    func onCloseTap() {
        onAction(.closed)
    }

    func onDisappear() {
        if actionSubject.value == nil {
            onAction(.dismissed)
        }
    }
}

// MARK: - Private methods

private extension HotUnlockViewModel {
    func bind() {
        $accessCode
            .dropFirst()
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, accessCode in
                viewModel.validate(accessCode: accessCode)
            }
            .store(in: &bag)

        accessCodeManager.statePublisher
            .receive(on: DispatchQueue.main)
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
        accessCodeManager.validate(accessCode: accessCode)
    }
}

// MARK: - Unlocking

private extension HotUnlockViewModel {
    func setupUnlockItemIfNeeded() {
        guard
            BiometricsUtil.isAvailable,
            AppSettings.shared.useBiometricAuthentication,
            CommonMobileWalletSdk().isBiometricsEnabled(for: userWalletId)
        else {
            return
        }

        unlockItem = UnlockItem(
            title: Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name),
            action: weakify(self, forFunction: HotUnlockViewModel.unlockWithBiometry)
        )
    }

    func unlockWithBiometry() {
        onAction(.biometricsRequest)
    }
}

// MARK: - State handlers

private extension HotUnlockViewModel {
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
        onAction(.accessCodeSuccessful(context))
    }

    func handleUnavailableState(_ state: HotAccessCodeState.UnavailableState) {
        isAccessCodeAvailable = false
        isSuccessful = false
        infoState = nil

        switch state {
        case .needsToDelete:
            onAction(.unavailableDueToDeletion)
        }
    }

    func clearAccessCode() {
        accessCode = .empty
    }
}

// MARK: - Callbacks

private extension HotUnlockViewModel {
    func onAction(_ action: Action) {
        actionSubject.send(action)
    }
}

// MARK: - Types

extension HotUnlockViewModel {
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

    enum Action {
        /// Access code was successfully entered.
        case accessCodeSuccessful(MobileWalletContext)
        /// Sent a request for biometrics.
        case biometricsRequest
        /// User tapped "Close" on the access code screen.
        case closed
        /// Access code screen was manually dismissed (e.g. swiped down).
        case dismissed
        /// Unavailable due wallet needs to be deleted.
        case unavailableDueToDeletion
    }
}
