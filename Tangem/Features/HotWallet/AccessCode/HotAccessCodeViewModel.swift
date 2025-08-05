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

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private let manager: HotAccessCodeManager
    private let unlockMode: UnlockMode?

    private var bag: Set<AnyCancellable> = []

    init(manager: HotAccessCodeManager, unlockMode: UnlockMode? = nil) {
        self.manager = manager
        self.unlockMode = unlockMode
        bind()
        setupUnlockItem()
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
                viewModel.process(state: state)
            }
            .store(in: &bag)
    }

    func validate(accessCode: String) {
        guard accessCode.count == accessCodeLength else {
            return
        }
        try? manager.validate(accessCode: accessCode)
    }
}

// MARK: - Unlocking

private extension HotAccessCodeViewModel {
    func setupUnlockItem() {
        guard
            case .biometry(let item) = unlockMode,
            BiometricsUtil.isAvailable
        else {
            return
        }

        unlockItem = UnlockItem(
            title: Localization.welcomeUnlock(BiometricAuthorizationUtils.biometryType.name),
            action: { [weak self] in
                self?.unlockWithBiometry(item: item)
            }
        )
    }

    func unlockWithBiometry(item: BiometryUnlockModeItem) {
        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                let userWalletModel = try await viewModel.userWalletRepository.unlock(with: .biometrics(context))

                await runOnMain {
                    viewModel.openMain(with: userWalletModel)
                }
            } catch {
                viewModel.incomingActionManager.discardIncomingAction()
            }
        }
    }
}

// MARK: - State processing

private extension HotAccessCodeViewModel {
    func process(state: HotAccessCodeState) {
        switch state {
        case .available(let availableState):
            processAvailableState(availableState)
        case .locked(let lockedState):
            processLockedState(lockedState)
        case .valid:
            processValidState()
        case .unavailable:
            proccessUnavailableState()
        }
    }

    func processAvailableState(_ state: HotAccessCodeState.AvailableState) {
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

    func processLockedState(_ state: HotAccessCodeState.LockedState) {
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

    func processValidState() {
        isAccessCodeAvailable = false
        isSuccessful = true
        infoState = nil
    }

    func proccessUnavailableState() {
        isAccessCodeAvailable = false
        isSuccessful = false
        infoState = nil
    }

    func clearAccessCode() {
        accessCode = .empty
    }
}

// MARK: - Navigation

private extension HotAccessCodeViewModel {
    func openMain(with model: UserWalletModel) {
        switch unlockMode {
        case .biometry(let item):
            item.openMain(model)
        case .none:
            break
        }
    }
}

// MARK: - Types

extension HotAccessCodeViewModel {
    enum UnlockMode {
        case biometry(BiometryUnlockModeItem)
    }

    struct BiometryUnlockModeItem {
        let openMain: (UserWalletModel) -> Void
    }

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
