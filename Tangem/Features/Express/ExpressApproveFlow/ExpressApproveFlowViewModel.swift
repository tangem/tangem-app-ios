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

    private let approveViewModel: ExpressApproveViewModel
    private let feeSelectorViewModel: FeeSelectorTokensViewModel?
    private let feeSelectorInteractor: CommonFeeSelectorInteractor?
    private weak var feeSelectorOutput: (any FeeSelectorOutput)?
    private weak var coordinatorRouter: ExpressApproveRoutable?

    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(
        input: ExpressApproveViewModel.Input,
        router: ExpressApproveRoutable,
        feeSelectorViewModel: FeeSelectorTokensViewModel? = nil,
        feeSelectorInteractor: CommonFeeSelectorInteractor? = nil,
        feeSelectorOutput: (any FeeSelectorOutput)? = nil
    ) {
        coordinatorRouter = router
        self.feeSelectorViewModel = feeSelectorViewModel
        self.feeSelectorInteractor = feeSelectorInteractor
        self.feeSelectorOutput = feeSelectorOutput
        
        // [REDACTED_TODO_COMMENT]
        approveViewModel = ExpressApproveViewModel(input: input)
        state = .approve(approveViewModel)
        approveViewModel.setCoordinator(self)
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
        guard let interactor = feeSelectorInteractor else { return }

        interactor.userDidSelect(feeTokenItem: tokenFeeProvider.feeTokenItem)

        feeSelectorOutput?.userDidFinishSelection(
            feeTokenItem: tokenFeeProvider.feeTokenItem,
            feeOption: interactor.selectedTokenFeeOption
        )

        state = .approve(approveViewModel)
    }
}

// MARK: - Public

extension ExpressApproveFlowViewModel {
    func presentFeeTokenSelection() {
        guard let viewModel = feeSelectorViewModel else { return }

        viewModel.setup(router: self)
        state = .feeTokenSelection(viewModel)
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
