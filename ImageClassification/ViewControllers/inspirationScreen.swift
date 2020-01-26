//
//  inspirationScreen.swift
//  
//
//  Created by Jonathan Davies on 1/26/20.
//

import UIKit

let happyInpiration = ["stop smirking jackass — we get it, you’re thriving. you know who else thrive like u do? - Cher", "literally glOwing today — ok QueEn go get that bread", "your fit is fire today — try not to instantaneously combust", "lookin’ like a snacc — who’s tryna smash?", "those eyelshes could rake up LeavES — any she/he/they would be LuckY to have u", "can i get a YEET for the WHEAT??? bc i think i love your look more than i love bread"]
let sadInpiration = ["why the long face? ur doing amazing sweetie", "blue as a smurf :( remember that the gays stand behind you always", "remember we’re all here for you! every letter in LGBTQIA+ is here for you", "dont cry!!! if you cry ill cry!!!", "your eyebrows are en pointe. dont scrunch them!"]

class inspirationScreen: UIViewController {
    @IBOutlet weak var inspirationText: UILabel!
    @IBOutlet weak var moodText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if determinedEmotion == "happy"
        {
            inspirationText.text = happyInpiration.randomElement()
            moodText.text = "You seem really happy today!"
        }
        else if determinedEmotion == "sad"
        {
            inspirationText.text = sadInpiration.randomElement()
            moodText.text = "Looking kind of sad today..."
        }
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
