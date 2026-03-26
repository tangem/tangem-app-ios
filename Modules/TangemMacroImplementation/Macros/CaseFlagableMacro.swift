//
//  CaseFlagableMacro.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftSyntax
import SwiftDiagnostics

public struct CaseFlagableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure the macro is applied only to enums
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: Syntax(declaration),
                message: MacroError.applicableOnlyToEnum(macro: "CaseFlagableMacro")
            )
            context.diagnose(diagnostic)
            return []
        }

        // Determine access level modifier from the enum declaration
        let accessModifier = enumDecl.modifiers.first(where: {
            $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
        }).map { $0.name.text + " " } ?? ""

        // Collect all case names from the enum, including multiple cases per line
        let caseNames: [String] = enumDecl.memberBlock.members.flatMap { member -> [String] in
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return [] }
            return enumCaseDecl.elements.map { $0.name.text }
        }

        // Build properties: var isXxx: Bool { if case .xxx = self { true } else { false } }
        let properties: [String] = caseNames.map { caseName in
            let capitalized = caseName.prefix(1).uppercased() + caseName.dropFirst()
            return """
            \(accessModifier)var is\(capitalized): Bool { if case .\(caseName) = self { true } else { false } }
            """
        }

        let code = properties.joined(separator: "\n")
        return [DeclSyntax(stringLiteral: code)]
    }
}
