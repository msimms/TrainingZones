//
//  ContentView.swift
//  Created by Michael Simms on 5/25/23.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var zonesVM: ZonesVM = ZonesVM()
	@ObservedObject var ftp = NumbersOnly(initialDoubleValue: 0.0)
	@State private var showingUnitsSelection: Bool = false
	@State private var showingFtpError: Bool = false
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
							.padding(5)
						
						if !self.zonesVM.hasHrData() {
							Text("Heart rate zones are not available because your resting and maximum heart rates have not been calculated.")
							Spacer()
						}
						HStack() {
							Text("Resting Heart Rate")
								.bold()
							Spacer()
							if self.zonesVM.healthMgr.restingHr != nil {
								Text(String(self.zonesVM.healthMgr.restingHr!))
								Text("bpm")
							}
							else {
								Text("Not Set")
							}
						}
						HStack() {
							Text("Maximum Heart Rate")
								.bold()
							Spacer()
							if self.zonesVM.healthMgr.maxHr != nil {
								Text(String(self.zonesVM.healthMgr.maxHr!))
								Text("bpm")
							}
							else {
								Text("Not Set")
							}
						}
						if self.zonesVM.hasHrData() {
							BarChartView(bars: self.zonesVM.listHrZones(), color: Color.red, units: "BPM")
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
						}
					}
				}
				.padding(10)
				
				// Cycling Power Zones
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Cycling Power Zones")
							.bold()
							.padding(5)
						
						if !self.zonesVM.hasPowerData() {
							Text("Cycling power zones are not available because your FTP has not been set.")
							Spacer()
						}
						HStack() {
							Text("Functional Threshold Power: ")
								.bold()
							Spacer()
							TextField("Watts", text: self.$ftp.value)
								.keyboardType(.decimalPad)
								.multilineTextAlignment(.trailing)
								.fixedSize()
								.onChange(of: self.ftp.value) { value in
									if let value = Double(self.ftp.value) {
										self.zonesVM.functionalThresholdPower = value
									} else {
										self.showingFtpError = true
									}
								}
							Text("watts")
						}
						if self.zonesVM.hasPowerData() {
							BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts")
								.frame(height:256)
							Text("")
							Text("")
							Text("Watts")
								.bold()
						}
					}
				}
				.padding(10)
				
				// Running Paces
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
							.padding(5)
						
						if !(self.zonesVM.hasRunData() || self.zonesVM.hasHrData()) {
							Text("To calculate run paces VO2Max (Cardio Fitness Score) must be present, or a run workout of at least 5 KM must be recorded, along with heart rate data.")
							Spacer()
						}
						else {
							HStack() {
								if self.zonesVM.healthMgr.vo2Max != nil {
									Text("VO2 Max")
										.bold()
									Spacer()
									Text(String(self.zonesVM.healthMgr.vo2Max!))
									Text("ml/kg/min")
								}
							}
							.padding(5)
							let runPaces = self.zonesVM.listRunTrainingPaces()
							ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(self.convertPaceToDisplayString(paceMetersMin: runPaces[paceName]!))
								}
								.padding(5)
							}
							
							// Unit selection
							HStack {
								Spacer()
								Button("Units: " + self.units) {
									self.showingUnitsSelection = true
								}
								.confirmationDialog(self.units, isPresented: self.$showingUnitsSelection, titleVisibility: .visible) {
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
						}
					}
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
