//
//  BarChartView.swift
//  Created by Michael Simms on 10/15/22.
//

import SwiftUI

struct Bar: Identifiable {
	let id: UUID = UUID()
	let value: Double
	let label: String
}

struct BarChartView: View {
	let bars: Array<Bar>
	let max: Double
	let color: Color
	let units: String

	init(bars: [Bar], color: Color, units: String) {
		self.bars = bars
		self.max = bars.map { $0.value }.max() ?? 0
		self.color = color
		self.units = units
	}

	var body: some View {
		GeometryReader { geometry in
			HStack(alignment: .bottom) {
				ForEach(self.bars) { bar in
					VStack(alignment: .center) {
						ZStack() {
							let barHeight = CGFloat(bar.value) / CGFloat(self.max) * geometry.size.height
							Rectangle()
								.frame(height: barHeight)
								.overlay(Rectangle().stroke(self.color).background(self.color))
								.accessibility(label: Text(bar.label))
							Text(bar.label + " " + self.units)
								.rotationEffect(Angle(degrees: -90))
								.offset(y: 0)
						}
					}
				}
			}
		}
	}
}
