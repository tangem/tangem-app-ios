//
//  NavigationContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public struct NavigationContainer<Root: View>: View {
    public typealias Router = NavigationRouter & NavigationActions

    @State private var path = NavigationPath()

    private let root: Root
    private let router: Router

    public init(root: Root, router: Router) {
        self.root = root
        self.router = router
    }

    public var body: some View {
        NavigationStack(path: $path) {
            root.onReceive(router.actionPublisher, perform: handleAction)
        }
    }

    private func handleAction(_ action: NavigationAction) {
        switch action {
        case .push(let route, let animated):
            withTransaction(makeTransaction(animated: animated)) {
                path.append(route)
            }
        case .pop(let animated):
            withTransaction(makeTransaction(animated: animated)) {
                path.removeLast()
            }
        case .popToRoot(let animated):
            withTransaction(makeTransaction(animated: animated)) {
                path = NavigationPath()
            }
        }
    }

    func makeTransaction(animated: Bool) -> Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        return transaction
    }
}
