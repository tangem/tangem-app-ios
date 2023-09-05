//
//  LineChartView.swift
//  Timezones
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct LineChartView: View {
    let color: Color
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            linePath(for: geometry.size)
                .stroke(color, lineWidth: 1)
                .background(
                    LinearGradient(
                        colors: [color.opacity(0.25), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(gradientPath(for: geometry.size))
                )
        }
    }

    private func linePath(for size: CGSize) -> Path {
        guard
            data.count >= 2,
            let minX = data.min(),
            let maxX = data.max()
        else {
            return Path()
        }

        let dx = size.width / Double(data.count - 1)
        let points = data.enumerated().map { index, x in
            CGPoint(
                x: dx * Double(index),
                y: (maxX - x) / (maxX - minX) * size.height
            )
        }

        return Path { path in
            if let first = points.first {
                path.move(to: first)
            }

            for point in points.dropFirst(1) {
                path.addLine(to: point)
            }
        }
    }

    private func gradientPath(for size: CGSize) -> Path {
        var path = linePath(for: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        return path
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 30) {
            LineChartView(
                color: Color(hex: "#FF3333")!,
                data: [1, 7, 3, 5, 13].reversed()
            )
            .frame(width: 100, height: 50, alignment: .center)

            LineChartView(
                color: Color(hex: "#0099FF")!,
                data: [2, 4, 3, 5, 6]
            )
            .frame(width: 100, height: 50, alignment: .center)
        }
    }
}
