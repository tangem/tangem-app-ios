//
//  RatingFeedbackBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct RatingFeedbackBottomSheetView: View {
    @ObservedObject var viewModel: RatingFeedbackBottomSheetViewModel

    @FocusState private var isFocused: Bool
    @State private var isKeyboardShown = false
    @State private var actionAfterKeyboardHides: Action?

    var body: some View {
        VStack(spacing: 0) {
            starIcon
                .padding(.top, 52)

            title
                .padding(.top, 24)

            divider
                .padding(.top, 20)

            feedbackInput
                .padding(.top, 20)
                .padding(.horizontal, 16)

            footer
                .padding(.top, 24)
                .padding([.horizontal, .bottom], 16)
        }
        .overlay(alignment: .topTrailing) {
            header
        }
        .background(Colors.Background.tertiary)
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
            config.sheetFrameUpdateAnimation = .contentFrameUpdate
            config.animatesContentWithKeyboard = true
        }
        .task(openKeyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardShown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            isKeyboardShown = false
            runActionAfterKeyboardHides()
        }
        .onDisappear {
            viewModel.dismiss()
        }
    }
}

private extension RatingFeedbackBottomSheetView {
    // MARK: - Private logic

    @MainActor
    @Sendable
    func openKeyboard() async {
        do {
            try await Task.sleep(for: Constants.keyboardOpeningDelay)
        } catch {
            return
        }

        UIApplication.shared.makeOverlayWindowKey()
        isFocused = true
    }

    func perform(_ action: Action) {
        guard isKeyboardShown else {
            run(action)
            return
        }

        actionAfterKeyboardHides = action
        isFocused = false
    }

    func runActionAfterKeyboardHides() {
        guard let action = actionAfterKeyboardHides else { return }

        actionAfterKeyboardHides = nil
        run(action)
    }

    func run(_ action: Action) {
        switch action {
        case .close:
            viewModel.dismiss()
        case .submit:
            Task { await viewModel.submit() }
        }
    }
}

private extension RatingFeedbackBottomSheetView {
    // MARK: - Subviews

    var header: some View {
        NavigationBarButton.close(action: { perform(.close) })
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 16)
            .padding(.top, 16)
    }

    var starIcon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.iconAccentYellow.opacity(0.1))
                .frame(width: 56, height: 56)

            Assets.DesignSystem.ratingStarEmpty.image
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(DesignSystem.Color.iconAccentYellow)
        }
    }

    var title: some View {
        Text(Localization.swappingRateFeedbackTitle)
            .style(Fonts.Bold.title2, color: Colors.Text.primary1)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
    }

    var divider: some View {
        Rectangle()
            .fill(Colors.Stroke.primary)
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    var feedbackInput: some View {
        TextField(
            text: $viewModel.feedbackText,
            prompt: Text(Localization.swappingRateFeedbackPlaceholder)
                .font(Fonts.Regular.body)
                .foregroundColor(Colors.Text.tertiary),
            axis: .vertical
        ) {}
            .font(Fonts.Regular.body)
            .foregroundColor(Colors.Text.primary1)
            .padding(12)
            .frame(height: 88, alignment: .topLeading)
            .background(Colors.Field.focused)
            .cornerRadius(14)
            .focused($isFocused)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            .accessibilityIdentifier(RatingAccessibilityIdentifiers.feedbackInput)
    }

    var footer: some View {
        MainButton(
            title: Localization.swappingRateFeedbackSubmit,
            isLoading: viewModel.isSubmitting,
            isDisabled: !viewModel.isSubmitEnabled
        ) {
            perform(.submit)
        }
        .accessibilityIdentifier(RatingAccessibilityIdentifiers.submitFeedbackButton)
    }
}

// MARK: - Action

private extension RatingFeedbackBottomSheetView {
    enum Action {
        case close
        case submit
    }
}

// MARK: - Constants

private extension RatingFeedbackBottomSheetView {
    enum Constants {
        static let contentFrameUpdateDuration: TimeInterval = 0.5
        static let keyboardOpeningDelay: Duration = .seconds(contentFrameUpdateDuration) + .milliseconds(100)
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(
        .easeInOutRefined,
        duration: RatingFeedbackBottomSheetView.Constants.contentFrameUpdateDuration
    )
}

// MARK: - Keyboard support for FloatingSheet

private extension UIApplication {
    /// Makes the overlay window (PassThroughWindow) key so the keyboard can appear.
    /// Needed because FloatingSheet lives in a separate window that is not key by default.
    @MainActor
    func makeOverlayWindowKey() {
        let overlayWindow = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0 is PassThroughWindow }

        overlayWindow?.makeKey()
    }
}

// MARK: - Previews

#Preview {
    RatingFeedbackBottomSheetView(
        viewModel: RatingFeedbackBottomSheetViewModel(
            rating: .four,
            onSubmit: { _, _ in /* no-op */ },
            onDismiss: {}
        )
    )
}
