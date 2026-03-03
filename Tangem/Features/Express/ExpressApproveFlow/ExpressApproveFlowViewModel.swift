//
//  ExpressApproveFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets
import TangemFoundation
import BlockchainSdk

protocol ExpressApproveFlowRoutable: AnyObject {
    func openFeeTokenSelection()
}

protocol ExpressApproveCoordinating: ExpressApproveFlowRoutable, ExpressApproveRoutable {}

final class ExpressApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel, ExpressApproveCoordinating {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Published

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private let approveViewModel: ExpressApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel?
    private let feeSelectorInteractor: CommonFeeSelectorInteractor?
    private let allowanceService: (any AllowanceService)?
    private let approveAmount: Decimal?
    private let spender: String?
    private weak var coordinatorRouter: ExpressApproveRoutable?

    private var recalculateApproveFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        approveViewModel: ExpressApproveViewModel,
        router: ExpressApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel?,
        feeSelectorInteractor: CommonFeeSelectorInteractor?,
        allowanceService: (any AllowanceService)?,
        approveAmount: Decimal? = nil,
        spender: String? = nil
    ) {
        coordinatorRouter = router

        self.feeSelectorViewModel = feeSelectorViewModel
        self.feeSelectorInteractor = feeSelectorInteractor
        self.allowanceService = allowanceService
        self.approveAmount = approveAmount
        self.spender = spender
        self.approveViewModel = approveViewModel

        state = .approve(approveViewModel)

        self.approveViewModel.setCoordinator(self)
        bind()
    }

    deinit {
        recalculateApproveFeeTask?.cancel()
    }
}

// MARK: - ExpressApproveFlowRoutable

extension ExpressApproveFlowViewModel: ExpressApproveFlowRoutable {
    func openFeeTokenSelection() {
        presentFeeTokenSelection()
    }
}

// MARK: - ExpressApproveRoutable (Proxy to coordinator)

extension ExpressApproveFlowViewModel: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        coordinatorRouter?.didSendApproveTransaction()
    }

    func userDidCancel() {
        recalculateApproveFeeTask?.cancel()
        approveViewModel.overriddenApproveData = nil
        coordinatorRouter?.userDidCancel()
    }

    func openLearnMore() {
        coordinatorRouter?.openLearnMore()
    }
}

// MARK: - FeeSelectorTokensRoutable

extension ExpressApproveFlowViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        feeSelectorInteractor?.userDidSelect(feeTokenItem: tokenFeeProvider.feeTokenItem)
        state = .approve(approveViewModel)
    }
}

// MARK: - Private

private extension ExpressApproveFlowViewModel {
    func bind() {
        approveViewModel.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)

        approveViewModel.$errorAlert
            .compactMap { $0 }
            .sink { [weak self] in self?.alert = $0 }
            .store(in: &bag)

        guard let feeSelectorInteractor else { return }

        feeSelectorInteractor.selectedTokenFeeProviderPublisher
            .dropFirst()
            .sink { [weak self] provider in
                self?.recalculateApproveFee(for: provider)
            }
            .store(in: &bag)

        approveViewModel.$selectedAction
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self,
                      let provider = self.feeSelectorInteractor?.selectedTokenFeeProvider else { return }
                recalculateApproveFee(for: provider)
            }
            .store(in: &bag)

        feeSelectorInteractor.selectedTokenFeeProviderPublisher
            .dropFirst()
            .flatMapLatest { $0.statePublisher }
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .error(let error):
                    recalculateApproveFeeTask?.cancel()
                    approveViewModel.applyFee(.override(.failure(error)))
                case .unavailable:
                    recalculateApproveFeeTask?.cancel()
                    approveViewModel.applyFee(.override(.failure(TokenFeeProviderError.providerUnavailable)))
                case .idle, .loading, .available:
                    break
                }
            }
            .store(in: &bag)
    }

    func recalculateApproveFee(for provider: any TokenFeeProvider) {
        recalculateApproveFeeTask?.cancel()

        guard let allowanceService, let approveAmount, let spender else { return }

        let feeTokenItem = provider.feeTokenItem
        let approvePolicy = approveViewModel.selectedAction
        approveViewModel.updateSelectedFeeTokenItem(feeTokenItem)
        approveViewModel.applyFee(.override(.loading))

        recalculateApproveFeeTask = runTask(in: self) { viewModel in
            do {
                let state: AllowanceState

                if feeTokenItem.isToken {
                    state = try await allowanceService.gaslessAllowanceState(
                        amount: approveAmount,
                        spender: spender,
                        approvePolicy: approvePolicy,
                        feeTokenItem: feeTokenItem
                    )
                } else {
                    state = try await allowanceService.allowanceState(
                        amount: approveAmount,
                        spender: spender,
                        approvePolicy: approvePolicy
                    )
                }

                let approveData: ApproveTransactionData? = if case .permissionRequired(let data) = state { data } else { nil }

                await runOnMain {
                    viewModel.approveViewModel.overriddenApproveData = approveData
                    viewModel.handleAllowanceState(state, feeTokenItem: feeTokenItem)
                }
            } catch is CancellationError {
            } catch {
                await runOnMain {
                    viewModel.approveViewModel.applyFee(.override(.failure(error)))
                }
            }
        }
    }

    func handleAllowanceState(_ state: AllowanceState, feeTokenItem: TokenItem) {
        switch state {
        case .permissionRequired(let data):
            let fee = ApproveInputFee(feeTokenItem: feeTokenItem, fee: data.fee)
            approveViewModel.applyFee(.override(.success(fee)))
        case .approveTransactionInProgress:
            assertionFailure("Approve transaction already in progress — fee recalculation is irrelevant")
            approveViewModel.applyFee(.reset)
        case .enoughAllowance:
            assertionFailure("Allowance is already sufficient — approve sheet should not have been presented")
            approveViewModel.applyFee(.reset)
        }
    }
}

// MARK: - Public

extension ExpressApproveFlowViewModel {
    func presentFeeTokenSelection() {
        guard let feeSelectorViewModel else { return }

        feeSelectorViewModel.setup(router: self)
        state = .feeTokenSelection(feeSelectorViewModel)
    }

    func dismissFeeTokenSelection() {
        state = .approve(approveViewModel)
    }
}

// MARK: - ViewState

extension ExpressApproveFlowViewModel {
    enum ViewState: Equatable, Hashable {
        case approve(ExpressApproveViewModel)
        case feeTokenSelection(FeeSelectorTokensViewModel)

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.approve, .approve), (.feeTokenSelection, .feeTokenSelection):
                return true
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .approve:
                hasher.combine(0)
            case .feeTokenSelection:
                hasher.combine(1)
            }
        }

        var title: String {
            switch self {
            case .approve:
                return Localization.swappingPermissionHeader
            case .feeTokenSelection:
                return Localization.feeSelectorChooseTokenTitle
            }
        }

        var subtitle: AttributedString? {
            switch self {
            case .approve(let viewModel):
                return makeSubtitle(text: viewModel.subtitle)
            case .feeTokenSelection:
                let text = Localization.feeSelectorChooseTokenDescription(Localization.commonLearnMore)
                return makeSubtitle(text: text)
            }
        }

        var headerButtonAction: HeaderButtonAction {
            switch self {
            case .approve:
                return .close
            case .feeTokenSelection:
                return .back
            }
        }

        private func makeSubtitle(text: String) -> AttributedString {
            var attr = AttributedString(text)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            if let range = attr.range(of: Localization.commonLearnMore) {
                attr.replaceSubrange(range, with: AttributedString(""))
            }

            return attr
        }
    }

    enum HeaderButtonAction: Equatable, Hashable {
        case close
        case back
    }
}
