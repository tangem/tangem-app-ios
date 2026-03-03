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
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemAssets
import BlockchainSdk

final class ExpressApproveViewModel: ObservableObject {
    // MARK: - ViewState

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
    private(set) var selectedFeeTokenItem: TokenItem
    /// Approve data computed from a fee-token change in the flow VM, passed explicitly to `sendApproveTransaction`.
    var overriddenApproveData: ApproveTransactionData?
    private let feeFormatter: FeeFormatter
    private let approveViewModelInput: ApproveViewModelInput
    private weak var coordinator: ExpressApproveCoordinating?

    private var bag: Set<AnyCancellable> = []

    private let initialFee: LoadingResult<ApproveInputFee, any Error>
    private let _currentFee: CurrentValueSubject<LoadingResult<ApproveInputFee, any Error>, Never>

    init(input: Input) {
        feeFormatter = input.feeFormatter
        approveViewModelInput = input.approveViewModelInput

        tokenItem = input.settings.tokenItem
        selectedFeeTokenItem = input.settings.feeTokenItem

        let initialFee = input.approveViewModelInput.approveFeeValue
        self.initialFee = initialFee
        _currentFee = CurrentValueSubject(initialFee)

        selectedAction = input.settings.selectedPolicy
        subtitle = input.settings.subtitle
        feeFooterText = input.settings.feeFooterText
        tangemIconProvider = input.settings.tangemIconProvider

        menuRowViewModel = .init(
            title: Localization.givePermissionRowsAmount(input.settings.tokenItem.currencySymbol),
            actions: [.unlimited, .specified]
        )

        feeCompactViewModel = FeeCompactViewModel(canEditFee: input.supportFeeSelection, showsLeadingIcon: false, showsRoundedBackground: false, feeFormatter: feeFormatter)
        updateView(state: _currentFee.value)
        bind()
    }

    func setCoordinator(_ coordinator: ExpressApproveCoordinating) {
        self.coordinator = coordinator
    }

    func updateSelectedFeeTokenItem(_ tokenItem: TokenItem) {
        selectedFeeTokenItem = tokenItem
    }

    func applyFee(_ action: ApproveFeeAction) {
        switch action {
        case .reset:
            _currentFee.send(initialFee)
        case .override(let value):
            _currentFee.send(value)
        }
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

extension ExpressApproveViewModel {
    @MainActor
    func didSendApproveTransaction() {
        coordinator?.didSendApproveTransaction()
    }
}

// MARK: - Private

private extension ExpressApproveViewModel {
    var approveFeeTokenPublisher: AnyPublisher<TokenFee, Never> {
        _currentFee
            .withWeakCaptureOf(self)
            .map { viewModel, result -> TokenFee in
                switch result {
                case .success(let fee):
                    return TokenFee(option: .market, tokenItem: fee.feeTokenItem, value: .success(fee.fee))
                case .loading:
                    return TokenFee(option: .market, tokenItem: viewModel.selectedFeeTokenItem, value: .loading)
                case .failure(let error):
                    return TokenFee(option: .market, tokenItem: viewModel.selectedFeeTokenItem, value: .failure(error))
                }
            }
            .eraseToAnyPublisher()
    }

    func bind() {
        feeCompactViewModel?.bind(
            selectedFeePublisher: approveFeeTokenPublisher,
            supportFeeSelectionPublisher: Empty(completeImmediately: true).eraseToAnyPublisher()
        )

        _currentFee
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
        runTask(in: self) { viewModel in
            do {
                try await viewModel.approveViewModelInput.sendApproveTransaction(overriddenApproveData: viewModel.overriddenApproveData)
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
    enum ApproveFeeAction {
        case reset
        case override(LoadingResult<ApproveInputFee, any Error>)
    }

    struct Input {
        let settings: Settings
        let feeFormatter: FeeFormatter
        let approveViewModelInput: ApproveViewModelInput
        var supportFeeSelection: Bool = false
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
