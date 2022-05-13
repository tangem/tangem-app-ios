//
//  AssemblyProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AssemblyProviding { //[REDACTED_TODO_COMMENT]
    var assembly: Assembly { get }
}
 
private struct AssemblyProviderKey: InjectionKey {
    static var currentValue: AssemblyProviding = AssemblyProvider()
}

extension InjectedValues {
    var assemblyProvider: AssemblyProviding {
        get { Self[AssemblyProviderKey.self] }
        set { Self[AssemblyProviderKey.self] = newValue }
    }
}

