//
//  TrainingPlaceCalculator.swift
//  Created by Michael Simms on 5/25/23.
//

import Foundation

class TrainingPlaceCalculator {

	func ConvertToSpeed(vo2: Double) -> Double {
		return 29.54 + 5.000663 * vo2 - 0.007546 * vo2 * vo2;
	}
	
	// Give the athlete's VO2Max, returns the suggested long run, easy run, tempo run, and speed run paces.
	func CalcFromVO2Max(vo2max: Double) -> Dictionary<TrainingPaceType, Double> {
		// Percentage of VO2 Max; from the USATF Coaches Education Program’s
		// 800 meters 120-136%
		// 1500 meters 110-112%
		// 3000 meter 100-102%
		// 5000 meters 97-100%
		// 10000 meters 88-92%
		// Half Marathon 85-88%%
		// Marathon 82-85%
	
		var longRunPace: Double = vo2max * 0.6
		var easyPace: Double = vo2max * 0.7
		var tempoPace: Double = vo2max * 0.88
		var functionalThresholdPace: Double = vo2max
		var speedPace: Double = vo2max * 1.1
		var shortIntervalPace: Double = vo2max * 1.15
	
		longRunPace = self.ConvertToSpeed(vo2: longRunPace)
		easyPace = self.ConvertToSpeed(vo2: easyPace)
		tempoPace = self.ConvertToSpeed(vo2: tempoPace)
		functionalThresholdPace = self.ConvertToSpeed(vo2: functionalThresholdPace)
		speedPace = self.ConvertToSpeed(vo2: speedPace)
		shortIntervalPace = self.ConvertToSpeed(vo2: shortIntervalPace)
	
		var paces: Dictionary<TrainingPaceType, Double> = [:]
		paces[TrainingPaceType.LONG_RUN_PACE] = longRunPace
		paces[TrainingPaceType.EASY_RUN_PACE] = easyPace
		paces[TrainingPaceType.TEMPO_RUN_PACE] = tempoPace
		paces[TrainingPaceType.FUNCTIONAL_THRESHOLD_PACE] = functionalThresholdPace
		paces[TrainingPaceType.SPEED_RUN_PACE] = speedPace
		paces[TrainingPaceType.SHORT_INTERVAL_RUN_PACE] = shortIntervalPace
		return paces
	}

	func CalcFromRaceDistanceInMeters(restingHr: Double, maxHr: Double, raceDurationSecs: Double, raceDistanceMeters: Double) -> Dictionary<TrainingPaceType, Double> {
		let v02MaxCalc: VO2MaxCalculator = VO2MaxCalculator()
		let vo2max = v02MaxCalc.EstimateVO2MaxFromHeartRate(maxHR: maxHr, restingHR: restingHr)
		return self.CalcFromVO2Max(vo2max: vo2max)
	}

	func CalcFromHR(restingHr: Double, maxHr: Double) -> Dictionary<TrainingPaceType, Double> {
		var paces: Dictionary<TrainingPaceType, Double> = [:]
		return paces
	}
}
