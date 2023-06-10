//
//  ZonesCalculator.swift
//  Created by Michael Simms on 5/25/23.
//

import Foundation

let NUM_HR_ZONES = 5
let NUM_POWER_ZONES = 6

class ZonesCalculator {
	func EstimateMaxHrFromAge(ageInYears: Double) -> Double {
		// Use the Oakland nonlinear formula to estimate based on age.
		return 192.0 - (0.007 * (ageInYears * ageInYears))
	}
	
	func CalculateHeartRateZones(restingHr: Double, maxHr: Double, ageInYears: Double) -> [Double] {
		var zones = Array(repeating: 0.0, count: NUM_HR_ZONES)

		// If given resting and max heart rates, use the Karvonen formula for determining zones based on hr reserve.
		if restingHr > 1.0 && maxHr > 1.0 {
			zones[0] = ((maxHr - restingHr) * 0.60) + restingHr
			zones[1] = ((maxHr - restingHr) * 0.70) + restingHr
			zones[2] = ((maxHr - restingHr) * 0.80) + restingHr
			zones[3] = ((maxHr - restingHr) * 0.90) + restingHr
			zones[4] = maxHr
		}

		// Maximum heart rate, but no resting heart rate.
		else if maxHr > 1.0 {
			zones[0] = maxHr * 0.60
			zones[1] = maxHr * 0.70
			zones[2] = maxHr * 0.80
			zones[3] = maxHr * 0.90
			zones[4] = maxHr;
		}

		// No heart rate information, estimate it based on age and then generate the zones.
		else {
			let maxHr = EstimateMaxHrFromAge(ageInYears: ageInYears)
			zones[0] = maxHr * 0.60
			zones[1] = maxHr * 0.70
			zones[2] = maxHr * 0.80
			zones[3] = maxHr * 0.90
			zones[4] = maxHr
		}

		return zones
	}

	func CalcuatePowerZones(ftp: Double) -> [Double] {
		var zones = Array(repeating: 0.0, count: NUM_POWER_ZONES)
		
		// Dr. Andy Coggan 6 zone model, last zone is anything over
		zones[0] = ftp * 0.55
		zones[1] = ftp * 0.75
		zones[2] = ftp * 0.90
		zones[3] = ftp * 1.05
		zones[4] = ftp * 1.20
		zones[5] = ftp * 2.00
		return zones
	}

	func GetRunTrainingPace(zone: TrainingPaceType, vo2Max: Double, best5KSecs: Double, restingHr: Double, maxHr: Double, ageInYears: Double) -> Double {
		let paceCalc: TrainingPlaceCalculator = TrainingPlaceCalculator()
		var paces: Dictionary<TrainingPaceType, Double> = [:]

		// Preferred method: VO2Max
		if vo2Max > 0.0 {
			paces = paceCalc.CalcFromVO2Max(vo2max: vo2Max)
		}
		
		// Second choice method: results of a recent hard effort.
		else if best5KSecs > 600.0 {
			paces = paceCalc.CalcFromRaceDistanceInMeters(restingHr: restingHr, maxHr: maxHr, raceDurationSecs: best5KSecs, raceDistanceMeters: 5000.0)
		}

		// Third choice method: from heart rate.
		else if restingHr > 1.0 && maxHr > 1.0 {
			paces = paceCalc.CalcFromHR(restingHr: restingHr, maxHr: maxHr)
		}

		if let result = paces[zone] {
			return result
		}

		return 0.0
	}
}
