//
//  ZonesVM.swift
//  Created by Michael Simms on 1/24/23.
//

import Foundation

class ZonesVM {
	static func hasHrData() -> Bool {
		return true
	}

	static func hasPowerData() -> Bool {
		return true
	}

	static func hasRunData() -> Bool {
		return true
	}

	static func GetRunTrainingPace(zoneNum: UInt8) -> Double {
		return 0.0
	}

	static func listHrZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalculateHeartRateZones(restingHr: 49.0, maxHr: 188.0, ageInYears: 49.5)

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}
	
	static func listPowerZones() -> Array<Bar> {
		var result: Array<Bar> = []
		let calc: ZonesCalculator = ZonesCalculator()
		let zones = calc.CalcuatePowerZones(ftp: 220.0)

		for zoneNum in 0...4 {
			let zoneValue = zones[zoneNum]
			result.append(Bar(value: zoneValue, label: String(Int(zoneValue))))
		}
		return result
	}
	
	static func listRunTrainingPaces() -> Dictionary<String, Double> {
		var result: Dictionary<String, Double> = [:]
		
		/*result[WORKOUT_INPUT_LONG_RUN_PACE] = GetRunTrainingPace(LONG_RUN_PACE)
		result[WORKOUT_INPUT_EASY_RUN_PACE] = GetRunTrainingPace(EASY_RUN_PACE)
		result[WORKOUT_INPUT_TEMPO_RUN_PACE] = GetRunTrainingPace(TEMPO_RUN_PACE)
		result[WORKOUT_INPUT_FUNCTIONAL_THRESHOLD_PACE] = GetRunTrainingPace(FUNCTIONAL_THRESHOLD_PACE) */
		return result
	}
}
