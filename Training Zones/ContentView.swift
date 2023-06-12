//
//  ContentView.swift
//  Created by Michael Simms on 5/25/23.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var zonesVM: ZonesVM = ZonesVM()
	@ObservedObject var healthMgr: HealthManager = HealthManager.shared
	@ObservedObject var ftp = NumbersOnly(initialDoubleValue: 0.0)
	@State private var showingUnitsSelection: Bool = false
	@State private var showingFtpError: Bool = false
	@State private var showingVO2MaxError: Bool = false
	@State private var showingBest5KSecsError: Bool = false
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
		if paceMetersMin > 0.0 {
			if self.units == "Metric" {
				let paceKmMin = (1000.0 / paceMetersMin) * 60.0
				return self.formatAsHHMMSS(numSeconds: paceKmMin) + " min/km"
			}
			else if self.units == "Imperial" {
				let METERS_PER_MILE = 1609.34
				let paceKmMin = (METERS_PER_MILE / paceMetersMin) * 60.0
				return self.formatAsHHMMSS(numSeconds: paceKmMin) + " min/mile"
			}
		}
		return String(paceMetersMin)
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
				// Heart Rate Zones
				VStack(alignment: .center) {
					HStack() {
						Text("Heart Rate Zones")
							.bold()
							.padding(5)
					}
					HStack() {
						if !self.zonesVM.hasHrData() {
							Text("Heart rate zones are not available because your resting and maximum heart rates have not been calculated and age has not been set.")
						}
					}

					Spacer()

					HStack() {
						Text("Age (Years):")
							.bold()
						Spacer()
						if self.healthMgr.ageInYears != nil {
							Text(String(format: "%.2f", self.healthMgr.ageInYears!))
							Text("years")
						}
						else {
							Text("Not Set")
						}
					}
					HStack() {
						Text("Resting Heart Rate:")
							.bold()
						Spacer()
						if self.healthMgr.restingHr != nil {
							Text(String(self.healthMgr.restingHr!))
							Text("bpm")
						}
						else {
							Text("Not Set")
						}
					}
					HStack() {
						Text("Maximum Heart Rate:")
							.bold()
						Spacer()
						if self.healthMgr.maxHr != nil {
							Text(String(self.healthMgr.maxHr!))
							Text("bpm")
						}
						else {
							Text("Not Set")
						}
					}
					HStack() {
						if self.zonesVM.hasHrData() {
							VStack() {
								BarChartView(bars: self.zonesVM.listHrZones(), color: Color.red, units: "BPM")
									.frame(height:256)
								Text("")
								Text("")
								Text("BPM")
									.bold()
								Text("Note: The Karvonen formula (i.e. heart rate reserve) is used if the resting heart rate is known and maximum heart rate can be calculated.")
							}
						}
					}
				}
				.padding(10)

				// Cycling Power Zones
				VStack(alignment: .center) {
					HStack() {
						Text("Cycling Power Zones")
							.bold()
							.padding(5)
					}
					HStack() {
						if !self.zonesVM.hasPowerData() {
							Text("Cycling power zones are not available because your FTP has not been set.")
						}
					}
					
					Spacer()

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
					HStack() {
						if self.zonesVM.hasPowerData() {
							VStack() {
								BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts")
									.frame(height:256)
								Text("")
								Text("")
								Text("Watts")
									.bold()
							}
						}
					}
				}
				.padding(10)
				
				// Running Paces
				VStack(alignment: .center) {
					HStack() {
						Text("Running Paces")
							.bold()
							.padding(5)
					}
					
					HStack() {
						if !(self.zonesVM.hasRunData() || self.zonesVM.hasHrData()) {
							Text("To calculate run paces VO\u{00B2}Max (Cardio Fitness Score) must be calculated, or a hard run of at least 5 KM must be known.")
						}
					}

					Spacer()

					HStack() {
						Text("VO\u{00B2} Max:")
							.bold()
						Spacer()
						if self.healthMgr.vo2Max != nil {
							Text(String(self.healthMgr.vo2Max!))
							Text("ml/kg/min")
						}
						else {
							Text("Not Set")
						}
					}
					HStack() {
						Text("Best Recent 5 KM (Or Greater) Effort:")
							.bold()
						Spacer()
						if self.healthMgr.best5KDuration != nil {
							Text(self.formatAsHHMMSS(numSeconds: self.healthMgr.best5KDuration!))
						}
						else {
							Text("Not Set")
						}
					}
					HStack() {
						let runPaces = self.zonesVM.listRunTrainingPaces()
						VStack() {
							ForEach([LONG_RUN_PACE_STR, EASY_RUN_PACE_STR, TEMPO_RUN_PACE_STR, FUNCTIONAL_THRESHOLD_PACE_STR], id:\.self) { paceName in
								if runPaces[paceName] != nil {
									HStack() {
										Text(paceName)
											.bold()
										Spacer()
										Text(self.convertPaceToDisplayString(paceMetersMin: runPaces[paceName]!))
									}
									.padding(.bottom, 3)
								}
							}
						}
					}

					// Unit selection
					HStack() {
						Text("Units:")
							.bold()
						Spacer()
						Button(self.units) {
							self.showingUnitsSelection = true
						}
						.confirmationDialog(self.units, isPresented: self.$showingUnitsSelection, titleVisibility: .visible) {
							ForEach(["Metric", "Imperial"], id: \.self) { item in
								Button(item) {
									self.units = item
								}
							}
						}
					}
				}
				.padding(10)

				// Notes
				HStack() {
					Text("Note: Values are either read or estimated from HealthKit data.")
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
