//
//  ContentView.swift
//  Created by Michael Simms on 5/25/23.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var zonesVM: ZonesVM = ZonesVM()
	@State private var showingUnitsSelection: Bool = false
	@State private var units: String = "Metric"

	/// @brief Utility function for converting a number of seconds into HH:MMSS format
	func formatAsHHMMSS(numSeconds: Double) -> String {
		let SECS_PER_DAY  = 86400
		let SECS_PER_HOUR = 3600
		let SECS_PER_MIN  = 60
		var tempSeconds   = Int(numSeconds)
		
		let days     = (tempSeconds / SECS_PER_DAY)
		tempSeconds -= (days * SECS_PER_DAY)
		let hours    = (tempSeconds / SECS_PER_HOUR)
		tempSeconds -= (hours * SECS_PER_HOUR)
		let minutes  = (tempSeconds / SECS_PER_MIN)
		tempSeconds -= (minutes * SECS_PER_MIN)
		let seconds  = (tempSeconds % SECS_PER_MIN)
		
		if days > 0 {
			return String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
		}
		else if hours > 0 {
			return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
		}
		return String(format: "%02d:%02d", minutes, seconds)
	}

	func convertPaceToDisplayString(paceMetersMin: Double) -> String {
		if self.units == "Metric" {
			let paceKmMin = (1000.0 / paceMetersMin) * 60.0
			return self.formatAsHHMMSS(numSeconds: paceKmMin)
		}
		else if self.units == "Imperial" {
			let METERS_PER_MILE = 1609.34
			let paceKmMin = (METERS_PER_MILE / paceMetersMin) * 60.0
			return self.formatAsHHMMSS(numSeconds: paceKmMin)
		}
		return String(paceMetersMin)
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {

				// Heart Rate Zones
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Heart Rate Zones")
							.bold()
						if self.zonesVM.hasHrData() {
							HStack() {
								if self.zonesVM.healthMgr.restingHr != nil {
									Text("Resting Heart Rate")
										.bold()
									Text(String(self.zonesVM.healthMgr.restingHr!))
									Text("bpm")
								}
								else {
									Text("Resting heart rate not set")
										.bold()
								}
							}
							HStack() {
								if self.zonesVM.healthMgr.maxHr != nil {
									Text("Maximum Heart Rate")
										.bold()
									Text(String(self.zonesVM.healthMgr.maxHr!))
									Text("bpm")
								}
								else {
									Text("Maximum heart rate not calculated")
										.bold()
								}
							}
							BarChartView(bars: self.zonesVM.listHrZones(), color: Color.red, units: "BPM")
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
						}
						else {
							Text("Heart rate zones are not available because your resting and maximum heart rates have not been calculated.")
						}
					}
					Spacer()
				}
				.padding(10)
				
				// Cycling Power Zones
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Cycling Power Zones")
							.bold()
						if self.zonesVM.hasPowerData() {
							HStack() {
								Text("Functional Threshold Power")
									.bold()
								Text(String(self.zonesVM.functionalThresholdPower))
								Text("watts")
							}
							BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts")
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
						}
						else {
							Text("Cycling power zones are not available because your FTP has not been set (or estimated from cycling power data).")
						}
					}
					Spacer()
				}
				.padding(10)
				
				// Running Paces
				HStack() {
					Spacer()

					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
						
						// Unit selection
						HStack {
							Spacer()
							Button("Units: " + self.units) {
								self.showingUnitsSelection = true
							}
							.confirmationDialog("Preferred unit system", isPresented: self.$showingUnitsSelection, titleVisibility: .visible) {
								ForEach(["Metric", "Imperial"], id: \.self) { item in
									Button(item) {
										self.units = item
									}
								}
							}
							.bold()
							Spacer()
						}
						.padding(5)

						if self.zonesVM.hasRunData() || self.zonesVM.hasHrData() {
							HStack() {
								if self.zonesVM.healthMgr.vo2Max != nil {
									Text("VO2 Max")
										.bold()
									Text(String(self.zonesVM.healthMgr.vo2Max!))
									Text("ml/kg/min")
								}
							}
							let runPaces = self.zonesVM.listRunTrainingPaces()
							ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(self.convertPaceToDisplayString(paceMetersMin: runPaces[paceName]!))
								}
								.padding(10)
							}
						}
						else {
							Text("Run paces are not available because there are no runs of at least 5 km in the database.")
						}
					}
					Spacer()
				}
				.padding(10)
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
