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
							BarChartView(bars: self.zonesVM.listHrZones(), color: Color.red)
								.frame(height:256)
							Text("")
							Text("")
							Text("BPM")
								.bold()
						}
						else {
							Text("Heart rate zones are not available because your maximum heart rate has not been set (or estimated from existing data).")
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
