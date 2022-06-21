//
//  File.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol CoordinatorObject: ObservableObject, Identifiable {
    var dismissAction: () -> Void { get set }
    
    func dismiss()
}

extension CoordinatorObject {
    func dismiss() {
        dismissAction()
    }
}
