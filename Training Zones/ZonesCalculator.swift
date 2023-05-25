//
//  ZonesCalculator.swift
//  Created by Michael Simms on 5/25/23.
//

import Foundation

let NUM_HR_ZONES = 5
let NUM_POWER_ZONES = 5

enum TrainingPaceType {
	case LONG_RUN_PACE
	case EASY_RUN_PACE
	case TEMPO_RUN_PACE
	case FUNCTIONAL_THRESHOLD_PACE
	case SPEED_RUN_PACE
	case SHORT_INTERVAL_RUN_PACE
};

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
		
		zones[0] = ftp * 0.55
		zones[1] = ftp * 0.75
		zones[2] = ftp * 0.90
		zones[3] = ftp * 1.05
		zones[4] = ftp * 1.20
		return zones
	}
	
	func GetRunTrainingPace(zoneNum: TrainingPaceType) -> Double {
		return 0.0
	}
}
