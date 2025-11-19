//
//  ContentView.swift
//  Created by Michael Simms on 5/25/23.
//

//	MIT License
//
//  Copyright © 2023 Michael J Simms. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import SwiftUI

let DEFAULT_INSET = EdgeInsets(top: 0, leading: 20, bottom: 5, trailing: 20)

struct ContentView: View {
	enum Field: Hashable {
		case ftp
	}

	@ObservedObject var zonesVM: ZonesVM = ZonesVM()
	@ObservedObject var healthMgr: HealthManager = HealthManager.shared
	@State private var showingFtpHelp: Bool = false
	@State private var showingPowerZonesHelp: Bool = false
	@State private var showingCooperTestHelp: Bool = false
	@State private var showingHrAlgorithmSelection: Bool = false
	@State private var showingUnitsSelection: Bool = false
	@State private var showingFtpError: Bool = false
	@State private var showingVO2MaxError: Bool = false
	@State private var showingBest5KSecsError: Bool = false
	@State private var units: String = Preferences.preferredUnitSystem()
	@FocusState private var focusedField: Field?

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

	func convertSpeedToPaceDisplayString(speedMetersPerMin: Double) -> String {
		if speedMetersPerMin > 0.0 {
			if self.units == "Metric" {
				let paceSecPerKm = 60.0 / (speedMetersPerMin / 1000.0)
				return self.formatAsHHMMSS(numSeconds: paceSecPerKm) + " min/km"
			}
			else if self.units == "Imperial" {
				let METERS_PER_MILE = 1609.34
				let paceSecPerMile = 60.0 / (speedMetersPerMin / METERS_PER_MILE)
				return self.formatAsHHMMSS(numSeconds: paceSecPerMile) + " min/mile"
			}
		}
		return String(speedMetersPerMin)
	}

	func convertPaceToDisplayString(paceSecsPerMeter: Double) -> String {
		if paceSecsPerMeter > 0.0 {
			if self.units == "Metric" {
				let paceSecPerKm = paceSecsPerMeter * 1000.0
				return self.formatAsHHMMSS(numSeconds: paceSecPerKm) + " min/km"
			}
			else if self.units == "Imperial" {
				let METERS_PER_MILE = 1609.34
				let paceSecPerMile = paceSecsPerMeter * METERS_PER_MILE
				return self.formatAsHHMMSS(numSeconds: paceSecPerMile) + " min/mile"
			}
		}
		return String(paceSecsPerMeter)
	}

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
				// Heart Rate Zones
				VStack(alignment: .center) {
					HStack() {
						Text("Heart Rate Zones")
							.font(.system(size: 24))
							.bold()
							.padding(5)
					}
					HStack() {
						if !self.zonesVM.hasHrData() {
							Image(systemName: "exclamationmark.circle")
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
								.font(.system(.body, design: .monospaced))
							Text("years")
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Found")
								.font(.system(.body, design: .monospaced))
						}
					}
					HStack() {
						Text("Resting Heart Rate:")
							.bold()
						Spacer()
						if self.healthMgr.restingHr != nil {
							Text(String(self.healthMgr.restingHr!))
								.font(.system(.body, design: .monospaced))
							Text("bpm")
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Found")
								.font(.system(.body, design: .monospaced))
						}
					}
					HStack() {
						Text("Estimated Maximum Heart Rate:")
							.bold()
						Spacer()
						if self.healthMgr.estimatedMaxHr != nil {
							Text(String(Int(self.healthMgr.estimatedMaxHr!)))
								.font(.system(.body, design: .monospaced))
							Text("bpm")
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Calculated")
								.font(.system(.body, design: .monospaced))
						}
					}
					HStack() {
						if self.zonesVM.hasHrData() {
							VStack() {
								let hrZonesResult = self.zonesVM.listHrZones()
								BarChartView(bars: hrZonesResult.0, color: Color.red, units: "BPM", description: self.zonesVM.hrZonesDescription)
									.frame(height:256)
									.font(.system(.caption))
								Text("")
								Text("")
								Text("BPM")
									.bold()
								Text(self.zonesVM.hrZonesDescription)
								Text("Calculated Using ")
									.bold()
								Text(hrZonesResult.1)
									.multilineTextAlignment(.center)
							}
						}
					}
				}
				.padding(DEFAULT_INSET)

				// Cycling Power Zones
				VStack(alignment: .center) {
					HStack() {
						Text("Cycling Power Zones")
							.font(.system(size: 24))
							.bold()
							.padding(5)
					}
					HStack() {
						if !self.zonesVM.hasPowerData() {
							Image(systemName: "exclamationmark.circle")
							Text("Cycling power zones were not calculated because your FTP has not been set.")
						}
					}
					
					Spacer()

					HStack() {
						Text("Functional Threshold Power: ")
							.bold()
						Spacer()
						TextField("Not set", text: Binding(
							get: { self.healthMgr.ftp == nil ? "" : String(self.healthMgr.ftp!) },
							set: {(newValue) in
								if let newFtp = Double(newValue) {
									self.zonesVM.healthMgr.ftp = newFtp
								}
							}))
							.focused(self.$focusedField, equals: .ftp)
#if os(iOS) || os(watchOS)
							.keyboardType(.decimalPad)
#endif
							.font(.system(.body, design: .monospaced))
							.multilineTextAlignment(.trailing)
							.fixedSize()
						Text("watts")
							.font(.system(.body, design: .monospaced))
					}
					if self.healthMgr.estimatedFtp != nil {
						HStack() {
							Text("FTP (Estimated From HealthKit Power Data): ")
								.bold()
							Spacer()
							Text(String(Int(self.healthMgr.estimatedFtp!)))
								.font(.system(.body, design: .monospaced))
							Text("watts")
								.font(.system(.body, design: .monospaced))
						}
						.popover(isPresented: $showingFtpHelp) {
							Text("Either the best:\n(20 min avg power * 95%) or\n(8 min avg power * 90%)\nfrom the last six months of data.")
								.padding()
								.presentationCompactAdaptation(.popover)
						}
						.onTapGesture { showingFtpHelp.toggle() }
					}
					HStack() {
						if self.zonesVM.hasPowerData() {
							VStack() {
								BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue, units: "Watts", description: self.zonesVM.powerZonesDescription)
									.frame(height:256)
									.font(.system(.caption))
								Text("")
								Text("")
								Text("Watts")
									.bold()
								Text(self.zonesVM.powerZonesDescription)
							}
							.popover(isPresented: $showingPowerZonesHelp) {
								Text("Computed from FTP using the Andy Coggan formula.")
									.padding()
									.presentationCompactAdaptation(.popover)
							}
							.onTapGesture { showingPowerZonesHelp.toggle() }
						}
					}
				}
				.padding(DEFAULT_INSET)
				
				// Aerobic Performance
				VStack(alignment: .center) {
					HStack() {
						Text("Aerobic Performance")
							.font(.system(size: 24))
							.bold()
							.padding(5)
					}
					
					HStack() {
						if !(self.zonesVM.hasRunData() || self.zonesVM.hasHrData()) {
							Image(systemName: "questionmark.circle")
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
								.font(.system(.body, design: .monospaced))
							Text("ml/kg/min")
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Set")
								.font(.system(.body, design: .monospaced))
						}
					}
					.padding(.bottom, 2)
					HStack() {
						Text("Best Recent 5 KM (Or Greater) Effort:")
							.bold()
						Spacer()
						if self.healthMgr.best5KPace != nil {
							Text(self.convertPaceToDisplayString(paceSecsPerMeter: self.healthMgr.best5KPace!))
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Calculated")
								.font(.system(.body, design: .monospaced))
						}
					}
					.padding(.bottom, 2)
					HStack() {
						Text("Best Recent 12 Minute Effort (Cooper Test):")
							.bold()
						Spacer()
						if self.healthMgr.best12MinuteEffort != nil {
							Text(String(format: "%.1f", self.healthMgr.best12MinuteEffort!))
								.font(.system(.body, design: .monospaced))
						}
						else {
							Text("Not Calculated")
								.font(.system(.body, design: .monospaced))
						}
					}
					.popover(isPresented: $showingCooperTestHelp) {
						Text("Looks through HealthKit for the fastest\nrun of approximately 12 minutes.")
							.padding()
							.presentationCompactAdaptation(.popover)
					}
					.onTapGesture { showingCooperTestHelp.toggle() }
					.padding(.bottom, 2)
				}
				.padding(DEFAULT_INSET)

				// Run Training Paces
				VStack(alignment: .center) {
					HStack() {
						Text("Run Training Paces")
							.font(.system(size: 24))
							.bold()
							.padding(5)
					}

					VStack() {
						let runPacesResult = self.zonesVM.listRunTrainingPaces()
						ForEach([LONG_RUN_PACE_STR, EASY_RUN_PACE_STR, TEMPO_RUN_PACE_STR, FUNCTIONAL_THRESHOLD_PACE_STR], id:\.self) { paceName in
							if runPacesResult.0[paceName] != nil {
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(self.convertSpeedToPaceDisplayString(speedMetersPerMin: runPacesResult.0[paceName]!))
										.font(.system(.body, design: .monospaced))
								}
								.padding(.bottom, 2)
							}
						}
						Text("Calculated Using ")
							.bold()
						Text(runPacesResult.1)
							.multilineTextAlignment(.center)
					}
				}
				.padding(DEFAULT_INSET)

				// Unit selection
				VStack(alignment: .center) {
					VStack() {
						Text("Unit System")
							.font(.system(size: 24))
							.bold()
						Spacer()
						Button(self.units) {
							self.showingUnitsSelection = true
						}
						.confirmationDialog(self.units, isPresented: self.$showingUnitsSelection, titleVisibility: .visible) {
							ForEach(["Metric", "Imperial"], id: \.self) { item in
								Button(item) {
									self.units = item
									Preferences.setPreferredUnitSystem(system: item)
								}
							}
						}
					}
				}
				.padding(DEFAULT_INSET)

				// Notes
				HStack() {
					Image(systemName: "questionmark.circle")
					Text("All the values used in these calculations are either read or estimated from HealthKit data.")
				}
				.padding(DEFAULT_INSET)
			}
		}
		.toolbar {
			ToolbarItem(placement: .keyboard) {
				Button("Done") {
					if self.focusedField == .ftp {
						self.zonesVM.healthMgr.setFtp()
					}
					self.focusedField = nil
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
