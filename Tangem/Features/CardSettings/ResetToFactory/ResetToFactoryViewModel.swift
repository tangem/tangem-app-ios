//
//  ResetToFactoryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ConfirmationDialogViewModel

final class ResetToFactoryViewModel: ObservableObject {
    @Published var warnings: [Warning] = []
    @Published var confirmationDialog: ConfirmationDialogViewModel?
    @Published var alert: AlertBinder?

    var actionButtonIsEnabled: Bool {
        warnings.allConforms(\.isAccepted)
    }

    var message: String {
        if hasBackupCards {
            return Localization.resetCardWithBackupToFactoryMessage
        } else {
            return Localization.resetCardWithoutBackupToFactoryMessage
        }
    }

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var hasBackupCards: Bool {
        input.backupCardsCount > 0
    }

    private var isPaeraCustomer: Bool {
        AppSettings.shared.tangemPayIsPaeraCustomer[
            input.userWalletId.stringValue
        ] ?? false
    }

    private let input: ResetToFactoryViewModel.Input
    private let resetUtil: ResetToFactoryUtil
    private weak var coordinator: ResetToFactoryViewRoutable?

    private var bag = Set<AnyCancellable>()

    init(input: ResetToFactoryViewModel.Input, coordinator: ResetToFactoryViewRoutable) {
        self.input = input
        self.coordinator = coordinator
        resetUtil = ResetToFactoryUtilBuilder().build(
            backupCardsCount: input.backupCardsCount,
            cardInteractor: input.cardInteractor
        )

        bind()
        setupView()
    }

    deinit {
        AppLogger.debug(self)
    }

    func didTapMainButton() {
        let resetButton = ConfirmationDialogViewModel.Button(
            title: Localization.cardSettingsActionSheetReset,
            role: .destructive,
            action: { [weak self] in
                self?.resetCardToFactory()
            }
        )

        confirmationDialog = ConfirmationDialogViewModel(
            title: Localization.cardSettingsActionSheetTitle,
            buttons: [
                resetButton,
                ConfirmationDialogViewModel.Button.cancel,
            ]
        )
    }

    func toggleWarning(warningType: WarningType) {
        guard let index = warnings.firstIndex(where: { $0.type == warningType }) else {
            return
        }

        warnings[index].isAccepted.toggle()
    }
}

private extension ResetToFactoryViewModel {
    func bind() {
        resetUtil.alertPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, alert in
                viewModel.alert = alert
            }
            .store(in: &bag)
    }

    func setupView() {
        warnings.append(Warning(isAccepted: false, type: .accessToCard))

        if hasBackupCards {
            warnings.append(Warning(isAccepted: false, type: .accessCodeRecovery))
        }

        if isPaeraCustomer {
            warnings.append(Warning(isAccepted: false, type: .tangemPay))
        }
    }

    func resetCardToFactory() {
        resetUtil.resetToFactory(onDidFinish: weakify(self, forFunction: ResetToFactoryViewModel.resetDidFinish))
    }

    func resetDidFinish() {
        userWalletRepository.delete(userWalletId: input.userWalletId)
        coordinator?.dismiss()
    }
}

extension ResetToFactoryViewModel {
    struct Warning: Identifiable, Hashable {
        var id: Int { hashValue }

        var isAccepted: Bool
        let type: WarningType
    }

    enum WarningType: String, CaseIterable, Hashable {
        case accessToCard
        case tangemPay
        case accessCodeRecovery

        var title: String {
            switch self {
            case .accessToCard:
                return Localization.resetCardToFactoryCondition1
            case .tangemPay:
                return Localization.tangempayFactorySettingsWarningTitle
            case .accessCodeRecovery:
                return Localization.resetCardToFactoryCondition2
            }
        }
    }
}
