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

protocol SendFeeSelectorRoutable: FeeSelectorRoutable {
    func openFeeSelectorLearnMoreURL(_ url: URL)
}

final class SendFeeSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published

    @Published
    private(set) var state: ViewState

    @Published
    private(set) var feeSelectorViewModel: FeeSelectorViewModel

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

    func userDidTapDismissButton() {
        feeSelectorViewModel.userDidTapDismissButton()
    }

    func userDidTapBackButton() {
        feeSelectorViewModel.userDidTapBackButton()
    }

    func openURL() {
        router?.openFeeSelectorLearnMoreURL(state.learnMoreURL)
    }

    // MARK: - Private Implementation

    private func bind() {
        feeSelectorViewModel.$viewState
            .receiveOnMain()
            .map(ViewState.init)
            .assign(to: \.state, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
}

// MARK: - State

extension SendFeeSelectorViewModel {
    struct ViewState: Equatable {
        let title: String
        let description: AttributedString
        let headerButtonAction: HeaderButtonAction
        var learnMoreURL: URL

        init(from feeSelectorState: FeeSelectorViewModel.ViewState) {
            switch feeSelectorState {
            case .summary:
                title = Localization.commonNetworkFeeTitle
                description = AttributedString("")
                headerButtonAction = .close
                learnMoreURL = URL(string: "https://tangem.com/en/blog/post/yield-mode")!

            case .tokens:
                title = Localization.feeSelectorChooseTokenTitle
                let text = Localization.feeSelectorChooseTokenDescription(Localization.commonLearnMore)
                description = ViewState.makeDescription(text: text)
                headerButtonAction = .back
                learnMoreURL = URL(string: "https://tangem.com/en/blog/post/yield-mode")!

            case .fees:
                title = Localization.feeSelectorChooseSpeedTitle
                let text = Localization.feeSelectorChooseSpeedDescription(Localization.commonLearnMore)
                description = ViewState.makeDescription(text: text)
                headerButtonAction = .back
                learnMoreURL = URL(string: "https://tangem.com/en/blog/post/yield-mode")!
            }
        }

        private static func makeDescription(text: String) -> AttributedString {
            var attr = AttributedString(text)
            attr.font = Fonts.Regular.footnote
            attr.foregroundColor = Colors.Text.tertiary

            if let range = attr.range(of: Localization.commonLearnMore) {
                attr[range].foregroundColor = Colors.Text.accent
                if let emptyUrl = URL(string: " ") {
                    attr[range].link = emptyUrl
                }
            }

            return attr
        }
    }
}

extension SendFeeSelectorViewModel {
    @CaseFlagable
    enum HeaderButtonAction {
        case close
        case back
    }
}
