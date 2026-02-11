//
//  ExpressApproveViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import UIKit
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class ExpressApproveViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var subtitle: String

    @Published var menuRowViewModel: DefaultMenuRowViewModel<BSDKApprovePolicy>?
    @Published var selectedAction: BSDKApprovePolicy
    @Published var feeRowViewModel: DefaultRowViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    let tangemIconProvider: TangemIconProvider
    let feeFooterText: String

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let feeFormatter: FeeFormatter
    private let approveViewModelInput: ApproveViewModelInput
    private weak var coordinator: ExpressApproveRoutable?

    private var didBecomeActiveNotificationCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        input: Input,
        coordinator: ExpressApproveRoutable
    ) {
        feeFormatter = input.feeFormatter
        approveViewModelInput = input.approveViewModelInput
        self.coordinator = coordinator

        tokenItem = input.settings.tokenItem

        selectedAction = input.settings.selectedPolicy
        subtitle = input.settings.subtitle
        feeFooterText = input.settings.feeFooterText
        tangemIconProvider = input.settings.tangemIconProvider

        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(input.settings.tokenItem.currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeRowViewModel = DefaultRowViewModel(title: Localization.commonNetworkFeeTitle, detailsType: .none)
        updateView(state: approveViewModelInput.approveFeeValue)
        bind()
    }

    func didTapInfoButton() {
        errorAlert = AlertBinder(
            title: Localization.swappingApproveInformationTitle,
            message: Localization.swappingApproveInformationText
        )
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
            feeRowViewModel?.update(detailsType: .loader)
            isLoading = true
            mainButtonIsDisabled = false
        case .failure(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func updateFeeAmount(fee: ApproveInputFee) {
        let formatted = feeFormatter.format(fee: fee.fee.amount.value, tokenItem: fee.feeTokenItem)
        feeRowViewModel?.update(detailsType: .text(formatted))
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
