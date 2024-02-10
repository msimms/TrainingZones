//
//  ZonesCalculator.swift
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

import Foundation

let NUM_HR_ZONES = 5
let NUM_POWER_ZONES = 6

let HR_ALGORITHM_NAME_AGE = "Estimated Maximum Heart Rate"
let HR_ALGORITHM_NAME_MAX_HR = "Actual Maximum Heart Rate"
let HR_ALGORITHM_NAME_HR_RESERVE = "Heart Rate Reserve (Karvonen Formula)"

let RUN_PACE_ALGORITHM_NAME_COOPER_TEST = "Cooper Test"
let RUN_PACE_ALGORITHM_NAME_BEST_5K = "Best Recent 5K"
let RUN_PACE_ALGORITHM_NAME_HR = "Heart Rate"
let RUN_PACE_ALGORITHM_NAME_VO2_MAX = "VO2 Max"

class ZonesCalculator {
	func EstimateMaxHrFromAge(ageInYears: Double) -> Double {
		// Use the Oakland nonlinear formula to estimate based on age.
		return 192.0 - (0.007 * (ageInYears * ageInYears))
	}
	
	func CalculateHeartRateZones(restingHr: Double, maxHr: Double, ageInYears: Double) -> ([Double], String) {
		var zones = Array(repeating: 0.0, count: NUM_HR_ZONES)
		var algorithmName: String = ""

		// If given resting and max heart rates, use the Karvonen formula for determining zones based on hr reserve.
		if restingHr > 1.0 && maxHr > 1.0 {
			zones[0] = ((maxHr - restingHr) * 0.60) + restingHr
			zones[1] = ((maxHr - restingHr) * 0.70) + restingHr
			zones[2] = ((maxHr - restingHr) * 0.80) + restingHr
			zones[3] = ((maxHr - restingHr) * 0.90) + restingHr
			zones[4] = maxHr
			algorithmName = HR_ALGORITHM_NAME_HR_RESERVE
		}

		// Maximum heart rate, but no resting heart rate.
		else if maxHr > 1.0 {
			zones[0] = maxHr * 0.60
			zones[1] = maxHr * 0.70
			zones[2] = maxHr * 0.80
			zones[3] = maxHr * 0.90
			zones[4] = maxHr
			algorithmName = HR_ALGORITHM_NAME_MAX_HR
		}

		// No heart rate information, estimate it based on age and then generate the zones.
		else {
			let maxHr = EstimateMaxHrFromAge(ageInYears: ageInYears)
			zones[0] = maxHr * 0.60
			zones[1] = maxHr * 0.70
			zones[2] = maxHr * 0.80
			zones[3] = maxHr * 0.90
			zones[4] = maxHr
			algorithmName = HR_ALGORITHM_NAME_AGE
		}

		return (zones, algorithmName)
	}

	func CalcuatePowerZones(ftp: Double) -> [Double] {
		var zones = Array(repeating: 0.0, count: NUM_POWER_ZONES)
		
		// Dr. Andy Coggan 7 zone model
		// Zone 1 - Active Recovery - Less than 55% of FTP
		// Zone 2 - Endurance - 55% to 74% of FTP
		// Zone 3 - Tempo - 75% to 89% of FTP
		// Zone 4 - Lactate Threshold - 90% to 104% of FTP
		// Zone 5 - VO2 Max - 105% to 120% of FTP
		// Zone 6 - Anaerobic Capacity - More than 120% of FTP
		// Zone 6 is really anything over 120%,
		// Zone 7 is neuromuscular (i.e., shorts sprints at no specific power)
		zones[0] = ftp * 0.549
		zones[1] = ftp * 0.75
		zones[2] = ftp * 0.90
		zones[3] = ftp * 1.05
		zones[4] = ftp * 1.20
		zones[5] = ftp * 1.50
		return zones
	}

	func CalculateRunTrainingPaces(vo2Max: Double, best5KSecs: Double, cooperTestMeters: Double, restingHr: Double, maxHr: Double, ageInYears: Double) -> ([TrainingPaceType:Double], String) {
		let paceCalc: TrainingPlaceCalculator = TrainingPlaceCalculator()
		var paces: Dictionary<TrainingPaceType, Double> = [:]
		var algorithmName: String = ""

		// First choice: Cooper Test.
		if cooperTestMeters > 100.0 {
			paces = paceCalc.CalcFromUsingCooperTest(cooperTestMeters: cooperTestMeters)
			algorithmName = RUN_PACE_ALGORITHM_NAME_COOPER_TEST
		}

		// Next choice: results of a recent hard effort.
		else if best5KSecs > 600.0 {
			paces = paceCalc.CalcFromRaceDistanceInMeters(raceDurationSecs: best5KSecs, raceDistanceMeters: 5000.0)
			algorithmName = RUN_PACE_ALGORITHM_NAME_BEST_5K
		}
		
		// Next choice: from heart rate.
		else if restingHr > 1.0 && maxHr > 1.0 {
			paces = paceCalc.CalcFromHR(restingHr: restingHr, maxHr: maxHr)
			algorithmName = RUN_PACE_ALGORITHM_NAME_HR
		}
		
		// Next method: VO2Max
		// This is only last because watch VO2Max can be kinda bad.
		else if vo2Max > 0.0 {
			paces = paceCalc.CalcFromVO2Max(vo2max: vo2Max)
			algorithmName = RUN_PACE_ALGORITHM_NAME_VO2_MAX
		}
		
		return (paces, algorithmName)
	}

	func GetRunTrainingPace(zone: TrainingPaceType, paces: [TrainingPaceType:Double] ) -> Double {
		if let result = paces[zone] {
			return result
		}

		return 0.0
	}
}
