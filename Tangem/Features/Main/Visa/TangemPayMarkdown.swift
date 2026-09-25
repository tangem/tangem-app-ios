//
//  TangemPayMarkdown.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum TangemPayMarkdown {
    static func attributed(_ string: String, linkColor: Color) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)

        guard var attributed = try? AttributedString(markdown: string, options: options) else {
            return AttributedString(string)
        }

        for run in attributed.runs where run.link != nil {
            attributed[run.range].underlineStyle = Text.LineStyle.single
            attributed[run.range].foregroundColor = linkColor
        }

        return attributed
    }
}
