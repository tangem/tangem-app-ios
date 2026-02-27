//
//  WrappedHoldToConfirmButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

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

    var labelTextColor: Color {
        viewModel.isDisabled ? Colors.Text.disabled : Colors.Text.primary2
    }

    var backgroundColor: Color {
        viewModel.isDisabled ? Colors.Button.disabled : Colors.Button.primary
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
        label
            .background(background)
            .overlay(overlay)
            // For iOS versions earlier than 18 there is issue using `scaleEffect` together
            // with UIKit gestures: touch `ended` and `cancelled` events stop being delivered.
            .if(isIOS18OrNewer) {
                $0.scaleEffect(scaleFactor)
            }
            .animation(scaleAnimation, value: viewModel.state)
    }

    var label: some View {
        Text(viewModel.labelTitle)
            .transaction { $0.animation = nil }
            .style(Fonts.Bold.callout, color: labelTextColor)
            .shake(
                trigger: viewModel.shakeTrigger,
                duration: viewModel.shakeDuration,
                shakesPerUnit: 1,
                travelDistance: 10
            )
            .frame(height: 46)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var overlay: some View {
        switch viewModel.state {
        case .idle, .holding, .canceled:
            if viewModel.isDisabled {
                EmptyView()
            } else {
                Color.clear.onTouches(perform: viewModel.onTouches)
            }
        case .loading:
            loading
        default:
            EmptyView()
        }
    }

    var background: some View {
        ZStack(alignment: .leading) {
            backgroundColor
            progressBar
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    var loading: some View {
        ZStack {
            backgroundColor
            ProgressView().tint(Colors.Text.primary2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    var progressBar: some View {
        GeometryReader { proxy in
            Color.Tangem.Fill.Neutral.quaternary
                .opacity(0.15)
                .frame(width: progressWidth(in: proxy))
                .animation(progressAnimation, value: viewModel.state)
        }
    }
}
