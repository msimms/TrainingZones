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
	@Published var functionalThresholdPower: Double?

	init() {
		self.healthMgr.requestAuthorization()
	}

	func hasHrData() -> Bool {
		return self.healthMgr.ageInYears != nil
	}

	func hasPowerData() -> Bool {
		return self.functionalThresholdPower != nil
	}

	func hasRunData() -> Bool {
		return self.healthMgr.vo2Max != nil || self.healthMgr.best5KDuration != nil
	}

	func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []

		guard (self.healthMgr.ageInYears != nil) else {
			return result
		}

		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalculateHeartRateZones(restingHr: self.healthMgr.restingHr ?? 0.0, maxHr: self.healthMgr.maxHr ?? 0.0, ageInYears: self.healthMgr.ageInYears!)
		let descriptions = ["Very Light (Recovery)", "Light (Endurance)", "Moderate", "Hard (Speed Endurance)", "Maximum"]

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue)), description: descriptions[zoneNum]))
		}
		return result
	}

	func listPowerZones() -> Array<Bar> {
		var result: Array<Bar> = []

		guard (self.functionalThresholdPower != nil) else {
			return result
		}

		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalcuatePowerZones(ftp: self.functionalThresholdPower!)
		let descriptions = ["Recovery", "Endurance", "Tempo", "Lactate Threshold", "VO2 Max", "Anaerobic Capacity", "Neuromuscular Power"]

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue)), description: descriptions[zoneNum]))
		}
		return result
	}

	func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		
		if self.healthMgr.vo2Max != nil || self.healthMgr.best5KDuration != nil || (self.healthMgr.restingHr != nil && self.healthMgr.maxHr != nil) {
			let calc: ZonesCalculator = ZonesCalculator()
			let restingHr = self.healthMgr.restingHr ?? 0.0
			let maxHr = self.healthMgr.maxHr ?? 0.0
			let vo2Max = self.healthMgr.vo2Max ?? 0.0
			let best5KSecs = self.healthMgr.best5KDuration ?? 0
			let ageInYears = self.healthMgr.ageInYears ?? 0.0
			
			result[LONG_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.LONG_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[EASY_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.EASY_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[MARATHON_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.MARATHON_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[TEMPO_RUN_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.TEMPO_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
			result[FUNCTIONAL_THRESHOLD_PACE_STR] = calc.GetRunTrainingPace(zone: TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		}
		return result
	}
}
