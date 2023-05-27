//
//  ContentView.swift
//  Created by Michael Simms on 5/25/23.
//

import SwiftUI

struct ContentView: View {
	var zonesVM: ZonesVM = ZonesVM()

	var body: some View {
		ScrollView() {
			VStack(alignment: .center) {
				
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
							BarChartView(bars: self.zonesVM.listHrZones(), color: Color.red)
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
							BarChartView(bars: self.zonesVM.listPowerZones(), color: Color.blue)
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
				
				HStack() {
					Spacer()
					VStack(alignment: .center) {
						Text("Running Paces")
							.bold()
						if self.zonesVM.hasRunData() || self.zonesVM.hasHrData() {
							HStack() {
								if self.zonesVM.healthMgr.vo2Max != nil {
									Text("VO2 Max")
										.bold()
									Text(String(self.zonesVM.healthMgr.vo2Max!))
									Text("ml/kg")
								}
							}
							let runPaces = self.zonesVM.listRunTrainingPaces()
							ForEach(runPaces.keys.sorted(), id:\.self) { paceName in
								HStack() {
									Text(paceName)
										.bold()
									Spacer()
									Text(String(runPaces[paceName]!))
								}
								.padding(5)
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
