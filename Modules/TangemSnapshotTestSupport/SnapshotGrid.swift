//
//  SnapshotGrid.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct SnapshotGrid<Data: RandomAccessCollection, Content: View>: View {
    private let columns: Int
    private let data: Data
    private let content: (Data.Element) -> Content

    public init(_ data: Data, columns: Int, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        precondition(columns > 0)
        self.data = data
        self.columns = columns
        self.content = content
    }

    public var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
            ForEach(Array(stride(from: 0, to: data.count, by: columns)), id: \.self) { start in
                GridRow {
                    ForEach(start ..< min(start + columns, data.count), id: \.self) { index in
                        content(data[data.index(data.startIndex, offsetBy: index)])
                    }
                }
            }
        }
    }
}
