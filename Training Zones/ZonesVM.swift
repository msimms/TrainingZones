//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
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

import Foundation

let SPEED_RUN_PACE_STR: String = "Speed Session Pace" // Pace for medium distance interfals
let SHORT_INTERVAL_RUN_PACE_STR: String = "Short Interval Run Pace" // Pace for shorter track intervals
let FUNCTIONAL_THRESHOLD_PACE_STR: String = "Functional Threshold Pace" // Pace that could be held for one hour, max effort
let TEMPO_RUN_PACE_STR: String = "Tempo Run Pace"
let MARATHON_PACE_STR: String = "Marathon Pace"
let EASY_RUN_PACE_STR: String = "Easy Run Pace"
let LONG_RUN_PACE_STR: String = "Long Run Pace"

class ZonesVM : ObservableObject {
	@Published var healthMgr: HealthManager = HealthManager.shared
	var hrZonesDescription: String = ""
	var powerZonesDescription: String = ""

	init() {
		self.healthMgr.requestAuthorization()
	}

	func hasHrData() -> Bool {
		return self.healthMgr.ageInYears != nil
	}

	func hasPowerData() -> Bool {
		return self.healthMgr.ftp != nil
	}

	func hasRunData() -> Bool {
		return self.healthMgr.vo2Max != nil || self.healthMgr.best5KDuration != nil
	}

	func listHrZones() -> (Array<Bar>, String) {
		var zoneBars: Array<Bar> = []

		guard (self.healthMgr.ageInYears != nil) else {
			return (zoneBars, "")
		}

		let calc: ZonesCalculator = ZonesCalculator()
		let hrZonesResult = calc.CalculateHeartRateZones(restingHr: self.healthMgr.restingHr ?? 0.0, maxHr: self.healthMgr.maxHr ?? 0.0, ageInYears: self.healthMgr.ageInYears!)
		let zoneMaxValues = hrZonesResult.0
		let algorithmName = hrZonesResult.1
		let descriptions = ["Very Light (Recovery)", "Light (Endurance)", "Moderate", "Hard (Speed Endurance)", "Maximum"]
		var lastValue = 1

		self.hrZonesDescription = ""
		for zoneNum in 0...4 {
			let printableValue = Int(zoneMaxValues[zoneNum])
			let zoneValue = zoneMaxValues[zoneNum]
			let zoneLabel = "\(lastValue) to \(printableValue) BPM"
			zoneBars.append(Bar(value: zoneValue, label: zoneLabel, description: descriptions[zoneNum]))

			self.hrZonesDescription += "Zone "
			self.hrZonesDescription += String(zoneNum + 1)
			self.hrZonesDescription += " : "
			self.hrZonesDescription += descriptions[zoneNum]
			self.hrZonesDescription += "\n"
			
			lastValue = printableValue
		}
		return (zoneBars, algorithmName)
	}

	func listPowerZones() -> Array<Bar> {
		var zoneBars: Array<Bar> = []

		guard (self.healthMgr.ftp != nil) else {
			return zoneBars
		}

		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalcuatePowerZones(ftp: self.healthMgr.ftp!)
		let descriptions = ["Recovery", "Endurance", "Tempo", "Lactate Threshold", "VO2 Max", "Anaerobic Capacity", "Neuromuscular Power"]
		var lastValue = 1

		self.powerZonesDescription = ""
		for zoneNum in 0...5 {
			let printableValue = Int(zones[zoneNum])
			let zoneValue = zones[zoneNum]
			let zoneLabel = "\(lastValue) to \(printableValue) Watts"
			zoneBars.append(Bar(value: zoneValue, label: zoneLabel, description: descriptions[zoneNum]))

			self.powerZonesDescription += "Zone "
			self.powerZonesDescription += String(zoneNum + 1)
			self.powerZonesDescription += " : "
			self.powerZonesDescription += descriptions[zoneNum]
			self.powerZonesDescription += "\n"

			lastValue = printableValue
		}
		return zoneBars
	}

	func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		
		if self.healthMgr.vo2Max != nil || self.healthMgr.best5KDuration != nil || (self.healthMgr.restingHr != nil && self.healthMgr.maxHr != nil) {
			let calc: ZonesCalculator = ZonesCalculator()
			let restingHr = self.healthMgr.restingHr ?? 0.0
			let maxHr = self.healthMgr.maxHr ?? 0.0
			let vo2Max = self.healthMgr.vo2Max ?? 0.0
			let best5KSecs = self.healthMgr.best5KDuration ?? 0
			let cooperTestMeters = self.healthMgr.best12MinuteEffort ?? 0
			let ageInYears = self.healthMgr.ageInYears ?? 0.0
			
			result[LONG_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.LONG_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, cooperTestMeters: cooperTestMeters, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[EASY_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.EASY_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, cooperTestMeters: cooperTestMeters, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[MARATHON_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.MARATHON_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, cooperTestMeters: cooperTestMeters, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[TEMPO_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.TEMPO_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, cooperTestMeters: cooperTestMeters, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[FUNCTIONAL_THRESHOLD_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, cooperTestMeters: cooperTestMeters, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		}
		return result
	}
}
