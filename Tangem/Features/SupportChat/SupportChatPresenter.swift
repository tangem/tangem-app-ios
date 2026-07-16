//
//  SupportChatPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class SupportChatPresenter: ObservableObject {
    @Published var supportTypeSelectionModel: SupportTypeSelectionModel?
    @Published var supportChatViewModel: SupportChatViewModel?

    func showSelection(emailAction: @escaping () -> Void, chatInput: SupportChatInputModel) {
        supportTypeSelectionModel = SupportTypeSelectionModel(
            emailAction: { [weak self] in self?.dismissSelection { emailAction() } },
            chatAction: { [weak self] in self?.dismissSelection { self?.showChat(input: chatInput) } }
        )
    }

    func showChat(input: SupportChatInputModel) {
        Analytics.log(.settingsButtonOpenChat)
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    /// Dismiss the selection sheet, then present email/chat after a short delay — presenting
    /// before the sheet is gone would tear the new screen down with the dismissing sheet.
    private func dismissSelection(then action: @escaping () -> Void) {
        supportTypeSelectionModel = nil
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Constants.selectionDismissDelay))
            action()
        }
    }
}

private extension SupportChatPresenter {
    enum Constants {
        static let selectionDismissDelay: TimeInterval = 0.6
    }
}

// MARK: - SupportChatPresenting

protocol SupportChatPresenting: AnyObject {
    var supportChatPresenter: SupportChatPresenter { get }
}

extension SupportChatPresenting {
    func openSupportTypeSelection(emailAction: @escaping () -> Void, chatInput: SupportChatInputModel) {
        supportChatPresenter.showSelection(emailAction: emailAction, chatInput: chatInput)
    }
}

// MARK: - Presentation

extension View {
    func supportChatPresentation(_ presenter: SupportChatPresenter) -> some View {
        modifier(SupportChatPresentationModifier(presenter: presenter))
    }
}

private struct SupportChatPresentationModifier: ViewModifier {
    @ObservedObject var presenter: SupportChatPresenter

    func body(content: Content) -> some View {
        content
            .navigation(item: $presenter.supportChatViewModel) {
                SupportChatView(viewModel: $0)
            }
            .sheet(item: $presenter.supportTypeSelectionModel) {
                SupportTypeSelectionView(model: $0)
            }
    }
}
