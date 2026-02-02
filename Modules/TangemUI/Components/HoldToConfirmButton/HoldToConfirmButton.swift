//
//  HoldToConfirmButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct HoldToConfirmButton: View {
    typealias ViewModel = HoldToConfirmButtonModel

    @StateObject private var viewModel: ViewModel

    @Environment(\.isEnabled) private var isEnabled: Bool
    @Environment(\.holdToConfirmButtonIsLoading) private var isLoading: Bool

    private let title: String
    private let action: () -> Void

    public init(
        title: String,
        configuration: Configuration = .default,
        action: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ViewModel(configuration: configuration))
        self.title = title
        self.action = action
    }

    public var body: some View {
        content
            .onAppear {
                viewModel.onLoading(isLoading)
                viewModel.onEnabled(isEnabled)
            }
            .onChange(of: viewModel.confirmTrigger, perform: confirmAction)
            .onChange(of: isLoading, perform: viewModel.onLoading)
            .onChange(of: isEnabled, perform: viewModel.onEnabled)
    }

    private func confirmAction(_ trigger: UInt) {
        action()
    }
}

// MARK: - Calculations

private extension HoldToConfirmButton {
    var isHoldingState: Bool {
        viewModel.state == .holding
    }

    var isDisabledState: Bool {
        viewModel.state == .disabled
    }

    var labelTextColor: Color {
        isDisabledState ? Colors.Text.disabled : Colors.Text.primary2
    }

    var backgroundColor: Color {
        isDisabledState ? Colors.Button.disabled : Colors.Button.primary
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

    var scaleValue: CGFloat {
        isHoldingState ? 0.95 : 1
    }
}

// MARK: - Subviews

private extension HoldToConfirmButton {
    var content: some View {
        label
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background(background)
            .overlay(overlay)
            .scaleEffect(scaleValue)
            .animation(scaleAnimation, value: viewModel.state)
    }

    var label: some View {
        Text(viewModel.labelText(title: title))
            .transaction { $0.animation = nil }
            .font(.headline)
            .foregroundStyle(labelTextColor)
            .shake(
                trigger: viewModel.shakeTrigger,
                duration: viewModel.shakeDuration,
                shakesPerUnit: 1,
                travelDistance: 10
            )
    }

    @ViewBuilder
    var overlay: some View {
        switch viewModel.state {
        case .idle, .holding, .canceled:
            Color.clear.onTouches(perform: viewModel.onTouches)
        case .confirmed, .disabled:
            EmptyView()
        case .loading:
            ZStack {
                backgroundColor
                ProgressView().tint(Colors.Text.primary2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    var background: some View {
        ZStack(alignment: .leading) {
            backgroundColor
            progressBar
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

// MARK: - Configuration

public extension HoldToConfirmButton {
    struct Configuration {
        let cancelTitle: String
        let holdDuration: TimeInterval
        let shakeDuration: TimeInterval
        let vibratesPerSecond: Int

        public static let `default` = Self(
            cancelTitle: "Tap and hold",
            holdDuration: 1.5,
            shakeDuration: 0.5,
            vibratesPerSecond: 20
        )

        public init(
            cancelTitle: String,
            holdDuration: TimeInterval,
            shakeDuration: TimeInterval,
            vibratesPerSecond: Int
        ) {
            self.cancelTitle = cancelTitle
            self.holdDuration = holdDuration
            self.shakeDuration = shakeDuration
            self.vibratesPerSecond = vibratesPerSecond
        }
    }
}

// MARK: - isLoading

public extension HoldToConfirmButton {
    func isLoading(_ value: Bool) -> some View {
        environment(\.holdToConfirmButtonIsLoading, value)
    }
}

// MARK: - Environment key/value

private struct HoldToConfirmButtonIsLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private extension EnvironmentValues {
    var holdToConfirmButtonIsLoading: Bool {
        get { self[HoldToConfirmButtonIsLoadingKey.self] }
        set { self[HoldToConfirmButtonIsLoadingKey.self] = newValue }
    }
}
