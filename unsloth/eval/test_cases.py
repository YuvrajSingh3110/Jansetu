#!/usr/bin/env python3
"""
Hard Test Cases for Jansetu E4B Evaluation
==========================================
Twenty hand-crafted test cases representing the most difficult examples —
inputs where the base Gemma 4 E4B model most frequently fails, and where
the fine-tuned model must demonstrate clear improvement.

Categories covered:
  - Bhojpuri seizure / emergency (3 cases)
  - Malnutrition visual descriptions (3 cases)
  - Jaundice colloquial phrases (3 cases)
  - Mild cases that must NOT be referred (3 cases)
  - Elderly multi-symptom (2 cases)
  - ASHA clinical with MUAC (3 cases)
  - Hinglish emergency (3 cases)

Usage:
    from test_cases import HARD_TEST_CASES
    for tc in HARD_TEST_CASES:
        run_inference(tc["input"])
"""

from typing import Any

HARD_TEST_CASES: list[dict[str, Any]] = [
    # -----------------------------------------------------------------------
    # BHOJPURI SEIZURE / EMERGENCY (3)
    # -----------------------------------------------------------------------
    {
        "id": "bhoj_seizure_01",
        "input": "Angiya chadh rahi ba, haath pair ainth gail, 2 saal ke bachwa ke",
        "expected": {
            "symptoms": ["seizure"],
            "duration": None,
            "ageGroup": "child",
            "gender": "M",
            "severity": "severe",
            "referral": True,
        },
        "category": "bhojpuri",
        "note": (
            "Bhojpuri for tonic-clonic seizure. 'Angiya chadh rahi ba' = body arching, "
            "'ainth gail' = limbs twisted. Base model often extracts 'bodyache' instead."
        ),
    },
    {
        "id": "bhoj_seizure_02",
        "input": "Baar baar jhatka aa raha ba, hosh nahi ba bacchwa ke, aankhein upar ho gaili",
        "expected": {
            "symptoms": ["seizure", "unconscious"],
            "duration": None,
            "ageGroup": "child",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "bhojpuri",
        "note": (
            "Repeated Bhojpuri seizure description with post-ictal unconsciousness. "
            "'jhatka' = seizure/jerk, 'aankhein upar ho gaili' = eyes rolled up. "
            "Base model misses 'unconscious' and under-classifies severity."
        ),
    },
    {
        "id": "bhoj_emergency_03",
        "input": "Sans nahi leke pa rahi ba, hont nile ho gaye ba, behosh ba",
        "expected": {
            "symptoms": ["breathlessness", "unconscious"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "F",
            "severity": "severe",
            "referral": True,
        },
        "category": "bhojpuri",
        "note": (
            "Bhojpuri cyanosis + unconsciousness. 'hont nile ho gaye' = lips turned blue. "
            "Base model sometimes outputs referral=false because it misses 'unconscious'."
        ),
    },

    # -----------------------------------------------------------------------
    # MALNUTRITION VISUAL DESCRIPTIONS (3)
    # -----------------------------------------------------------------------
    {
        "id": "maln_visual_01",
        "input": "Bachchi sukh rahi hai, haddi dikhne lagi, pet phula hua",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "F",
            "severity": "severe",
            "referral": True,
        },
        "category": "child_malnutrition",
        "note": (
            "Visual wasting + oedema = kwashiorkor. Base model often classifies "
            "as 'bodyache' or 'vomiting' because it does not map visual wasting "
            "descriptions to the malnutrition canonical symptom."
        ),
    },
    {
        "id": "maln_visual_02",
        "input": "Ek saal ke bachche ki haddi sab nikal aayi hai, bahut sukha, aankhen andar ho gayi",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "M",
            "severity": "severe",
            "referral": True,
        },
        "category": "child_malnutrition",
        "note": (
            "Severe wasting + sunken eyes (dehydration sign on top of malnutrition). "
            "Base model frequently misclassifies severity as 'moderate'."
        ),
    },
    {
        "id": "maln_visual_03",
        "input": "Bachi ke haath bahut patle hain, pet bahar nikla hai, khana nahi kha rahi teen din se",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": 3,
            "ageGroup": "child",
            "gender": "F",
            "severity": "severe",
            "referral": True,
        },
        "category": "child_malnutrition",
        "note": (
            "Nutritional oedema with poor feeding. Colloquial 'pet bahar nikla' "
            "(protruding belly) is a key SAM sign the base model misses."
        ),
    },

    # -----------------------------------------------------------------------
    # JAUNDICE COLLOQUIAL (3)
    # -----------------------------------------------------------------------
    {
        "id": "jaundice_coll_01",
        "input": "Aankhein pili ho gayi, skin pe haldi jaisi rang aa gayi hai",
        "expected": {
            "symptoms": ["jaundice"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "standard_hindi",
        "note": (
            "'Haldi jaisi rang' = turmeric-coloured skin, a classic rural Indian "
            "description of jaundice. Base model sometimes outputs symptoms=[] or "
            "maps it to rash."
        ),
    },
    {
        "id": "jaundice_coll_02",
        "input": "Poora body peela pad gail ba, aankhein bhi pili, okar aankhoin mein safedi nahi rahi",
        "expected": {
            "symptoms": ["jaundice"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "bhojpuri",
        "note": (
            "Bhojpuri: scleral icterus described as 'aankhoin mein safedi nahi rahi' "
            "(whiteness gone from eyes). Base model output is often referral=false."
        ),
    },
    {
        "id": "jaundice_coll_03",
        "input": "Uske aankhon ka safed hissa yellow ho gaya hai, skin bhi yellow, serious nahi lagta but",
        "expected": {
            "symptoms": ["jaundice"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "M",
            "severity": "severe",
            "referral": True,
        },
        "category": "hinglish",
        "note": (
            "Downplayed Hinglish jaundice ('serious nahi lagta but'). "
            "Base model agrees with the speaker's downplayed assessment and outputs "
            "severity=mild, referral=false — a dangerous error."
        ),
    },

    # -----------------------------------------------------------------------
    # MILD CASES — MUST NOT OVER-REFER (3)
    # -----------------------------------------------------------------------
    {
        "id": "mild_no_refer_01",
        "input": "Halki khansi hai kal se, bukhar nahi, naak se thoda paani aa raha",
        "expected": {
            "symptoms": ["cough", "runny_nose"],
            "duration": 1,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "mild",
            "referral": False,
        },
        "category": "mild_cases",
        "note": (
            "Classic mild URTI. Base model sometimes outputs referral=true because "
            "it sees 'cough' and 'runny_nose' together and over-triggers referral."
        ),
    },
    {
        "id": "mild_no_refer_02",
        "input": "Gala thoda dukh raha hai, paani pine mein dard, bukhar bilkul nahi, ek din se",
        "expected": {
            "symptoms": ["sore_throat"],
            "duration": 1,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "mild",
            "referral": False,
        },
        "category": "mild_cases",
        "note": (
            "Isolated sore throat without fever = mild, no referral. "
            "Base model inconsistently classifies severity as 'moderate'."
        ),
    },
    {
        "id": "mild_no_refer_03",
        "input": "Thoda sa headache hai, subah se, nind se theek ho jaega, koi aur takleef nahi",
        "expected": {
            "symptoms": ["headache"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "mild",
            "referral": False,
        },
        "category": "mild_cases",
        "note": (
            "Self-assessed mild headache. Base model sometimes outputs severity=moderate "
            "for headache regardless of context."
        ),
    },

    # -----------------------------------------------------------------------
    # ELDERLY MULTI-SYMPTOM (2)
    # -----------------------------------------------------------------------
    {
        "id": "elderly_multi_01",
        "input": "Dadi ko 70 saal hai, teen din se sans fulna aur seene mein dard, aankhein bhi thodi pili",
        "expected": {
            "symptoms": ["breathlessness", "bodyache", "jaundice"],
            "duration": 3,
            "ageGroup": "elderly",
            "gender": "F",
            "severity": "severe",
            "referral": True,
        },
        "category": "elderly",
        "note": (
            "Elderly woman with dyspnoea, chest pain, and early jaundice — "
            "three overlapping symptoms. Base model often captures only breathlessness "
            "and misses jaundice from 'thodi pili'."
        ),
    },
    {
        "id": "elderly_multi_02",
        "input": "Baba 75 saal ke hain, khansi, bukhar, dast, aur beech beech mein behosh ho jaate hain",
        "expected": {
            "symptoms": ["cough", "fever", "diarrhoea", "unconscious"],
            "duration": None,
            "ageGroup": "elderly",
            "gender": "M",
            "severity": "severe",
            "referral": True,
        },
        "category": "elderly",
        "note": (
            "Quadruple symptom elderly case. Base model struggles to extract all four "
            "symptoms and frequently misses 'unconscious' in long descriptions."
        ),
    },

    # -----------------------------------------------------------------------
    # ASHA CLINICAL WITH MUAC (3)
    # -----------------------------------------------------------------------
    {
        "id": "asha_muac_01",
        "input": "2 saal ki bachi, MUAC 10.2 cm, bilateral pitting oedema, SAM complicated",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "F",
            "severity": "severe",
            "referral": True,
        },
        "category": "asha_clinical",
        "note": (
            "MUAC measurement + oedema = SAM complicated. "
            "Base model often does not recognise MUAC values as malnutrition indicators."
        ),
    },
    {
        "id": "asha_muac_02",
        "input": "Male child 3 yrs, MUAC 11.8 cm — MAM category, koi aur complaint nahi, follow up",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "M",
            "severity": "moderate",
            "referral": True,
        },
        "category": "asha_clinical",
        "note": (
            "MAM (moderate acute malnutrition) based on MUAC alone. "
            "Base model sometimes outputs severity=mild and referral=false "
            "because 'koi aur complaint nahi' (no other complaints) misleads it."
        ),
    },
    {
        "id": "asha_muac_03",
        "input": "3 mahine ka shishu, MUAC nahi liya, par weight 3.2 kg, saans tez, OPD urgent",
        "expected": {
            "symptoms": ["breathlessness", "malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "asha_clinical",
        "note": (
            "Neonate with low weight and tachypnoea — both malnutrition risk and "
            "respiratory emergency. Base model tends to output only breathlessness."
        ),
    },

    # -----------------------------------------------------------------------
    # HINGLISH EMERGENCY (3)
    # -----------------------------------------------------------------------
    {
        "id": "hinglish_emerg_01",
        "input": "Uski body shake ho rahi thi, eyes roll kar gaye, 5 minute tak nahi ruka",
        "expected": {
            "symptoms": ["seizure"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "hinglish",
        "note": (
            "Hinglish seizure description. Base model sometimes outputs bodyache "
            "instead of seizure when 'shake' is used without 'fit' or 'seizure'."
        ),
    },
    {
        "id": "hinglish_emerg_02",
        "input": "Baby ka stomach bahut bloated hai, weight nahi badh raha, bones dikh rahe hain",
        "expected": {
            "symptoms": ["malnutrition"],
            "duration": None,
            "ageGroup": "child",
            "gender": "unknown",
            "severity": "severe",
            "referral": True,
        },
        "category": "hinglish",
        "note": (
            "Hinglish malnutrition visual description. 'Bloated stomach + visible bones' "
            "= kwashiorkor. Base model maps 'bloated' to 'vomiting' in 40%+ of cases."
        ),
    },
    {
        "id": "hinglish_emerg_03",
        "input": "Wo suddenly fall ho gaya, aur fir nahi utha, response nahi de raha",
        "expected": {
            "symptoms": ["unconscious"],
            "duration": None,
            "ageGroup": "adult",
            "gender": "M",
            "severity": "severe",
            "referral": True,
        },
        "category": "hinglish",
        "note": (
            "Collapse + unresponsiveness. Base model sometimes classifies "
            "severity as 'moderate' because 'suddenly fall' sounds like a simple fall."
        ),
    },
]
