//
//  DSShowcaseMatrix.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUIUtils

struct DSShowcaseMatrix<Row: Hashable, Column: Hashable, Cell: View>: View {
    private let rows: [Row]
    private let rowLabel: (Row) -> String
    private let layout: Layout

    init(
        rows: some Collection<Row>,
        columns: some Collection<Column>,
        rowLabel: ((Row) -> String)? = nil,
        columnLabel: ((Column) -> String)? = nil,
        @ViewBuilder cell: @escaping (Row, Column) -> Cell
    ) {
        self.rows = Array(rows)
        self.rowLabel = rowLabel ?? { DSShowcaseLabel.text($0) }
        layout = .grid(columns: Array(columns), columnLabel: columnLabel ?? { DSShowcaseLabel.text($0) }, cell: cell)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                switch layout {
                case .grid(let columns, let columnLabel, let cell):
                    GridRow {
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                        ForEach(columns, id: \.self) { column in
                            DSShowcaseMatrixLabel(columnLabel(column))
                        }
                    }

                    ForEach(rows, id: \.self) { row in
                        GridRow(alignment: .center) {
                            DSShowcaseMatrixLabel(rowLabel(row))
                            ForEach(columns, id: \.self) { column in
                                cell(row, column)
                            }
                        }
                    }
                case .list(let cell):
                    ForEach(rows, id: \.self) { row in
                        GridRow(alignment: .center) {
                            DSShowcaseMatrixLabel(rowLabel(row))
                            cell(row)
                        }
                    }
                }
            }
        }
    }
}

extension DSShowcaseMatrix where Column == Never {
    init(
        rows: some Collection<Row>,
        rowLabel: ((Row) -> String)? = nil,
        @ViewBuilder cell: @escaping (Row) -> Cell
    ) {
        self.rows = Array(rows)
        self.rowLabel = rowLabel ?? { DSShowcaseLabel.text($0) }
        layout = .list(cell: cell)
    }
}

private extension DSShowcaseMatrix {
    enum Layout {
        case grid(columns: [Column], columnLabel: (Column) -> String, cell: (Row, Column) -> Cell)
        case list(cell: (Row) -> Cell)
    }
}

struct DSShowcaseGroup<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DSShowcaseMatrixLabel: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            .lineLimit(1)
            .fixedSize()
    }
}
#endif
