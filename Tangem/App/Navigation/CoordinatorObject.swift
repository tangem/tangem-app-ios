//
//  File.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemUIUtils

typealias Action<Params> = (Params) -> Void

struct PopToRootOptions {
    var newScan: Bool = false

    static let `default`: PopToRootOptions = .init()
}

protocol CoordinatorObject: ObservableObject, Identifiable, NavigationRoutable {
    associatedtype InputOptions
    associatedtype OutputOptions

    var dismissAction: Action<OutputOptions> { get }
    var popToRootAction: Action<PopToRootOptions> { get }

    func start(with options: InputOptions)

    init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>)
}

extension CoordinatorObject {
    init(dismissAction: @escaping Action<OutputOptions> = { _ in }, popToRootAction: @escaping Action<PopToRootOptions> = { _ in }) {
        self.init(dismissAction: dismissAction, popToRootAction: popToRootAction)
    }

    func dismiss(with options: OutputOptions) {
        dismissAction(options)
    }

    func popToRoot(with options: PopToRootOptions) {
        popToRootAction(options)
    }

    func popToRoot() {
        popToRootAction(.default)
    }
}

extension CoordinatorObject where OutputOptions == Void {
    func dismiss() {
        dismissAction(())
    }
}

// MARK: - Hashable

extension CoordinatorObject {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
