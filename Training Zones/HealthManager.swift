//
//  HealthManager.swift
//  Created by Michael Simms on 10/7/22.
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
import HealthKit
import CoreLocation

class HealthManager : ObservableObject {
	static let shared = HealthManager()

	private let healthStore = HKHealthStore()
	private var queryGroup: DispatchGroup = DispatchGroup() // tracks queries until they are completed
	private var powerSampleBuf: [HKQuantitySample] = []

	@Published var restingHr: Double? // Resting heart rate, from HealthKit
	@Published var estimatedMaxHr: Double? // Algorithmically estimated maximum heart rate
	@Published var vo2Max: Double? // VO2Max, from HealthKit
	@Published var ftp: Double? // Cycling threshold power, from HealthKit, in watts
	@Published var estimatedFtp: Double? // Algorithmically estimated cycling threshold power, in watts
	@Published var ageInYears: Double?
	@Published var best5KDuration: TimeInterval? // Best 5K (or greater) effort, in seconds
	@Published var best5KPace: Double? // Best 5K (or greater) effort, in pace
	@Published var best12MinuteEffort: Double? // Best 12 minute effort, in meters

	private init() {
	}
	
	func requestAuthorization() {
		
		// Check for HealthKit availability.
		guard HKHealthStore.isHealthDataAvailable() else {
			return
		}
		
		// Request authorization for things to read and write.
		let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!
		let birthdayType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
		let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
#if TARGET_OS_WATCH
		var readTypes = Set([heartRateType, restingHeartRateType, vo2MaxType, birthdayType, biologicalSexType])
		var writeTypes: Set<HKSampleType>? = nil
#else
		let routeType = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
		let workoutType = HKObjectType.workoutType()
		var readTypes = Set([heartRateType, restingHeartRateType, vo2MaxType, birthdayType, biologicalSexType, workoutType, routeType])
		var writeTypes: Set<HKSampleType>? = nil
#endif

		// Have to do this down here since there's a version check.
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let ftpType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)!
			readTypes.insert(ftpType)
			writeTypes = Set([ftpType])
		}
		
		// Request authorization for all the things we need from HealthKit.
		healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { result, error in
			do {
				try self.getAge()
			}
			catch {
				NSLog("Failed to read the age from HealthKit.")
			}
			do {
				try self.getRestingHr()
				try self.estimateMaxHr()
			}
			catch {
				NSLog("Failed to read heart rate information from HealthKit.")
			}
			do {
				try self.getVO2Max()
			}
			catch {
				NSLog("Failed to read the VO2Max from HealthKit.")
			}
			do {
				try self.getBestRecentEfforts()
			}
			catch {
				NSLog("Failed to read the workout history from HealthKit.")
			}
			do {
				try self.getFtp()
			}
			catch {
				NSLog("Failed to read the cycling FTP from HealthKit.")
			}
		}
	}

	func mostRecentQuantitySampleOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// Since we are interested in retrieving the user's latest sample, we sort the samples in descending
		// order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
		let timeSortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [timeSortDescriptor], resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				let sample = results!.first as! HKQuantitySample?
				callback(sample, error)
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func recentQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		let oneYear = (365.25 * 24.0 * 60.0 * 60.0)
		let startDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - oneYear)
		let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [.strictStartDate])

		let query = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func quantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantitySample?, Error?) -> ()) {
		
		// We are not filtering the data, and so the predicate is set to nil.
		let query = HKSampleQuery.init(sampleType: quantityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: { query, results, error in
			
			// Error case: Call the callback handler, passing nil for the results.
			if results == nil || results!.count == 0 {
				callback(nil, error ?? nil)
			}
			
			// Normal case: Call the callback handler with the results.
			else {
				for sample in results! {
					let quantitySample = sample as! HKQuantitySample?
					callback(quantitySample, error)
				}
			}
		})
		
		// Execute asynchronously.
		self.healthStore.execute(query)
	}

	func subscribeToQuantitySamplesOfType(quantityType: HKQuantityType, callback: @escaping (HKQuantity?, Date?, Error?) -> ()) -> HKQuery {

		let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options:HKQueryOptions.strictStartDate)
		let query = HKAnchoredObjectQuery.init(type: quantityType, predicate: datePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { query, addedObjects, deletedObjects, newAnchor, error in

			if addedObjects != nil {
				for sample in addedObjects! {
					if let quantitySample = sample as? HKQuantitySample {
						callback(quantitySample.quantity, quantitySample.endDate, error)
					}
				}
			}
		})

		query.updateHandler = { query, addedObjects, deletedObjects, newAnchor, error in
			for sample in addedObjects! {
				if let quantitySample = sample as? HKQuantitySample {
					callback(quantitySample.quantity, quantitySample.endDate, error)
				}
			}
		}

		// Execute asynchronously.
		self.healthStore.execute(query)

		// Background delivery.
		self.healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate, withCompletion: {(succeeded: Bool, error: Error!) in
		})

		return query
	}

	/// @brief Gets the user's age from HealthKit .
	func getAge() throws {
		let dateOfBirth = try self.healthStore.dateOfBirthComponents()
		let gregorianCalendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)!
		let tempDate = gregorianCalendar.date(from: dateOfBirth)

		if let birthDate = tempDate {
			let SECS_PER_YEAR = 365.25 * 24.0 * 60.0 * 60.0

			DispatchQueue.main.async {
				self.ageInYears = (Date.now.timeIntervalSince1970 - birthDate.timeIntervalSince1970) / SECS_PER_YEAR
			}
		}
	}

	/// @brief Gets the user's resting heart rate from HealthKit .
	func getRestingHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
		
		self.mostRecentQuantitySampleOfType(quantityType: hrType) { sample, error in
			if let restingHrSample = sample {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

				DispatchQueue.main.async {
					self.restingHr = restingHrSample.quantity.doubleValue(for: hrUnit)
				}
			}
		}
	}
	
	/// @brief Estimates the user's maximum heart rate from the last six months of HealthKit data.
	func estimateMaxHr() throws {
		let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		
		self.recentQuantitySamplesOfType(quantityType: hrType) { sample, error in
			if let hrSample = sample {
				let hrUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
				let hrValue = hrSample.quantity.doubleValue(for: hrUnit)

				if self.estimatedMaxHr == nil || hrValue > self.estimatedMaxHr! {
					DispatchQueue.main.async {
						self.estimatedMaxHr = hrValue
					}
				}
			}
		}
	}

	/// @brief Gets the user's VO2Max from HealthKit .
	func getVO2Max() throws {
		let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max)!

		self.mostRecentQuantitySampleOfType(quantityType: vo2MaxType) { sample, error in
			if let vo2MaxSample = sample {
				let kgmin = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())
				let mL = HKUnit.literUnit(with: .milli)
				let vo2MaxUnit = mL.unitDivided(by: kgmin)

				DispatchQueue.main.async {
					self.vo2Max = vo2MaxSample.quantity.doubleValue(for: vo2MaxUnit)
				}
			}
		}
	}

	func estimateFtp() throws {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let powerType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)!

			self.mostRecentQuantitySampleOfType(quantityType: powerType) { sample, error in
				if let powerSample = sample {
					let powerUnit: HKUnit = HKUnit.watt()

					// Add to the sample buffer.
					self.powerSampleBuf.append(powerSample)

					// Remove anything that falls outside of our 20 minute window.
					
					// Compute the average.

					if self.estimatedFtp == nil {
						DispatchQueue.main.async {
						}
					}
				}
			}
		}
	}
	
	func getFtp() throws {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			let powerType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)!
			
			self.mostRecentQuantitySampleOfType(quantityType: powerType) { sample, error in
				if let powerSample = sample {
					let powerUnit: HKUnit = HKUnit.watt()
					
					DispatchQueue.main.async {
						self.ftp = powerSample.quantity.doubleValue(for: powerUnit)
					}
				}
			}
		}
	}
	
	func setFtp() {
		if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
			if let tempFtp = self.ftp {
				let now = Date()
				let powerQuantity = HKQuantity.init(unit: HKUnit.watt(), doubleValue: tempFtp)
				let powerType = HKQuantityType.init(HKQuantityTypeIdentifier.cyclingFunctionalThresholdPower)
				let powerSample = HKQuantitySample.init(type: powerType, quantity: powerQuantity, start: now, end: now)

				self.healthStore.save(powerSample, withCompletion: {_,_ in })
			}
		}
	}

	/// @brief Gets the user's best 5K and 12 minute efforts from the last six months of HealthKit data.
	func getBestRecentEfforts() throws {
		let startDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 86400.0 * 7.0 * 26.0)
		let predicate = HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.running)
		let sortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierStartDate, ascending: false)
		let quantityType = HKWorkoutType.workoutType()
		let sampleQuery = HKSampleQuery.init(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, samples, error in
			
			if samples != nil {
				var tempBest5KDuration: TimeInterval? // Best 5K (or greater) effort, in seconds
				var tempBest12MinuteEffort: Double? // Best 12 minute effort, in meters
				var best5KPace: Double = 0.0 // Pace in seconds per meter

				for sample in samples! {
					if let workout = sample as? HKWorkout {
						if workout.startDate.timeIntervalSince1970 >= startDate.timeIntervalSince1970 {
							let distance = workout.totalDistance
							let duration = workout.duration

							if distance != nil {
								let distanceMeters = distance?.doubleValue(for: HKUnit.meter())
								let durationSecs = workout.duration
								let pace = workout.duration / distanceMeters!

								// Is this our best recent 5K?
								if distanceMeters! >= 5000.0 {
									if tempBest5KDuration == nil || pace <= best5KPace {
										best5KPace = pace
										tempBest5KDuration = durationSecs
									}
								}

								// Is this our best recent 12 minute effort? Effort has to be between 12:00 and 12:10 in duration.
								if duration >= 12 * 60 && duration <= (12 * 60) + 10 {
									if tempBest12MinuteEffort == nil || distanceMeters! >= self.best12MinuteEffort! {
										tempBest12MinuteEffort = distanceMeters
									}
								}
							}
						}
					}
				}

				DispatchQueue.main.async {
					self.best5KDuration = tempBest5KDuration
					self.best5KPace = best5KPace
					self.best12MinuteEffort = tempBest12MinuteEffort
				}
			}

			self.queryGroup.leave()
		})
		
		self.queryGroup.enter()
		self.healthStore.execute(sampleQuery)
	}

	/// @brief Blocks until all HealthKit queries have completed.
	func waitForHealthKitQueries() {
		self.queryGroup.wait()
	}
}
