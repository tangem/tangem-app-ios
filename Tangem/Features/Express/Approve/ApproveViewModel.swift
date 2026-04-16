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
    @Published var selectedAction: BSDKApprovePolicy
    @Published var feeCompactViewModel: FeeCompactViewModel?

    @Published var isLoading = false
    @Published var mainButtonIsDisabled = false
    @Published var errorAlert: AlertBinder?

    let tangemIconProvider: TangemIconProvider
    let feeFooterText: String

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let feeFormatter: FeeFormatter
    private let interactor: ApproveInteractor
    private weak var coordinator: ApproveCoordinating?

    private var bag: Set<AnyCancellable> = []

    init(input: Input) {
        feeFormatter = input.feeFormatter
        interactor = input.interactor

        tokenItem = input.settings.tokenItem

        selectedAction = input.settings.selectedPolicy
        title = input.settings.title
        subtitle = input.settings.subtitle
        feeFooterText = input.settings.feeFooterText
        tangemIconProvider = input.settings.tangemIconProvider

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

        approveFeePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, tokenFee in
                viewModel.updateView(tokenFee: tokenFee)
            }
            .store(in: &bag)

        $selectedAction
            .dropFirst()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, policy in
                viewModel.interactor.updateApprovePolicy(policy: policy)
            }
            .store(in: &bag)
    }

    func updateView(tokenFee: TokenFee) {
        switch tokenFee.value {
        case .success:
            isLoading = false
            mainButtonIsDisabled = false
        case .loading:
            isLoading = true
            mainButtonIsDisabled = false
        case .failure(let error):
            errorAlert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
            isLoading = false
            mainButtonIsDisabled = true
        }
    }

    func sendApproveTransaction() {
        mainButtonIsDisabled = true
        isLoading = true

        runTask(in: self) { viewModel in
            do {
                try await viewModel.interactor.sendApproveTransaction()
                try await Task.sleep(for: .seconds(0.3))
                await viewModel.didSendApproveTransaction()
            } catch TransactionDispatcherResult.Error.userCancelled {
                await runOnMain {
                    viewModel.mainButtonIsDisabled = false
                    viewModel.isLoading = false
                }
            } catch {
                ExpressLogger.error(error: error)
                await runOnMain {
                    viewModel.mainButtonIsDisabled = false
                    viewModel.isLoading = false
                    viewModel.errorAlert = .init(title: Localization.commonError, message: error.localizedDescription)
                }
            }
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
        let selectedPolicy: BSDKApprovePolicy = .specified
        let tangemIconProvider: TangemIconProvider
    }
}
