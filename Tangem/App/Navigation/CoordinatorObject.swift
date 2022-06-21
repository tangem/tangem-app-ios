//
//  File.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct PopToRootOptions {
    var newScan: Bool = false
    
    static var `default`: PopToRootOptions = .init()
}

protocol CoordinatorObject: ObservableObject, Identifiable {
    associatedtype Options
    
    var dismissAction: () -> Void { get set }
    var popToRootAction: (PopToRootOptions) -> Void { get set }
    
    func dismiss()
    func start(with options: Options)
}

extension CoordinatorObject {
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
