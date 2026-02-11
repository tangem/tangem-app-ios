//
//  SendFeeSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI
import Foundation
import TangemLocalization
import TangemAssets
import TangemMacro
import TangemAccessibilityIdentifiers

protocol SendFeeSelectorRoutable: FeeSelectorRoutable {
    func openFeeSelectorLearnMoreURL(_ url: URL)
}

final class SendFeeSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published

    @Published
    private(set) var state: ViewState

    @Published
    private(set) var feeSelectorViewModel: FeeSelectorViewModel

    @Published
    private(set) var isMainButtonEnabled = false

    // MARK: - Dependencies

    private weak var router: SendFeeSelectorRoutable?

    // MARK: - Properties

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(feeSelectorViewModel: FeeSelectorViewModel, router: SendFeeSelectorRoutable) {
        self.feeSelectorViewModel = feeSelectorViewModel
        self.router = router

        state = ViewState(from: feeSelectorViewModel.viewState)
        bind()
    }

    // MARK: - Navigation

    func userDidTapConfirmButton() {
        feeSelectorViewModel.userDidTapConfirmButton()
    }

    func userDidTapDismissButton() {
        feeSelectorViewModel.userDidTapDismissButton()
    }

    func userDidTapBackButton() {
        feeSelectorViewModel.userDidTapBackButton()
    }

    func openURL() {
        router?.openFeeSelectorLearnMoreURL(state.content.learnMoreURL)
    }

    // MARK: - Private Implementation

    private func bind() {
        feeSelectorViewModel.$viewState
            .receiveOnMain()
            .map(ViewState.init)
            .assign(to: &$state)

        feeSelectorViewModel
            .selectedFeeStateWithCoveragePublisher
            .receiveOnMain()
            .map { feeState, coverage in
                feeState.isAvailable && coverage.isCovered
            }
            .assign(to: &$isMainButtonEnabled)
    }
}

// MARK: - State

extension SendFeeSelectorViewModel {
    enum ViewState: Equatable, Hashable {
        case summary(Content)
        case tokens(Content)
        case fees(Content)

        init(from feeSelectorState: FeeSelectorViewModel.ViewState) {
            switch feeSelectorState {
            case .summary:
                self = .summary(
                    Content(
                        title: Localization.commonNetworkFeeTitle,
                        description: AttributedString(""),
                        headerButtonAction: .close,
                        learnMoreURL: URL(string: "https://tangem.com/en/blog/post/yield-mode")!,
                        isSingleOptionMode: false
                    )
                )

            case .tokens:
                let text = Localization.feeSelectorChooseTokenDescription(Localization.commonLearnMore)
                self = .tokens(
                    Content(
                        title: Localization.feeSelectorChooseTokenTitle,
                        description: Content.makeDescription(text: text),
                        headerButtonAction: .back,
                        learnMoreURL: URL(string: "https://tangem.com/en/blog/post/yield-mode")!,
                        isSingleOptionMode: false
                    )
                )

            case .fees(_, let isFeesOnlyOption):
                let text = Localization.feeSelectorChooseSpeedDescription(Localization.commonLearnMore)
                self = .fees(
                    Content(
                        title: Localization.feeSelectorChooseSpeedTitle,
                        description: Content.makeDescription(text: text),
                        headerButtonAction: isFeesOnlyOption ? .close : .back,
                        learnMoreURL: URL(string: "https://tangem.com/en/blog/post/yield-mode")!,
                        isSingleOptionMode: isFeesOnlyOption
                    )
                )
            }
        }

        var content: Content {
            switch self {
            case .summary(let content), .fees(let content), .tokens(let content):
                return content
            }
        }

        var description: AttributedString? {
            switch self {
            case .summary:
                return nil
            case .fees(let content), .tokens(let content):
                return content.description
            }
        }

        var titleAccessibilityIdentifier: String? {
            switch self {
            case .fees:
                return FeeAccessibilityIdentifiers.feeSelectorChooseSpeedTitle
            case .summary, .tokens:
                return nil
            }
        }
    }
}

extension SendFeeSelectorViewModel {
    struct Content: Equatable, Hashable {
        let title: String
        let description: AttributedString
        let headerButtonAction: SendFeeSelectorViewModel.ViewState.HeaderButtonAction
        let learnMoreURL: URL
        let isSingleOptionMode: Bool

        static func makeDescription(text: String) -> AttributedString {
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
}

extension SendFeeSelectorViewModel.ViewState {
    @CaseFlagable
    enum HeaderButtonAction {
        case close
        case back
    }
}
