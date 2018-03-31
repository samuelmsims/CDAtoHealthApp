/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import HealthKit
import Fuzi

class ProfileDataStore {

  class func getAgeSexAndBloodType() throws -> (age: Int,
                                                biologicalSex: HKBiologicalSex,
                                                bloodType: HKBloodType) {
    
    
    let healthKitStore = HKHealthStore()
                                                    
    do {
        
        
      //1. This method throws an error if these data are not available.
      let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
      let biologicalSex =       try healthKitStore.biologicalSex()
      let bloodType =           try healthKitStore.bloodType()
      
      //2. Use Calendar to calculate age.
      let today = Date()
      let calendar = Calendar.current
      let todayDateComponents = calendar.dateComponents([.year],
                                                        from: today)
      let thisYear = todayDateComponents.year!
      let age = thisYear - birthdayComponents.year!
      
      //3. Unwrap the wrappers to get the underlying enum values.
      let unwrappedBiologicalSex = biologicalSex.biologicalSex
      let unwrappedBloodType = bloodType.bloodType
      
      return (age, unwrappedBiologicalSex, unwrappedBloodType)
    }
    catch let error {
        print(error)
        return (35, HKBiologicalSex.female, HKBloodType.abNegative)
    }
  }
  
  class func getMostRecentSample(for sampleType: HKSampleType,
                                 completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
    
    //1. Use HKQuery to load the most recent samples.
    let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                          end: Date(),
                                                          options: .strictEndDate)
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                          ascending: false)
    
    let limit = 1
    
    let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                    predicate: mostRecentPredicate,
                                    limit: limit,
                                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
    
      //2. Always dispatch to the main thread when complete.
      DispatchQueue.main.async {
        
        guard let samples = samples,
              let mostRecentSample = samples.first as? HKQuantitySample else {
                
              completion(nil, error)
              return
        }
        
        completion(mostRecentSample, nil)
      }
    }
    
    HKHealthStore().execute(sampleQuery)
  }
  
  class func saveBodyMassIndexSample(bodyMassIndex: Double, date: Date) {
    
    //1.  Make sure the body mass type exists
    guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
      fatalError("Body Mass Index Type is no longer available in HealthKit")
    }
    
    //2.  Use the Count HKUnit to create a body mass quantity
    let bodyMassQuantity = HKQuantity(unit: HKUnit.count(),
                                      doubleValue: bodyMassIndex)
    
    let bodyMassIndexSample = HKQuantitySample(type: bodyMassIndexType,
                                               quantity: bodyMassQuantity,
                                               start: date,
                                               end: date)
    
    //3.  Save the same to HealthKit
    HKHealthStore().save(bodyMassIndexSample) { (success, error) in
      
      if let error = error {
        print("Error Saving BMI Sample: \(error.localizedDescription)")
      } else {
        print("Successfully saved BMI Sample")
      }
    }
  }
    
  class func saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier,  indexValue: Double, date: Date, idxType: HKUnit) {
    
        let healthKitStore = HKHealthStore()
    
        // Make sure the type exists
        guard let indexType = HKQuantityType.quantityType(forIdentifier: qtyType) else {
            fatalError("Index Type is no longer available in HealthKit")
        }
        
        //Use the Count HKUnit to create a quantity
        let indxQuantity = HKQuantity(unit: idxType,  doubleValue: indexValue)
    
    
        //check to see if sample exist
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil)
    
        let idxSample = HKQuantitySample(type: indexType,
                                         quantity: indxQuantity,
                                         start: date,
                                         end: date)
    
        let dupCheckquery = HKSampleQuery(sampleType: indexType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's sample. The error was: \(String(describing: error?.localizedDescription))");
            }
            
            //if not samples found then create inital record
            if (samples.count == 0) {
                HKHealthStore().save(idxSample) { (success, error) in
                    
                    if let error = error {
                        print("Error  Sample: \(error.localizedDescription)")
                    } else {
                        print("Successfully saved Sample")
                    }
                }
                
            }
            
            //check for duplicates
            for sample in samples {
                if (sample.quantity == indxQuantity){
                    print("Sample already defined.  Skipping: " + indexType.description + " Date: " + sample.startDate.description)
                }
                else{
                    HKHealthStore().save(idxSample) { (success, error) in
                        
                        if let error = error {
                            print("Error  Sample: \(error.localizedDescription)")
                        } else {
                            print("Successfully saved Sample")
                            //updatexmlConvStatusText(indexType as String + " updated!")
                        }
                    }
                }
            }
            
        }
    
        healthKitStore.execute(dupCheckquery)
    
    }
  
  class func convertCCDXMLfunc() {
    
    let healthKitStore = HKHealthStore()
    
    guard let cdaType = HKObjectType.documentType(forIdentifier: .CDA) else {
        fatalError("Unable to create a CDA document type.")
    }

    //read for cda documents. they can be more than one
    
    let cdaQuery2 = HKDocumentQuery(documentType: cdaType, predicate: nil, limit:
    1, sortDescriptors: nil, includeDocumentData: true) { query, samples,
        done, error in
        
        if done {
            return
        }
        
        print ("processing CDA file")
        
        guard let cdaDatasamples = samples as? [HKCDADocumentSample] else {fatalError("Unable to create a CDA sample.")}
        
        guard let healthDocumentData = cdaDatasamples.first?.document?.documentData else {fatalError("Unable to create a CDA data.")}
        
        let text = NSString(data: healthDocumentData, encoding: String.Encoding.utf8.rawValue) as! String
        
        
        //process document xml
        ImportCDAXML(XMLString: text)
    
    }
    
    healthKitStore.execute(cdaQuery2)
    
  }
  
    
  class func ImportCDAXML(XMLString: String){
    
    do{
        let doc = try XMLDocument(string: XMLString, encoding: String.Encoding.utf8)
        
        //parse document
        
        if let root = doc.root {
            if let root_element_name = root.tag, root_element_name == "ClinicalDocument" {
                
                //set prefix for xpath filtering
                
                doc.definePrefix("cda", defaultNamespace: "urn:hl7-org:v3")
                
                //check for vital sections via xpath.  could be a a better way bu this is what I came up with
                
                if doc.xpath("/cda:ClinicalDocument/cda:component/cda:structuredBody/cda:component/cda:section/cda:templateId[@root='2.16.840.1.113883.10.20.22.2.4']").first != nil {
                   
                    print("Found patient vitals")
                    
                    for (index, element) in doc.xpath("/cda:ClinicalDocument/cda:component/cda:structuredBody/cda:component/cda:section/cda:entry/cda:organizer/cda:component/cda:observation").enumerated(){
                        
                        //this section is for vitals only
                        
                        if (element.description as NSString).contains("2.16.840.1.113883.10.20.22.4.27"){
                            
                            //format effect date
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                           
                            let strDate = element.firstChild(tag: "effectiveTime")?.attr("value") as String?
                            
                            let yrlowerBound = String.Index(encodedOffset: 0)
                            let yrupperBound = String.Index(encodedOffset: 4)
                            let year = strDate![yrlowerBound..<yrupperBound]
        
                            let lowerBound = String.Index(encodedOffset: 4)
                            let upperBound = String.Index(encodedOffset: 6)
                            let month = strDate![lowerBound..<upperBound]
        
                            let dlowerBound = String.Index(encodedOffset: 6)
                            let dupperBound = String.Index(encodedOffset: 8)
                            let day = strDate![dlowerBound..<dupperBound]
                            
                            let dateString = (year + "-" + month + "-" + day)
                            
                            let recdate = dateFormatter.date(from: dateString)! as NSDate
                           
                            let qtyValue = element.firstChild(tag: "value")?.attr("value") as! NSString
                            
                            if (element.description as NSString).contains("weight"){
                                saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier.bodyMass,  indexValue: qtyValue.doubleValue, date: recdate as Date, idxType: HKUnit.pound())
                            }
                            
                            
                            if (element.description as NSString).contains("bmi"){
                                saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier.bodyMassIndex,  indexValue: qtyValue.doubleValue, date: recdate as Date, idxType: HKUnit.count())
                            }
                            
                            if (element.description as NSString).contains("height"){
                                saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier.height, indexValue: qtyValue.doubleValue, date: recdate as Date, idxType: HKUnit.inch())
                            }
                            
                            
                            if (element.description as NSString).contains("temperature"){
                                saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier.bodyTemperature, indexValue: qtyValue.doubleValue, date: recdate as Date, idxType: HKUnit.degreeFahrenheit())
                            }

                            if (element.description as NSString).contains("heart rate"){
                                
                                if #available(iOS 11.0, *) {
                                  //  let unit = HKUnit.count().unitDivided(by: HKUnit.count())
                                    
                                    saveHKQuantitySample(qtyType: HKQuantityTypeIdentifier.heartRate, indexValue: qtyValue.doubleValue, date: recdate as Date, idxType: HKUnit.count().unitDivided(by: HKUnit.minute()))
                                } else {
                                    // Fallback on earlier versions
                                }
                            }
                            
                        }
                    }
                    
                    
                }
                

                
                
            }
            
        }
        
    }
    catch {}
    }
 
    
    
}

