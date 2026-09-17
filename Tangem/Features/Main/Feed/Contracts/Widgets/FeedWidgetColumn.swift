//
//  FeedWidgetColumn.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedWidgetColumn: Identifiable, Equatable {
    case pair(top: FeedWidget, bottom: FeedWidget)
    case single(FeedWidget)

    var id: String {
        switch self {
        case .pair(let top, let bottom): "\(top.id)-\(bottom.id)"
        case .single(let widget): widget.id
        }
    }

    var isProductCard: Bool {
        switch self {
        case .single(let widget) where widget.span == .wide: true
        case .single, .pair: false
        }
    }
}

// MARK: - Packing

extension FeedWidgetColumn {
    static func columns(packing widgets: [FeedWidget]) -> [FeedWidgetColumn] {
        var columns: [FeedWidgetColumn] = []
        var pendingCompact: FeedWidget?

        for widget in widgets {
            switch (widget.span, pendingCompact) {
            case (.compact, .none):
                pendingCompact = widget

            case (.compact, .some(let top)):
                columns.append(.pair(top: top, bottom: widget))
                pendingCompact = nil

            case (.wide, .none):
                columns.append(.single(widget))

            case (.wide, .some(let lone)):
                columns.append(.single(lone))
                columns.append(.single(widget))
                pendingCompact = nil
            }
        }

        if let lone = pendingCompact {
            columns.append(.single(lone))
        }

        return columns
    }
}
