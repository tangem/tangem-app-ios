//
//  ExpressApproveFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets
import TangemFoundation

protocol ExpressApproveFlowRoutable: AnyObject {
    func openFeeTokenSelection()
    func didTapInfoButton()
}

protocol ExpressApproveCoordinating: ExpressApproveFlowRoutable, ExpressApproveRoutable {}

final class ExpressApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel, ExpressApproveCoordinating {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Published

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessNetworkManager: GaslessTransactionsNetworkManager

    private let approveViewModel: ExpressApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel
    private let feeSelectorInteractor: CommonFeeSelectorInteractor
    private let allowanceService: (any AllowanceService)?
    private let approveAmount: Decimal?
    private let spender: String?
    private let overrideFeeSubject: CurrentValueSubject<LoadingResult<ApproveInputFee, any Error>?, Never>

    private let balanceConverter = BalanceConverter()

    private weak var coordinatorRouter: ExpressApproveRoutable?

    private var recalculateApproveFeeTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        approveViewModel: ExpressApproveViewModel,
        router: ExpressApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel,
        feeSelectorInteractor: CommonFeeSelectorInteractor,
        allowanceService: (any AllowanceService)?,
        approveAmount: Decimal? = nil,
        spender: String? = nil,
        overrideFeeSubject: CurrentValueSubject<LoadingResult<ApproveInputFee, any Error>?, Never> = .init(nil)
    ) {
        coordinatorRouter = router

        self.feeSelectorViewModel = feeSelectorViewModel
        self.feeSelectorInteractor = feeSelectorInteractor
        self.allowanceService = allowanceService
        self.approveAmount = approveAmount
        self.spender = spender
        self.overrideFeeSubject = overrideFeeSubject
        self.approveViewModel = approveViewModel

        state = .approve(approveViewModel)

        self.approveViewModel.setCoordinator(self)
        bind()
    }
}

// MARK: - ExpressApproveFlowRoutable

extension ExpressApproveFlowViewModel: ExpressApproveFlowRoutable {
    func didTapInfoButton() {
        alert = AlertBinder(title: Localization.swappingApproveInformationTitle, message: Localization.swappingApproveInformationText)
    }

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
        coordinatorRouter?.userDidCancel()
    }

    func openLearnMore() {
        coordinatorRouter?.openLearnMore()
    }
}

// MARK: - FeeSelectorTokensRoutable

extension ExpressApproveFlowViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        feeSelectorInteractor.userDidSelect(feeTokenItem: tokenFeeProvider.feeTokenItem)
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

        Publishers.CombineLatest(
            feeSelectorInteractor.selectedTokenFeeProviderPublisher,
            approveViewModel.$selectedAction.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] provider, _ in
            self?.recalculateApproveFee(for: provider)
        }
        .store(in: &bag)
    }

    func recalculateApproveFee(for provider: any TokenFeeProvider) {
        recalculateApproveFeeTask?.cancel()

        guard let allowanceService, let approveAmount, let spender else { return }

        let feeTokenItem = provider.feeTokenItem

        guard feeTokenItem.isToken else {
            overrideFeeSubject.send(nil)
            return
        }

        let approvePolicy = approveViewModel.selectedAction
        overrideFeeSubject.send(.loading)

        recalculateApproveFeeTask = runTask(in: self) { viewModel in
            do {
                guard let feeToken = feeTokenItem.token else {
                    throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
                }

                guard let feeRecipientAddress = await viewModel.gaslessNetworkManager.feeRecipientAddress else {
                    throw TokenFeeLoaderError.missingFeeRecipientAddress
                }

                guard let feeAssetId = feeToken.id else {
                    throw TokenFeeLoaderError.feeTokenIdNotFound
                }

                let nativeAssetId = feeTokenItem.blockchain.coinId
                let nativeToFeeTokenRate = try await viewModel.balanceConverter.cryptoToCryptoRate(
                    from: nativeAssetId,
                    to: feeAssetId
                )

                let state = try await allowanceService.gaslessAllowanceState(
                    amount: approveAmount,
                    spender: spender,
                    approvePolicy: approvePolicy,
                    feeToken: feeToken,
                    feeRecipientAddress: feeRecipientAddress,
                    nativeToFeeTokenRate: nativeToFeeTokenRate
                )

                await runOnMain {
                    viewModel.handleAllowanceState(state, feeTokenItem: feeTokenItem)
                }
            } catch is CancellationError {
                // Task was cancelled due to a new fee token selection
            } catch {
                await runOnMain {
                    viewModel.overrideFeeSubject.send(.failure(error))
                }
            }
        }
    }

    func handleAllowanceState(_ state: AllowanceState, feeTokenItem: TokenItem) {
        switch state {
        case .permissionRequired(let data):
            let fee = ApproveInputFee(feeTokenItem: feeTokenItem, fee: data.fee)
            overrideFeeSubject.send(.success(fee))
        case .approveTransactionInProgress, .enoughAllowance:
            overrideFeeSubject.send(nil)
        }
    }
}

// MARK: - Public

extension ExpressApproveFlowViewModel {
    func presentFeeTokenSelection() {
        feeSelectorViewModel.setup(router: self)
        state = .feeTokenSelection(feeSelectorViewModel)
    }

    func dismissFeeTokenSelection() {
        state = .approve(approveViewModel)
    }

    func openLearnMoreURL() {
        coordinatorRouter?.openLearnMore()
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
                // Temporarily replace with an empty string because the final URL isn't ready yet
                attr.replaceSubrange(range, with: AttributedString(""))
//                attr[range].foregroundColor = Colors.Text.accent
//                attr[range].link = URL(string: " ")
            }

            return attr
        }
    }

    enum HeaderButtonAction: Equatable, Hashable {
        case close
        case back
    }
}
