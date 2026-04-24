//
//  TangemMacroImplementationPlugin.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftSyntax

/**
 Good thing to read to understand how it works:
 Official documentation:
 https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/

 Articles:
 https://medium.com/@gar.hovsepyan/macros-in-swift-a-practical-guide-to-using-fa1a24eba8bb
 https://engineering.traderepublic.com/how-to-create-swift-macros-the-easiest-and-least-boring-way-faf1113c6194
 */
@main
struct TangemMacroImplementationPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        CaseFlagableMacro.self,
        RawCaseNameMacro.self,
    ]
}
