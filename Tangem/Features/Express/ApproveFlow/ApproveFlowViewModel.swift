//
//  ApproveFlowViewModel.swift
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
import TangemMacro

protocol ApproveFlowRoutable: AnyObject {
    func openFeeTokenSelection()
}

protocol ApproveCoordinating: ApproveFlowRoutable, ApproveRoutable {}

final class ApproveFlowViewModel: ObservableObject, FloatingSheetContentViewModel, ApproveCoordinating {
    // MARK: - ViewState

    @Published private(set) var state: ViewState

    // MARK: - Published

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    let confirmTransactionPolicy: ConfirmTransactionPolicy

    private let approveViewModel: ApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel?
    private let interactor: ApproveInteractor
    private weak var coordinatorRouter: ApproveRoutable?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        approveViewModel: ApproveViewModel,
        router: ApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel?,
        interactor: ApproveInteractor,
        confirmTransactionPolicy: ConfirmTransactionPolicy
    ) {
        coordinatorRouter = router

        self.feeSelectorViewModel = feeSelectorViewModel
        self.interactor = interactor
        self.approveViewModel = approveViewModel
        self.confirmTransactionPolicy = confirmTransactionPolicy

        state = .approve(approveViewModel)

        self.approveViewModel.setCoordinator(self)
        bind()
    }
}

// MARK: - ApproveFlowRoutable

extension ApproveFlowViewModel: ApproveFlowRoutable {
    func openFeeTokenSelection() {
        presentFeeTokenSelection()
    }
}

// MARK: - ApproveRoutable (Proxy to coordinator)

extension ApproveFlowViewModel: ApproveRoutable {
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

extension ApproveFlowViewModel: FeeSelectorTokensRoutable {
    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        interactor.userDidSelectFeeToken(tokenFeeProvider: tokenFeeProvider)
        state = .approve(approveViewModel)
    }
}

// MARK: - Private

private extension ApproveFlowViewModel {
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
    }
}

// MARK: - Navigation Helpers

extension ApproveFlowViewModel {
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

extension ApproveFlowViewModel {
    @RawCaseName
    enum ViewState: Equatable, Hashable {
        case approve(ApproveViewModel)
        case feeTokenSelection(FeeSelectorTokensViewModel)

        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            lhs.rawCaseValue == rhs.rawCaseValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(rawCaseValue)
        }

        var title: String {
            switch self {
            case .approve(let viewModel):
                return viewModel.title
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

        var showsButton: Bool {
            switch self {
            case .approve: return true
            case .feeTokenSelection: return false
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

        /// "Learn More" is stripped from the header subtitle — it is shown as a tappable link in the body instead
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
