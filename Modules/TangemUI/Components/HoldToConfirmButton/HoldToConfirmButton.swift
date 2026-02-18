//
//  HoldToConfirmButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization

public struct HoldToConfirmButton: View {
    @State private var viewModel: WrappedHoldToConfirmButtonModel

    private let title: String
    private let isLoading: Bool
    private let isDisabled: Bool
    private let configuration: Configuration
    private let action: Action

    public init(
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        configuration: Configuration = .default,
        action: @escaping () -> Void
    ) {
        viewModel = WrappedHoldToConfirmButtonModel(
            title: title,
            isLoading: isLoading,
            isDisabled: isDisabled,
            configuration: configuration,
            action: action
        )
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.configuration = configuration
        self.action = HoldToConfirmButton.Action(closure: action)
    }

    public var body: some View {
        WrappedHoldToConfirmButton(viewModel: viewModel)
            .environment(\.title, title)
            .environment(\.isLoading, isLoading)
            .environment(\.isDisabled, isDisabled)
            .environment(\.configuration, configuration)
            .environment(\.action, action)
    }
}

struct WrappedHoldToConfirmButton {
    typealias ViewModel = WrappedHoldToConfirmButtonModel

    @Environment(\.title) var title: String
    @Environment(\.isLoading) var isLoading: Bool
    @Environment(\.isDisabled) var isDisabled: Bool
    @Environment(\.configuration) var configuration: HoldToConfirmButton.Configuration
    @Environment(\.action) var action: HoldToConfirmButton.Action

    @ObservedObject var viewModel: ViewModel
}

// MARK: - Types

extension HoldToConfirmButton {
    public struct Configuration: Hashable {
        let cancelTitle: String
        let holdDuration: TimeInterval
        let shakeDuration: TimeInterval
        let vibratesPerSecond: Int

        public static let `default` = Self(
            cancelTitle: Localization.commonTapAndHoldHint,
            holdDuration: 1.5,
            shakeDuration: 0.8,
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

    struct Action: Equatable {
        private let id = UUID()

        let closure: () -> Void

        static let `default`: Self = .init(closure: {})

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
    }
}

// MARK: - Environment keys

private struct TitleKey: EnvironmentKey {
    static let defaultValue: String = ""
}

private struct IsLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct IsDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct ConfigurationKey: EnvironmentKey {
    static let defaultValue: HoldToConfirmButton.Configuration = .default
}

private struct ActionKey: EnvironmentKey {
    static let defaultValue: HoldToConfirmButton.Action = .default
}

// MARK: - Environment value

private extension EnvironmentValues {
    var title: String {
        get { self[TitleKey.self] }
        set { self[TitleKey.self] = newValue }
    }

    var isLoading: Bool {
        get { self[IsLoadingKey.self] }
        set { self[IsLoadingKey.self] = newValue }
    }

    var isDisabled: Bool {
        get { self[IsDisabledKey.self] }
        set { self[IsDisabledKey.self] = newValue }
    }

    var configuration: HoldToConfirmButton.Configuration {
        get { self[ConfigurationKey.self] }
        set { self[ConfigurationKey.self] = newValue }
    }

    var action: HoldToConfirmButton.Action {
        get { self[ActionKey.self] }
        set { self[ActionKey.self] = newValue }
    }
}
