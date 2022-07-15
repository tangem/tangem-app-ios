//
//  File.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

typealias Action = () -> Void
typealias ParamsAction<Params> = (Params) -> Void

struct PopToRootOptions {
    var newScan: Bool = false

    static var `default`: PopToRootOptions = .init()
}

protocol CoordinatorObject: ObservableObject, Identifiable {
    associatedtype Options

    var dismissAction: Action { get }
    var popToRootAction: ParamsAction<PopToRootOptions> { get }

    func start(with options: Options)
    func dismiss()

    init(dismissAction: @escaping Action, popToRootAction: @escaping ParamsAction<PopToRootOptions>)
}

extension CoordinatorObject {
    init(dismissAction: @escaping Action = {}, popToRootAction: @escaping ParamsAction<PopToRootOptions> = { _ in }) {
        self.init(dismissAction: dismissAction, popToRootAction: popToRootAction)
    }

    func dismiss() {
        dismissAction()
    }

    func popToRoot(with options: PopToRootOptions) {
        popToRootAction(options)
    }

    func popToRoot() {
        popToRootAction(.default)
    }
}
