//
//  WrappedHoldToConfirmButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

// MARK: - View

extension WrappedHoldToConfirmButton: View {
    private var isIOS18OrNewer: Bool {
        if #available(iOS 18.0, *) {
            true
        } else {
            false
        }
    }

    var body: some View {
        content
            .onChange(of: title, perform: viewModel.onTitleChanged)
            .onChange(of: isLoading, perform: viewModel.onLoadingChanged)
            .onChange(of: isDisabled, perform: viewModel.onDisabledChanged)
            .onChange(of: configuration, perform: viewModel.onConfigurationChanged)
            .onChange(of: action, perform: viewModel.onActionChanged)
    }
}

// MARK: - Views calculations

private extension WrappedHoldToConfirmButton {
    var isHoldingState: Bool {
        viewModel.state == .holding
    }

    var isLoadingState: Bool {
        viewModel.state == .loading
    }

    var acceptsTouches: Bool {
        switch viewModel.state {
        case .idle, .holding, .canceled: !viewModel.isDisabled
        case .confirmed, .loading: false
        }
    }

    var progressAnimation: Animation {
        let duration = isHoldingState ? viewModel.holdDuration : 0
        return .linear(duration: duration)
    }

    func progressWidth(in proxy: GeometryProxy) -> CGFloat {
        [.holding, .confirmed].contains(viewModel.state) ? proxy.size.width : 0
    }

    var scaleAnimation: Animation {
        let duration = isHoldingState ? viewModel.holdDuration : 0.2
        return .easeOut(duration: duration)
    }

    var scaleFactor: CGFloat {
        isHoldingState ? 0.95 : 1
    }
}

// MARK: - Subviews

private extension WrappedHoldToConfirmButton {
    var content: some View {
        button
            .overlay(progressBar)
            .overlay(touchArea)
            .shake(
                trigger: viewModel.shakeTrigger,
                duration: viewModel.shakeDuration,
                shakesPerUnit: 1,
                travelDistance: 10
            )
            // For iOS versions earlier than 18 there is issue using `scaleEffect` together
            // with UIKit gestures: touch `ended` and `cancelled` events stop being delivered.
            .if(isIOS18OrNewer) {
                $0.scaleEffect(scaleFactor)
            }
            .animation(scaleAnimation, value: viewModel.state)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(viewModel.labelTitle))
            .accessibilityHint(Text(configuration.cancelTitle))
            .accessibilityValue(isLoadingState ? Localization.commonInProgress : "")
            .accessibilityAddTraits(.isButton)
            .disabled(viewModel.isDisabled)
    }

    var button: some View {
        Button(label: viewModel.labelTitle, accessibilityLabel: nil, action: {})
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .loading(.spinner(if: isLoadingState))
            .disabled(viewModel.isDisabled)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .transaction { $0.animation = nil }
    }

    @ViewBuilder
    var touchArea: some View {
        if acceptsTouches {
            Color.clear.onTouches(perform: viewModel.onTouches)
        }
    }

    var progressBar: some View {
        GeometryReader { proxy in
            Color.Tangem.Fill.Neutral.quaternary
                .opacity(0.15)
                .frame(width: progressWidth(in: proxy))
                .animation(progressAnimation, value: viewModel.state)
        }
        .clipShape(Capsule())
        .allowsHitTesting(false)
    }
}
