// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

var univPredictArray = [0.0, 0.0]
var currentDataIndex = 0

var totalHappy = 0.0;
var totalSad = 0.0;

var numValuesInAverage = 0;

var determinedEmotion = ""

var beginPressed = false

import UIKit

// MARK: InferenceViewControllerDelegate Method Declarations
protocol InferenceViewControllerDelegate {

  /**
   This method is called when the user changes the stepper value to update number of threads used for inference.
   */
  func didChangeThreadCount(to count: Int)

}

class InferenceViewController: UIViewController {

  // MARK: Sections and Information to display
  private enum InferenceSections: Int, CaseIterable {
    case Results
    case InferenceInfo
  }

  private enum InferenceInfo: Int, CaseIterable {
    case Resolution
    case Crop
    case InferenceTime

    func displayString() -> String {

      var toReturn = ""

      switch self {
      case .Resolution:
        toReturn = "Resolution"
      case .Crop:
        toReturn = "Crop"
      case .InferenceTime:
        toReturn = "Inference Time"

      }
      return toReturn
    }
  }

  // MARK: Storyboard Outlets
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var threadStepper: UIStepper!
  @IBOutlet weak var stepperValueLabel: UILabel!

  // MARK: Constants
  private let normalCellHeight: CGFloat = 27.0
  private let separatorCellHeight: CGFloat = 42.0
  private let bottomSpacing: CGFloat = 21.0
  private let minThreadCount = 1
  private let bottomSheetButtonDisplayHeight: CGFloat = 44.0
  private let infoTextColor = UIColor.black
  private let lightTextInfoColor = UIColor(displayP3Red: 117.0/255.0, green: 117.0/255.0, blue: 117.0/255.0, alpha: 1.0)
  private let infoFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
  private let highlightedFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)

  // MARK: Instance Variables
  var inferenceResult: Result? = nil
  var wantedInputWidth: Int = 0
  var wantedInputHeight: Int = 0
  var resolution: CGSize = CGSize.zero
  var maxResults: Int = 0
  var threadCountLimit: Int = 0
  private var currentThreadCount: Int = 0

  // MARK: Delegate
  var delegate: InferenceViewControllerDelegate?

  // MARK: Computed properties
  var collapsedHeight: CGFloat {
    return normalCellHeight * CGFloat(maxResults - 1) + separatorCellHeight + bottomSheetButtonDisplayHeight

  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set up stepper
    threadStepper.isUserInteractionEnabled = true
    threadStepper.maximumValue = Double(threadCountLimit)
    threadStepper.minimumValue = Double(minThreadCount)
    threadStepper.value = Double(currentThreadCount)

  }

  // MARK: Buttion Actions
  /**
   Delegate the change of number of threads to View Controller and change the stepper display.
   */
  @IBAction func onClickThreadStepper(_ sender: Any) {

    delegate?.didChangeThreadCount(to: Int(threadStepper.value))
    currentThreadCount = Int(threadStepper.value)
    stepperValueLabel.text = "\(currentThreadCount)"
  }
}

// MARK: UITableView Data Source
extension InferenceViewController: UITableViewDelegate, UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {

    return InferenceSections.allCases.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    guard let inferenceSection = InferenceSections(rawValue: section) else {
      return 0
    }

    var rowCount = 0
    switch inferenceSection {
    case .Results:
      rowCount = maxResults
    case .InferenceInfo:
      rowCount = InferenceInfo.allCases.count
    }
    return rowCount
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

    var height: CGFloat = 0.0

    guard let inferenceSection = InferenceSections(rawValue: indexPath.section) else {
      return height
    }

    switch inferenceSection {
    case .Results:
      if indexPath.row == maxResults - 1 {
        height = separatorCellHeight + bottomSpacing
      }
      else {
        height = normalCellHeight
      }
    case .InferenceInfo:
      if indexPath.row == InferenceInfo.allCases.count - 1 {
        height = separatorCellHeight + bottomSpacing
      }
      else {
        height = normalCellHeight
      }
    }
    return height
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "INFO_CELL") as! InfoCell

    guard let inferenceSection = InferenceSections(rawValue: indexPath.section) else {
      return cell
    }

    var fieldName = ""
    var info = ""
    var font = infoFont
    var color = infoTextColor

    switch inferenceSection {
    case .Results:

      let tuple = displayStringsForResults(atRow: indexPath.row)
      fieldName = tuple.0
      info = tuple.1

      if indexPath.row == 0 {
        font = highlightedFont
        color = infoTextColor
      }
      else {
        font = infoFont
        color = lightTextInfoColor
      }

    case .InferenceInfo:
      let tuple = displayStringsForInferenceInfo(atRow: indexPath.row)
      fieldName = tuple.0
      info = tuple.1

    }
    cell.fieldNameLabel.font = font
    cell.fieldNameLabel.textColor = color
    cell.fieldNameLabel.text = fieldName
    cell.infoLabel.text = info
    print(fieldName)
    print(info)
    
    let faceTag = matches(for: "[0-9] happy", in: fieldName)
    
    var dataOnly = matches(for: "[0-9]?[0-9].[0-9][0-9]%", in: info)

    if (faceTag.isEmpty == false && !(dataOnly.isEmpty))
    {
        var insertString = (dataOnly[0] as String)
        insertString = String(insertString.dropLast())
        univPredictArray.remove(at: 0)
        univPredictArray.insert(Double(insertString)!, at: 0)
    }
    else if (!(dataOnly.isEmpty))
    {
        var insertString = (dataOnly[0] as String)
        insertString = String(insertString.dropLast())
        univPredictArray.remove(at: 1)
        univPredictArray.insert(Double(insertString)!, at: 1)
    }
    if(beginPressed == true)
    {
        addDataAndCheckIfDone()
    }

        
    return cell
  }

    func addDataAndCheckIfDone() -> Void
    {
        if (!(univPredictArray[0] == 0.0 || univPredictArray[1] == 0.0))
        {
            totalHappy += univPredictArray[0]
            totalSad += univPredictArray[1]
            numValuesInAverage += 1
        }
        
        if (numValuesInAverage >= 30)
        {
            let averageHappy = totalHappy / 10.0
            let averageSad = totalSad / 10.0
            
            if(averageHappy > averageSad)
            {
                determinedEmotion = "happy"
            }
            else
            {
                determinedEmotion = "sad"
            }
            
            numValuesInAverage = 0
            totalHappy = 0
            totalSad = 0
            univPredictArray = [0.0, 0.0]
            currentDataIndex = 0
            beginPressed = false
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "inspirationScreen") as UIViewController
            present(nextViewController, animated: true, completion: nil)
        }
    }
    
    func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

  // MARK: Format Display of information in the bottom sheet
  /**
   This method formats the display of the inferences for the current frame.
   */
  func displayStringsForResults(atRow row: Int) -> (String, String) {

    var fieldName: String = ""
    var info: String = ""

    guard let tempResult = inferenceResult, tempResult.inferences.count > 0 else {

      if row == 1 {
        fieldName = "No Results"
        info = ""
      }
      else {
        fieldName = ""
        info = ""
      }
      return (fieldName, info)
    }

    if row < tempResult.inferences.count {
      let inference = tempResult.inferences[row]
      fieldName = inference.label
      info =  String(format: "%.2f", inference.confidence * 100.0) + "%"
    }
    else {
      fieldName = ""
      info = ""
    }

    return (fieldName, info)
  }

  /**
   This method formats the display of additional information relating to the inferences.
   */
  func displayStringsForInferenceInfo(atRow row: Int) -> (String, String) {

    var fieldName: String = ""
    var info: String = ""

    guard let inferenceInfo = InferenceInfo(rawValue: row) else {
      return (fieldName, info)
    }

    fieldName = inferenceInfo.displayString()

    switch inferenceInfo {
    case .Resolution:
      info = "\(Int(resolution.width))x\(Int(resolution.height))"
    case .Crop:
      info = "\(wantedInputWidth)x\(wantedInputHeight)"
    case .InferenceTime:
      guard let finalResults = inferenceResult else {
        info = "0ms"
        break
      }
      info = String(format: "%.2fms", finalResults.inferenceTime)
    }

    return(fieldName, info)
  }
}


