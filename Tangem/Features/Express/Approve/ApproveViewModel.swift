//
//  ApproveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemAssets
import BlockchainSdk

final class ApproveViewModel: ObservableObject {
    // MARK: - ViewState

    let title: String
    let subtitle: String

    @Published var menuRowViewModel: DefaultMenuRowViewModel<BSDKApprovePolicy>?
    @Published var selectedPolicy: BSDKApprovePolicy
    @Published var feeCompactViewModel: FeeCompactViewModel?

    @Published private(set) var state: State = .idle
    @Published var errorAlert: AlertBinder?

    let feeFooterText: String

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let feeFormatter: FeeFormatter
    private let interactor: ApproveInteractor
    private weak var coordinator: ApproveCoordinating?

    private let isUpdatingPolicySubject = CurrentValueSubject<Bool, Never>(false)
    private let isSendingSubject = CurrentValueSubject<Bool, Never>(false)
    private var policyUpdateTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(input: Input) {
        feeFormatter = input.feeFormatter
        interactor = input.interactor

        tokenItem = input.settings.tokenItem

        selectedPolicy = input.interactor.approveInteractorState.policy
        title = input.settings.title
        subtitle = input.settings.subtitle
        feeFooterText = input.settings.feeFooterText

        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(input.settings.tokenItem.currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeCompactViewModel = FeeCompactViewModel(
            canEditFee: input.supportFeeSelection,
            showsLeadingIcon: false,
            showsRoundedBackground: false,
            feeFormatter: feeFormatter
        )

        bind()
    }

    func setCoordinator(_ coordinator: ApproveCoordinating) {
        self.coordinator = coordinator
    }

    func didTapFeeSelectorButton() {
        coordinator?.openFeeTokenSelection()
    }

    func didTapApprove() {
        guard !state.isMainButtonDisabled else {
            return
        }

        sendApproveTransaction()
    }

    func didTapCancel() {
        Analytics.log(.swapButtonPermissionCancel)
        coordinator?.userDidCancel()
    }

    func didTapLearnMore() {
        if case .token(let token, _) = tokenItem {
            Analytics.log(
                event: .swapButtonPermissionLearnMore,
                params: [
                    .blockchain: tokenItem.blockchain.displayName,
                    .token: token.name,
                ]
            )
        }
        coordinator?.openLearnMore()
    }

    func approveInfoSubtitle() -> AttributedString {
        var attr = AttributedString(Localization.givePermissionPolicyTypeFooter + " " + Localization.commonLearnMore)
        attr.font = Fonts.Regular.footnote
        attr.foregroundColor = Colors.Text.tertiary

        if let range = attr.range(of: Localization.commonLearnMore) {
            attr[range].foregroundColor = Colors.Text.accent
            attr[range].link = URL(string: " ")
        }

        return attr
    }
}

// MARK: - Navigation

extension ApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        coordinator?.didSendApproveTransaction()
    }
}

// MARK: - Private

private extension ApproveViewModel {
    func bind() {
        let approveFeePublisher = interactor.approveFeePublisher
            .receiveOnMain()

        feeCompactViewModel?.bind(
            selectedFeePublisher: approveFeePublisher.eraseToAnyPublisher(),
            supportFeeSelectionPublisher: Empty(completeImmediately: true).eraseToAnyPublisher()
        )

        Publishers.CombineLatest3(approveFeePublisher, isUpdatingPolicySubject, isSendingSubject)
            .map { tokenFee, isUpdatingPolicy, isSending in
                State(tokenFee: tokenFee, isUpdatingPolicy: isUpdatingPolicy, isSending: isSending)
            }
            .assign(to: &$state)

        approveFeePublisher
            .compactMap(\.value.error)
            .withWeakCaptureOf(self)
            .sink { viewModel, error in
                viewModel.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            }
            .store(in: &bag)

        $selectedPolicy
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, policy in
                viewModel.updateApprovePolicy(policy)
            }
            .store(in: &bag)
    }

    func updateApprovePolicy(_ policy: BSDKApprovePolicy) {
        policyUpdateTask?.cancel()

        guard policy != interactor.approveInteractorState.policy else {
            isUpdatingPolicySubject.send(false)
            return
        }

        isUpdatingPolicySubject.send(true)
        policyUpdateTask = runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.interactor.updateApprovePolicy(policy: policy)
                try Task.checkCancellation()
                viewModel.isUpdatingPolicySubject.send(false)
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                ExpressLogger.error(error: error)
                viewModel.isUpdatingPolicySubject.send(false)
                viewModel.selectedPolicy = viewModel.interactor.approveInteractorState.policy
                viewModel.errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            }
        }
    }

    func sendApproveTransaction() {
        isSendingSubject.send(true)

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.interactor.sendApproveTransaction()
                try await Task.sleep(for: .seconds(0.3))
                viewModel.didSendApproveTransaction()
            } catch TransactionDispatcherResult.Error.userCancelled {
                viewModel.isSendingSubject.send(false)
            } catch {
                ExpressLogger.error(error: error)
                viewModel.isSendingSubject.send(false)
                viewModel.errorAlert = .init(title: Localization.commonError, message: error.localizedDescription)
            }
        }
    }
}

// MARK: - State

extension ApproveViewModel {
    enum State: Equatable {
        case idle
        case loadingFee
        case feeUnavailable
        case updatingPolicy
        case sending

        init(tokenFee: TokenFee, isUpdatingPolicy: Bool, isSending: Bool) {
            switch (isSending, isUpdatingPolicy, tokenFee.value) {
            case (true, _, _):
                self = .sending
            case (_, true, _):
                self = .updatingPolicy
            case (_, _, .success):
                self = .idle
            case (_, _, .loading):
                self = .loadingFee
            case (_, _, .failure):
                self = .feeUnavailable
            }
        }

        var isLoading: Bool {
            switch self {
            case .loadingFee, .updatingPolicy, .sending:
                return true
            case .idle, .feeUnavailable:
                return false
            }
        }

        var isMainButtonDisabled: Bool {
            switch self {
            case .feeUnavailable, .updatingPolicy, .sending:
                return true
            case .idle, .loadingFee:
                return false
            }
        }

        var isContentLocked: Bool {
            self == .sending
        }
    }
}

extension ApproveViewModel {
    struct Input {
        let settings: Settings
        let feeFormatter: FeeFormatter
        let interactor: ApproveInteractor
        var supportFeeSelection: Bool = false
    }

    struct Settings {
        let title: String
        let subtitle: String
        let feeFooterText: String
        let tokenItem: TokenItem
    }
}
