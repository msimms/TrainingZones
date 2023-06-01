//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

let WORKOUT_INPUT_SPEED_RUN_PACE: String = "Speed Session Pace" // Pace for medium distance interfals
let WORKOUT_INPUT_SHORT_INTERVAL_RUN_PACE: String = "Short Interval Run Pace" // Pace for shorter track intervals
let WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE: String = "Functional Threshold Pace" // Pace that could be held for one hour, max effort
let WORKOUT_INPUT_TEMPO_RUN_PACE: String = "Tempo Run Pace"
let WORKOUT_INPUT_EASY_RUN_PACE: String = "Easy Run Pace"
let WORKOUT_INPUT_LONG_RUN_PACE: String = "Long Run Pace"

class ZonesVM : ObservableObject {
	var healthMgr: HealthManager = HealthManager()
	@Published var best5KSecs: Double?
	@Published var functionalThresholdPower: Double?

	init() {
		self.healthMgr.requestAuthorization()
	}

	func hasHrData() -> Bool {
		return self.healthMgr.restingHr != nil && self.healthMgr.maxHr != nil
	}

	func hasPowerData() -> Bool {
		return self.functionalThresholdPower != nil
	}

	func hasRunData() -> Bool {
		return self.healthMgr.vo2Max != nil || self.best5KSecs != nil
	}

	func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []

		guard (self.healthMgr.restingHr != nil && self.healthMgr.maxHr != nil && self.healthMgr.ageInYears != nil) else {
			return result
		}

		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalculateHeartRateZones(restingHr: self.healthMgr.restingHr!, maxHr: self.healthMgr.maxHr!, ageInYears: self.healthMgr.ageInYears!)

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
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

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}

	func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		let calc: ZonesCalculator = ZonesCalculator()
		let restingHr = self.healthMgr.restingHr ?? 0.0
		let maxHr = self.healthMgr.maxHr ?? 0.0
		let vo2Max = self.healthMgr.vo2Max ?? 0.0
		let best5KSecs = self.best5KSecs ?? 0.0
		let ageInYears = self.healthMgr.ageInYears ?? 0.0

		result[WORKOUT_INPUT_LONG_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.LONG_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		result[WORKOUT_INPUT_EASY_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.EASY_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		result[WORKOUT_INPUT_TEMPO_RUN_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.TEMPO_RUN_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		result[WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE] = calc.GetRunTrainingPace(zone: TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE, vo2Max: vo2Max, best5KSecs: best5KSecs, restingHr: restingHr, maxHr: maxHr, ageInYears: ageInYears)
		return result
	}
}
