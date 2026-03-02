//
//  ExpressApproveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI
import UIKit
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemAssets

final class ExpressApproveViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - ViewState

    @Published var subtitle: String

    @Published var menuRowViewModel: DefaultMenuRowViewModel<BSDKApprovePolicy>?
    @Published var selectedAction: BSDKApprovePolicy
    @Published var feeCompactViewModel: FeeCompactViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    let tangemIconProvider: TangemIconProvider
    let feeFooterText: String

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeFormatter: FeeFormatter
    private let approveViewModelInput: ApproveViewModelInput
    private weak var coordinator: ExpressApproveCoordinating?

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(input: Input) {
        feeFormatter = input.feeFormatter
        approveViewModelInput = input.approveViewModelInput

        tokenItem = input.settings.tokenItem
        feeTokenItem = input.settings.feeTokenItem

        selectedAction = input.settings.selectedPolicy
        subtitle = input.settings.subtitle
        feeFooterText = input.settings.feeFooterText
        tangemIconProvider = input.settings.tangemIconProvider

        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(input.settings.tokenItem.currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeCompactViewModel = FeeCompactViewModel(showsLeadingIcon: false, showsRoundedBackground: false, feeFormatter: feeFormatter)
        updateView(state: approveViewModelInput.approveFeeValue)
        bind()
    }

    func setCoordinator(_ coordinator: ExpressApproveCoordinating) {
        self.coordinator = coordinator
    }

    func didTapFeeSelectorButton() {
        coordinator?.openFeeTokenSelection()
    }

    func didTapInfoButton() {
        coordinator?.didTapInfoButton()
    }

    func didTapApprove() {
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

extension ExpressApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        coordinator?.didSendApproveTransaction()
    }
}

// MARK: - Private

private extension ExpressApproveViewModel {
    func bind() {
        approveViewModelInput.approveFeeValuePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, state in
                viewModel.updateView(state: state)
            }
            .store(in: &bag)

        $selectedAction
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, policy in
                viewModel.approveViewModelInput.updateApprovePolicy(policy: policy)
            }
            .store(in: &bag)
    }

    func updateView(state: LoadingResult<ApproveInputFee, any Error>) {
        switch state {
        case .success(let fee):
            updateFeeAmount(fee: fee)
            isLoading = false
            mainButtonIsDisabled = false
        case .loading:
            // [REDACTED_TODO_COMMENT]
            isLoading = true
            mainButtonIsDisabled = false
        case .failure(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fee: ApproveInputFee) {
        // [REDACTED_TODO_COMMENT]
        // For now, just keep the fee data
    }

    func sendApproveTransaction() {
        runTask(in: self) { viewModel in
            do {
                try await viewModel.approveViewModelInput.sendApproveTransaction()
                try await Task.sleep(for: .seconds(0.3))
                await viewModel.didSendApproveTransaction()
            } catch TransactionDispatcherResult.Error.userCancelled {
                // Do nothing
            } catch {
                ExpressLogger.error(error: error)
                await runOnMain {
                    viewModel.errorAlert = .init(title: Localization.commonError, message: error.localizedDescription)
                }
            }
        }
    }
}

extension ExpressApproveViewModel {
    struct Input {
        let settings: Settings
        let feeFormatter: FeeFormatter
        let approveViewModelInput: ApproveViewModelInput
    }

    struct Settings {
        let subtitle: String
        let feeFooterText: String
        let tokenItem: TokenItem
        let feeTokenItem: TokenItem
        let selectedPolicy: BSDKApprovePolicy
        let tangemIconProvider: TangemIconProvider
    }
}

extension BSDKApprovePolicy: @retroactive Identifiable {
    public var id: Int { hashValue }
}

extension BSDKApprovePolicy: DefaultMenuRowViewModelAction {
    public var title: String {
        switch self {
        case .specified:
            return Localization.givePermissionCurrentTransaction
        case .unlimited:
            return Localization.givePermissionUnlimited
        }
    }
}
