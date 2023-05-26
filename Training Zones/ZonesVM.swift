//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

let WORKOUT_INPUT_SPEED_RUN_PACE: String = "Speed Session Pace"         // Pace for medium distance interfals
let WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE: String = "Short Interval Run Pace"    // Pace for shorter track intervals
let WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE: String = "Functional Threshold Pace"  // Pace that could be held for one hour, max effort
let WORKOUT_INPUT_TEMPO_RUN_PACE: String = "Tempo Run Pace"
let WORKOUT_INPUT_EASY_RUN_PACE: String = "Easy Run Pace"
let WORKOUT_INPUT_LONG_RUN_PACE: String = "Long Run Pace"

class ZonesVM {
	var healthMgr: HealthManager = HealthManager()
	var best5KSecs: Double = 1200.0
	var restingHr: Double = 49.0
	var maxHr: Double = 188.0
	var ageInYears: Double = 49.5

	func hasHrData() -> Bool {
		return true
	}

	func hasPowerData() -> Bool {
		return true
	}

	func hasRunData() -> Bool {
		return true
	}

	func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalculateHeartRateZones(restingHr: self.restingHr, maxHr: self.maxHr, ageInYears: self.ageInYears)

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}

	func listPowerZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalcuatePowerZones(ftp: 220.0)

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}

	func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		let calc: ZonesCalculator = ZonesCalculator()

		result[WORKOUT_INPUT_LONG_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.LONG_RUN_PACE, best5KSecs: self.best5KSecs, restingHr: self.restingHr, maxHr: self.maxHr, ageInYears: self.ageInYears)
		result[WORKOUT_INPUT_EASY_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.EASY_RUN_PACE, best5KSecs: self.best5KSecs, restingHr: self.restingHr, maxHr: self.maxHr, ageInYears: self.ageInYears)
		result[WORKOUT_INPUT_TEMPO_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.TEMPO_RUN_PACE, best5KSecs: self.best5KSecs, restingHr: self.restingHr, maxHr: self.maxHr, ageInYears: self.ageInYears)
		result[WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE, best5KSecs: self.best5KSecs, restingHr: self.restingHr, maxHr: self.maxHr, ageInYears: self.ageInYears)
		return result
	}
}
