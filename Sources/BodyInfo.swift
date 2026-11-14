import Foundation

/// "Body mein kya ho raha hai" — short, honest notes per step.
extension PhaseKind {
    var bodyInfo: [(title: String, text: String)] {
        switch self {
        case .settle:
            return [
                ("Hawa", "Naak se andar, naak ke baal aur nami use filter aur halka garam karte hain. Isliye andar thandak lagti hai, bahar thodi garmi."),
                ("Body mein", "Workout ke baad heart rate dheere-dheere neeche aa raha hai. Ek-ek hissa dheela karne se muscles se brain tak 'sab safe hai' ka signal jaata hai."),
                ("Mann mein", "Saans ko sirf dekhna attention ko 'abhi' mein laata hai. Dimaag list banayega, wo normal hai. Wapas aana hi kaam hai."),
            ]
        case .nadi:
            return [
                ("Hawa ka raasta", "Ek nathune se andar → naak ke andar ki chambers (yahan hawa garam, nam aur saaf hoti hai) → gale ke peeche → windpipe → do phephdon mein, jahan chhoti-chhoti thailiyon mein oxygen khoon mein jaati hai."),
                ("Pet kyun bahar aata hai", "Phephdon ke neeche ek dome jaisi muscle hai, diaphragm. Saans andar lete waqt wo neeche khisakta hai, pet ko bahar dhakelta hai. Chhaati nahi, pet. Yahi 'pet se saans' hai."),
                ("Nervous system", "Dheemi saans, khaaskar lambi exhale, vagus nerve ke through 'rest and digest' wale hisse ko jagati hai. Heart rate thoda kam hota hai, body alarm mode se bahar aati hai."),
                ("Naak ka bonus", "Naak ke sinus nitric oxide banate hain jo naak se saans lene pe andar jaata hai. Ye khoon ki naliyon ko thoda khol ke oxygen lene mein madad karta hai."),
                ("Yogic nazar", "Baayaan nathuna iḍā: shaant, thandi urja. Daayaan piṅgalā: garam, active urja. Dono barabar hon toh prana beech ki suṣumnā mein aata hai. (Hatha Yoga Pradipika 2.4–2.10)"),
            ]
        case .bhramari:
            return [
                ("Awaaz kahan se", "Gale mein voice box (larynx) ki vocal cords kaanpti hain. Hont band hain, isliye awaaz bahar nahi jaati, khopdi ke andar goonjti hai."),
                ("Vibration", "Ye kampan haddiyon ke through maathe, gaalon, sinus aur khopdi tak phailta hai. Kaan band hain, isliye tumhe ye andar se aur zyada sunai deta hai."),
                ("Body mein", "Gungunaane se exhale apne aap lamba ho jaata hai, jo nervous system ko shaant karta hai. Research mein humming se naak mein nitric oxide kai guna badhta dikha hai."),
                ("Baad ki khamoshi", "Awaaz rukne ke baad jo chuppi hai, wo bhramari ka asli hissa hai. Bahar ki awaaz band, dhyaan apne aap andar mud jaata hai."),
            ]
        case .witness:
            return [
                ("Dimaag mein", "Jab mann bhatakta hai, brain ka 'default mode network' chalta hai: plan, yaad, chinta. Ye bura nahi, bas aadat hai."),
                ("Rep", "Jis pal tum notice karte ho 'main bhatak gaya tha', attention wala network kaam karta hai. Wapas aana ek rep hai, jaise gym mein. 30 baar bhatke, 30 baar lautey: 30 reps."),
                ("Naam dena", "Emotion ko ek shabd mein naam dene se ('darr', 'gussa') uski pakad halki hoti hai. Isko research mein 'affect labeling' kehte hain."),
                ("Saakshi", "Thoughts aate-jaate hain. Jo dekh raha hai, wo wahin hai. Ashtavakra Gita 1.7. Saanp ki gaanth khud khulti hai jab tum sirf dekhte ho."),
            ]
        case .visualize:
            return [
                ("Roshni", "Dheemi saans ke saath ek garam, shaant image pe tikna body ko usi 'rest' mode mein rakhta hai jo nadi shodhana ne banaya. Image ek anchor hai, jaise saans."),
                ("Rehearsal", "Kisi kaam ko mann mein saaf-saaf dekhne se brain ke wahi hisse jaagte hain jo asli kaam mein. Athletes aur performers isi ko mental rehearsal kehte hain."),
                ("Mushkil pal", "Stress wale pal ko shaant body ke saath pehle se dekh lena ek naya raasta banata hai. Asli pal mein 'ek saans' wala jawab thoda zyada paas hota hai."),
                ("Mic", "Stage se pehle ka darr aur excitement body mein ek jaise dikhte hain: tez dil, garmi. Pair zameen pe aur pet se saans, us energy ko sambhaalne ka tareeka hai."),
            ]
        case .sankalpa:
            return [
                ("Kyun abhi", "Is waqt body shaant hai aur mann dheema. Is state mein ek chhoti, seedhi line dohrana use yaad mein baithaata hai."),
                ("Kaise", "Dheere. Har shabd pe ek pal. Awaaz mein nahi. Force nahi, bas dohrao."),
            ]
        case .guided:
            return [
                ("Aaj", "Aaj koi aur guide kar raha hai. Tumhe bas sunna hai aur saath chalna hai. Wahi posture, wahi jagah."),
                ("Kyun", "Hafte mein ek din alag awaaz, alag tareeka: aadat taaza rehti hai, aur sadhana mechanical nahi lagti."),
            ]
        case .close:
            return [
                ("Hathelian", "Ragadne se friction se garmi banti hai. Aankhon pe rakhne se andhera aur halki garmi aankhon ki muscles ko dheela karti hai."),
                ("Aankhein kholna", "Dheere kholne se aankhein roshni se aaraam se adjust hoti hain. Phone nahi, notebook: sadhana se likhne tak ye 10 second sabse important hain."),
            ]
        }
    }
}
