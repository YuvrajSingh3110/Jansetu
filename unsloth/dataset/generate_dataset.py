#!/usr/bin/env python3
"""
Jansetu Dataset Generator
=========================
Generates a synthetic JSONL training dataset for fine-tuning Gemma 4 E4B
on rural India health symptom extraction.

Produces 400 training examples and 80 eval examples across 8 language/
style categories: Standard Hindi, Bhojpuri, Hinglish, ASHA clinical style,
Severe emergency cases, Mild self-treatable cases, Elderly patients, and
Children under 5 with malnutrition.

Run:
    python generate_dataset.py
"""

import json
import random
from pathlib import Path
from typing import Any

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

SYSTEM_PROMPT = (
    "You are Jansetu, a health AI assistant for rural India. "
    "When a user describes symptoms, extract them into a structured JSON object "
    "with these exact fields: symptoms (array of strings from the canonical list), "
    "duration (integer days or null), ageGroup (child/adult/elderly), "
    "gender (M/F/unknown), severity (mild/moderate/severe), referral (boolean). "
    "Canonical symptoms: fever, cough, breathlessness, diarrhoea, vomiting, rash, "
    "headache, bodyache, sore_throat, runny_nose, malnutrition, jaundice, "
    "conjunctivitis, seizure, unconscious, bleeding. "
    "Output ONLY the JSON object, nothing else."
)

CANONICAL_SYMPTOMS = [
    "fever", "cough", "breathlessness", "diarrhoea", "vomiting",
    "rash", "headache", "bodyache", "sore_throat", "runny_nose",
    "malnutrition", "jaundice", "conjunctivitis", "seizure",
    "unconscious", "bleeding",
]

# ---------------------------------------------------------------------------
# Template bank helpers
# Each template group: texts (list of variants), symptoms, severity,
# referral, age_group, gender.
# {N} in a text string is replaced with a random duration (1-7 days).
# "random" as gender value picks M / F / unknown randomly.
# ---------------------------------------------------------------------------

def _dur() -> int | None:
    """Return a random duration in days, or None (30 % chance)."""
    if random.random() < 0.30:
        return None
    weights = [20, 20, 25, 15, 10, 5, 5]  # 1,2,3,4,5,6,7 days
    return random.choices(range(1, 8), weights=weights)[0]


def _long_dur() -> int | None:
    """Longer durations for chronic / severe presentations."""
    if random.random() < 0.15:
        return None
    return random.randint(5, 14)


# ---------------------------------------------------------------------------
# CATEGORY 1 — Standard Hindi (target 60 = 50 train + 10 eval)
# ---------------------------------------------------------------------------
CAT1_HINDI: list[dict[str, Any]] = [
    {
        "texts": [
            "Teen din se bukhar hai, saath mein khansi bhi",
            "Bukhar hai {N} din se, khansi bhi aa rahi hai",
            "Tez bukhar ke saath khansi bhi hai {N} din se",
            "Bukhar aur khansi dono hain, {N} din ho gaye",
        ],
        "symptoms": ["fever", "cough"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "unknown",
    },
    {
        "texts": [
            "Pet mein dard hai aur ulti ho rahi hai",
            "Pet mein dard aur ulti, {N} din se pareshan hai",
            "Ulti ho rahi hai, pet mein bhi dard chal raha hai",
        ],
        "symptoms": ["vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bachche ko {N} din se dast aa rahe hain",
            "Chhote ko dast ho rahe hain, {N} din se, paani bhi peeta nahi",
            "Bacha bilkul kamzor ho gaya, dast nahi ruk rahe",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Aankhein pili ho gayi hain, bhook nahi lag rahi",
            "Poora body peela pad gaya, aankhein bhi pili hain",
            "Peela rang aa gaya skin pe, aankhein bhi pili, {N} din se",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Budhiye ko sans lene mein takleef hai",
            "Saans fulne lagi hai, chalte nahi ban raha {N} din se",
            "Sans ki takleef hai, seene mein bhari bhari feeling",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Sar dard hai, aankhon mein bhi jalan",
            "Tez sar dard hai {N} din se, nind nahi aa rahi",
            "Sar phata ja raha hai, bukhar bhi lag raha hai",
        ],
        "symptoms": ["headache", "fever"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Poore body mein dard hai, bukhar bhi hai",
            "Haath pair mein bahut dard, body toot rahi hai, bukhar bhi",
            "Bukhar ke saath body dard hai, uthha nahi ja raha {N} din se",
        ],
        "symptoms": ["fever", "bodyache"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Gale mein dard hai, kuch nighalne mein taklif",
            "Gala baith gaya, dard hai {N} din se",
            "Gale mein kharash hai, khaana nahi kha pa raha",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Naak beh rahi hai, thoda sar dard, khansi bhi",
            "Naak se paani aa raha hai {N} din se, khansi bhi thodi",
            "Zukaam hua hai, naak band ho gayi, sar bhari bhari lag rahi",
        ],
        "symptoms": ["runny_nose", "cough", "headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Pet mein dast bhi hain, saath mein ulti bhi",
            "Dast aur ulti dono chal rahe hain {N} din se, bahut kamzori",
            "Ulti dast dono ho rahe hain, kuch bhi andar nahi reh raha",
        ],
        "symptoms": ["diarrhoea", "vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Poori body pe laal daane ho gaye hain",
            "Skin pe rash aa gaya hai, khujli bhi bahut hai",
            "Daane nikal aaye hain, bukhar bhi hai saath mein",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Aankhein laal ho gayi hain, paani beh raha hai",
            "Aankhon mein jalan aur sujan, laal ho gayi hain",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Ek hafte se bukhar nahi ja raha, bahut kamzori",
            "Lambey arse se bukhar hai, koi faida nahi ho raha dawai se",
        ],
        "symptoms": ["fever"],
        "severity": "moderate", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bache ko khoon aa raha hai shauche mein",
            "Potti mein khoon dikh raha hai {N} din se",
        ],
        "symptoms": ["bleeding", "diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Chehre pe sujan aa gayi hai, aankhein bhi suji hain",
            "Haath pair phool gaye hain, sans lena mushkil ho raha",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Khansi mein khoon aa raha hai, bahut darr gaye",
            "Balgam mein khoon aa raha hai {N} din se",
        ],
        "symptoms": ["cough", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bacha kha nahi raha, sukta ja raha hai, bahut kamzor lag raha",
            "Bachi khana chhodh diya hai, haath pair patla ho gaya",
        ],
        "symptoms": ["malnutrition"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Hafta bhar se dast aa rahe hain, bahut kamzori hai",
            "Dast thak nahi rahe, paanch din ho gaye, ORS diya par aaram nahi",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "Bukhar hai par sar dard nahi, gala bhi theek hai",
            "Halka bukhar hai ek do din se, koi aur takleef nahi",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Seene mein dard hai, saans bhi thoda fulta hai",
            "Chhaati mein dard hai, hath bhi dard kar raha hai saath mein",
        ],
        "symptoms": ["breathlessness", "bodyache"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Aankhein pili aur body pe peela rang, pet mein dard bhi",
            "Liver mein taklif lag rahi hai, aankhein bahut pili hain",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bacha behosh sa lag raha tha, ab thoda hosh hai",
            "Ghabra gaya tha, behosh ho gaya tha kal raat",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Aankhon mein pani aa raha, chehre pe daane bhi",
            "Aankhein laal aur suji hain, bukhar bhi hai",
        ],
        "symptoms": ["conjunctivitis", "fever", "rash"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Khansi hai halki, aaram se saans le raha hai",
            "Sirf khansi hai, bukhar nahi, thak sa lagta hai",
        ],
        "symptoms": ["cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bukhar, khansi, runny nose, sar dard sab ek saath",
            "Tez bukhar ke saath body dard, naak beh rahi, khansi bhi hai",
        ],
        "symptoms": ["fever", "cough", "runny_nose", "headache", "bodyache"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 2 — Bhojpuri (target 72 = 60 train + 12 eval)
# ---------------------------------------------------------------------------
CAT2_BHOJPURI: list[dict[str, Any]] = [
    {
        "texts": [
            "Tikan ba, khansi bhi ba, teen din se",
            "{N} din se tikan ba, khansi nahi chhut rahi",
            "Bukhar jaisan tikan ba okar, khansi bhi chal raha ba",
        ],
        "symptoms": ["fever", "cough"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Okar pet mein dard baa, ulti ho raha ba",
            "Pet mein dard ba, ulti bhi ho rahi ba {N} din se",
        ],
        "symptoms": ["vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bachwa ke seizure aa gail, 2 saal ke ba",
            "Angiya chadh rahi ba, haath pair ainth gail",
            "Bacchwa ke jhatka aa gail, hosh nahi ba okar",
            "Aankh pherke maral ba, body ainth gaili",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "Haddi dikhay lage ba, sukhat jaat ba bachwa",
            "Sukh raha ba, haddi sab dikh rahi hai body mein",
            "Bahut patla ho gail, haddi dikhay lage ba, khaana nahi khaat ba",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "Sar mein dard baa, aankhon ke aage andhiyar",
            "Mathha phootat ba, aankhon mein andhera aawat ba",
            "Sar mein bahut dard ba, chakkar aawat ba",
        ],
        "symptoms": ["headache"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Peet mein dard baa, dast bhi hote ba {N} din se",
            "Dast aur ulti dono ho rahi ba, bahut kamzor ho gail",
        ],
        "symptoms": ["diarrhoea", "vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Aankhein pili ho gaili ba, haldi jaisi rang aa gaili",
            "Poora body peela pad gail ba, aankhein bhi pili",
            "Chehre pe pili pitayi aa gaili ba, aankhein bhi",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Sans nahi leke pa rahi ba, hont nile ho gaye ba",
            "Saans fulat ba, chalat nahi ban raha",
            "Chhaati mein bhar ba, sans khatir taras ta",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "Dadi ke {N} din se hosh nahi ba, uthhat nahi ba",
            "Budhiya behosh ba, uthhat nahi, hosh nahi",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Body pe daane nikal aaye ba, bukhar bhi ba",
            "Laal daane aa gaye ba skin pe, khansi bhi chal raha",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Bachi sukh rahi ba, haddi dikhay lage ba, pet phula hua",
            "Bachi bahut patla ho gaili, pet bahar nikal aa gail",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "Khoon aa raha ba shauch mein, dard bhi bahut ba",
            "Potti mein laal khoon dikh raha ba",
        ],
        "symptoms": ["bleeding", "diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Halka tikan ba ek do din se, koi aur takleef nahi ba",
            "Thoda sa tikan ba, khansi nahi, naak bhi theek ba",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bache ke khansi ba, naak beh rahi ba, bukhar nahi ba",
            "Sirf zukaam jaisan ba, khansi ba thoda",
        ],
        "symptoms": ["cough", "runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Baba ke sans leke takleef ba, chhaati mein dard bhi ba",
            "Burhe ke saans phulat ba, seene mein bhar ba",
        ],
        "symptoms": ["breathlessness", "bodyache"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Gala dukh raha ba, khaana nighalna mushkil ba",
            "Gale mein dard ba thoda, bukhar nahi ba",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bachwa ke {N} din se dast ho raha ba, bahut kamzor",
            "Dast nahi ruk raha ba bachwe ke, paani bhi chhod diye ba",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "Burhwa ke aankhein pili ho gaili, body pe pili pitayi",
            "Budhe baba ke poora body peela ba, aankhein bhi",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Tikan aur haath pair mein dard ba, body tooti ba",
            "Bukhar jaisan ba, haath pair sab dard karat ba",
        ],
        "symptoms": ["fever", "bodyache"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Naak beh rahi ba, thodi khansi ba, sar bhari ba",
            "Zukaam ho gail ba, naak se paani nikaltaa ba",
        ],
        "symptoms": ["runny_nose", "headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Angiya aur haath pair ainthle ba, bar bar aa raha ba",
            "Baar baar jhatka aa raha ba, hosh nahi ba okar",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Aankhein laal ba, paani beh raha ba aankhon se",
            "Aankhon mein jalan aur lali ba",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Khansi mein balgam ba aur khoon bhi aa raha ba",
            "Khansi bahut ba, balgam mein laal rang aa raha ba",
        ],
        "symptoms": ["cough", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bahut dast ho raha ba, {N} din se, ORS diya fir bhi nahi ruka",
            "Dast ruk nahi raha, kamzori bahut ho gaili ba",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "Behosh ho gail raha, uthha nahi pa raha ba",
            "Hosh chhal gail, uthhat nahi ba koi",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bukhar, dast, ulti teen dino se ba, bahut takleef ba",
            "Tikon, dast, ulti sab ek saath ba, bahut bura laat ba",
        ],
        "symptoms": ["fever", "diarrhoea", "vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bachi {N} din se kha nahi rahi, bahut sukhi dikh rahi ba",
            "Khana chhodh diye ba, MUAC bhi bahut kam lage ba",
        ],
        "symptoms": ["malnutrition"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "Sirf ek do din se halki khansi ba, theek ho jaai",
            "Thodi si khansi ba, naak se paani ba, bukhar nahi",
        ],
        "symptoms": ["cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Tikon ke saath aankhein pili ba, body pe daane bhi",
            "Bukhar jaisan aur daane nikal aaye ba, aankhein bhi pili",
        ],
        "symptoms": ["fever", "jaundice", "rash"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bache ke haath pair thanda ho gail, hosh bhi nahi ba",
            "Bacchwa behosh ba, haath pair ice jaisan lage ba",
        ],
        "symptoms": ["unconscious", "seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 3 — Hinglish / mixed Hindi-English (target 72 = 60 train + 12 eval)
# ---------------------------------------------------------------------------
CAT3_HINGLISH: list[dict[str, Any]] = [
    {
        "texts": [
            "Usko fever hai {N} days se, plus cough bhi",
            "Fever and cough dono hain {N} din se",
            "{N} days se fever hai, cough bhi aa rahi hai",
        ],
        "symptoms": ["fever", "cough"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Baby ko rash ho gaya, whole body pe",
            "Bachche ko full body pe rash aa gaya hai, fever bhi",
            "Skin pe rash hai, itching bhi ho rahi hai",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Mummy ko breathlessness feel ho rahi hai",
            "Mom ko breathing problem hai, seriously dekho",
            "Wo saans nahi le pa rahi properly",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Serious case hai, unconscious pad gaya",
            "Wo suddenly unconscious ho gaya, please help",
            "Behosh ho gaya hai, unconscious hai abhi",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Loose motions ho rahe hain {N} days se",
            "Diarrhoea aur vomiting dono hai, dehydrated lag raha",
            "Pani jaisi potty aa rahi hai, {N} times already",
        ],
        "symptoms": ["diarrhoea", "vomiting"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Yellow eyes aa gaye hain, jaundice suspect hai",
            "Aankhein yellow ho gayi hain, jaundice ka sign hai",
            "Skin bhi yellow pad gayi hai, ankhein bhi — jaundice lagta hai",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Mild headache hai, fever nahi, thoda rest karega",
            "Sirf headache hai, {N} din se, medicine nahi li",
        ],
        "symptoms": ["headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "High fever hai, body pain bhi, bahut weak feel ho raha",
            "Fever 103 jaisa lag raha, body totally pained out",
        ],
        "symptoms": ["fever", "bodyache"],
        "severity": "moderate", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Sore throat hai, little bit cough, no fever",
            "Gale mein pain hai, mild hai, just sore throat",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Seizure aa gaya suddenly, please rush",
            "Usko fit aa gaya, body kainp rahi thi, hosh nahi tha",
            "Epilepsy jaisa lag raha tha, body shake ho rahi thi",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Child malnourished lag raha hai, ribs dikh rahi hain",
            "Baby ka weight bahut kam hai, visible bones hain",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Normal cold hai, runny nose aur cough, {N} din se",
            "Seasonal flu jaisa hai, nothing serious, bas rest chahiye",
        ],
        "symptoms": ["runny_nose", "cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Eyes red ho gayi hain, pink eye jaisa, discharge bhi",
            "Conjunctivitis ho gaya hai, dono aankhon mein",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bleeding nahi ruk rahi, emergency hai",
            "Bahut blood loss hua hai, stop nahi ho raha",
            "Wound se blood bahut aa raha hai, control nahi ho raha",
        ],
        "symptoms": ["bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Severe dehydration lag rahi hai, {N} din se diarrhoea",
            "Bahut loose motions hain, dehydrated, aankhen andar ho gayi",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Old man ko breathing difficulty hai, chest pain bhi",
            "Papa ko chest mein tightness hai, breathlessness bhi",
        ],
        "symptoms": ["breathlessness", "bodyache"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Thoda sa fever hai, just one day, no worries",
            "Low grade fever hai, aaj se, no other symptoms",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Measles jaisa dikh raha hai, rash with fever, {N} din se",
            "Full body rash aur high fever, measles suspect",
        ],
        "symptoms": ["rash", "fever", "cough"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Dadi ko jaundice ho gayi hai, eyes bhi yellow, liver mein problem",
            "Grandma ki aankhein aur skin dono yellow hai",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Stomach cramps aur loose motions, nothing serious",
            "Pet mein mild cramps hain, thodi si potty problem",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Multiple symptoms hain — fever, cough, loose motions, vomiting",
            "Sab kuch ek saath hai — fever, diarrhoea, vomiting, headache",
        ],
        "symptoms": ["fever", "cough", "diarrhoea", "vomiting"],
        "severity": "moderate", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Child ko {N} din se fit aa rahi hai bar bar",
            "Seizures repeatedly aa rahe hain, control nahi ho raha",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Grandpa unconscious hai, nahi uth rahe",
            "Bade uncle suddenly fall ho gaye, unconscious hain",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Just headache aur mild fever, nothing to worry about",
            "Normal mild symptoms, just rest chahiye",
        ],
        "symptoms": ["headache", "fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Baby 1 year old hai, wasting ho raha hai, weight gain nahi",
            "Toddler malnourished, belly phula hua, arms thin",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 4 — ASHA worker clinical style (target 72 = 60 train + 12 eval)
# ---------------------------------------------------------------------------
CAT4_ASHA: list[dict[str, Any]] = [
    {
        "texts": [
            "35 saal ki mahila, teen din se tez bukhar, saans fulna, referral chahiye",
            "Mahila 35 varsh, {N} din se bukhar aur breathlessness, PHC bhejna hai",
        ],
        "symptoms": ["fever", "breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "8 saal ka bachcha, poore body pe rash, bukhar 102, measles suspect",
            "8 year male child, rash with fever, measles look kar raha hai",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "60 saal ke bujurg, dast 5 din se, kamzori bahut, ORS diya",
            "Elder 60 yrs male, {N} din se diarrhoea, dehydrated, ORS diya gaya",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "2 saal ki bachi, MUAC 10.5cm, sukhi twacha, malnutrition SAM",
            "Female child 2 yrs, MUAC 10.5, SAM category, weight bahut kam",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "55 saal ka purush, aankhein pili, pet dard, jaundice suspected",
            "Male 55 yrs, {N} din se aankhein pili, liver function check karna hai",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Teen saal ka baccha, 4 din se dast, aankhein andar, aansu nahi",
            "Child 3 yr male, diarrhoea {N} days, severe dehydration signs",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "25 saal ki mahila, sirf halki khansi aur naak beh rahi, bukhar nahi",
            "Young female 25 yr, mild cough and runny nose, no fever, no referral",
        ],
        "symptoms": ["cough", "runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "18 mahine ka bachcha, MUAC 11cm, MAM category, twacha dhili",
            "18 months child, MUAC 11 cm, MAM, needs NRC follow up",
        ],
        "symptoms": ["malnutrition"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "40 saal ka purush, {N} din se bukhar, bodyache, dengue suspect",
            "Male 40 yr, high fever with body pain, dengue like symptoms {N} days",
        ],
        "symptoms": ["fever", "bodyache"],
        "severity": "moderate", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "5 saal ki bachi, seizure aya kal, hosh nahi tha, referral urgent",
            "Female 5 yr, seizure episode yesterday, unconscious tha thodi der, urgent",
        ],
        "symptoms": ["seizure", "unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "70 saal ki burhiya, saans bahut fulti hai, haath pair sujan",
            "Elderly female 70 yr, severe breathlessness, pedal edema",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "30 saal ki mahila, halka bukhar ek din se, koi aur complaint nahi",
            "Female 30 yr, mild fever since yesterday, no other symptoms, watch",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "4 saal ka bachcha, khansi 5 din se, saans tez hai, chest indrawing",
            "4 yr male, cough {N} days, fast breathing, possible pneumonia",
        ],
        "symptoms": ["cough", "breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "65 saal ke bujurg, 3 din se unconscious ho rahe hain beech beech mein",
            "Elder male 65 yr, intermittent unconsciousness {N} days, emergency",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "15 saal ki ladki, gale mein dard, bukhar nahi, ek din se",
            "Female 15 yr, sore throat since yesterday, no fever, mild case",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "2 saal ka bachcha, MUAC 9.8cm, SAM plus complications, emergency",
            "Male 2 yr, MUAC 9.8 bilateral pitting oedema, SAM complicated, NRC urgent",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "28 saal ka purush, jaundice {N} din se, aankhein bahut pili, liver bulge",
            "Male 28 yr, jaundice progressive {N} days, hepatomegaly likely",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "50 saal ki mahila, khansi 2 hafte se, khoon aa raha balgam mein",
            "Female 50 yr, cough 2 weeks with blood in sputum, TB suspect",
        ],
        "symptoms": ["cough", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "32 saal ki mahila, aankhein laal hain, conjunctivitis, koi aur nahi",
            "Female 32 yr, bilateral conjunctivitis, mild, no systemic illness",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "3 mahine ka bachcha, fever 3 din se, khansi, fast breathing",
            "3 month male infant, fever {N} days, cough, tachypnea — urgent",
        ],
        "symptoms": ["fever", "cough", "breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "22 saal ka purush, pet dard thoda, ek baar ulti, theek ho raha",
            "Male 22 yr, mild stomach pain, one vomiting episode, no fever, stable",
        ],
        "symptoms": ["vomiting"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "45 saal ki mahila, poora body pe rash, bukhar 104, measles confirmed",
            "Female 45 yr, high fever rash, measles contact history, confirm and refer",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "7 saal ka bachcha, sar dard, halka bukhar, school se aa raha tha",
            "7 yr male, headache and low grade fever, mild presentation",
        ],
        "symptoms": ["headache", "fever"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "12 saal ki ladki, bleeding ho rahi hai naak se, ruk nahi rahi",
            "12 yr female, epistaxis not stopping, {N} minutes already, refer",
        ],
        "symptoms": ["bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "80 saal ke bujurg, bukhar, dast, ulti sab ek saath, bahut weak",
            "Elder 80 yr male, fever, diarrhoea, vomiting, severe dehydration",
        ],
        "symptoms": ["fever", "diarrhoea", "vomiting"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "20 saal ki mahila, sirf naak beh rahi hai, ek din se, no fever",
            "Female 20 yr, runny nose only since yesterday, viral URTI mild",
        ],
        "symptoms": ["runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 5 — Severe / emergency (target 60 = 50 train + 10 eval)
# ---------------------------------------------------------------------------
CAT5_SEVERE: list[dict[str, Any]] = [
    {
        "texts": [
            "Bachche ko seizure aa raha hai bar bar, hosh nahi",
            "Baar baar jhatkha aa raha hai, hosh waapis nahi aa raha",
            "Bache ko fit aa gayi, unconscious hai, please help",
        ],
        "symptoms": ["seizure", "unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Khoon aa raha hai, rok nahi pa rahe",
            "Bahut zyada khoon beh raha hai, nahin ruk raha",
            "Emergency hai — khoon nikal raha hai banda, ruk nahi raha",
        ],
        "symptoms": ["bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Poora body peela pad gaya, aankhein bhi",
            "Skin aur aankhein dono pili, jaundice bahut advanced lag raha",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Saans bilkul nahi le pa raha, hont nile ho gaye",
            "Naak aur hont nile pad gaye, saans ki ghur ghur aa rahi hai",
            "Breathing band ho rahi hai, oxygen ki zaroorat lag rahi hai",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Behosh pad gaya, uthha nahi pa raha",
            "Suddenly gir gaya, hosh nahi aa raha",
            "Completely unconscious hai, response nahi de raha",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bachche ko baar baar ulti ho rahi hai, pet bahut phula hai",
            "Ulti band nahi ho rahi, bhook bilkul nahi, bahut kamzor",
        ],
        "symptoms": ["vomiting"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Dast mein khoon aa raha hai, rok nahi pa rahe",
            "Potti mein laal khoon beh raha hai, bahut zyada",
        ],
        "symptoms": ["diarrhoea", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bujurg ko tez bukhar hai, hosh nahi aa ja raha",
            "70 saal waale ko fever aur unconscious ho jaate hain beech beech mein",
        ],
        "symptoms": ["fever", "unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Bachche ke haath pair bilkul thandhe ho gaye, hosh gum hai",
            "Shock jaisa lag raha hai, haath pair thande, hont nile",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Teen hafte se khansi hai, balgam mein khoon, weight ghata",
            "Khansi do hafte se, khoon bhi aa raha balgam mein, TB suspect",
        ],
        "symptoms": ["cough", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Ek saal ka bacha, bahut sukha, haddi nikal rahi, aankhein andar, SAM",
            "12 mahine ka bacha, wasting aur bilateral edema, critical malnutrition",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Naak aur munh dono se khoon aa raha hai, rokne ki koshish kar rahe",
            "Munh se khoon nikal raha hai galat jagah se, emergency",
        ],
        "symptoms": ["bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Budhi aurat behosh ho gayi, sans aa ja rahi hai par hosh nahi",
            "Unconscious elderly woman, breathing present par no response",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Bachcha tez saans le raha hai, chest mein ghur ghur, khaans raha",
            "Child fast breathing, chest retractions, cough with wheeze",
        ],
        "symptoms": ["breathlessness", "cough"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "Aankhein jaundice se bahut pili, pet mein bahut dard, beemar",
            "Advanced jaundice with abdominal pain, emergency referral needed",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bukhar 104 se upar, seizure bhi aya ek baar, emergency",
            "Very high fever with single febrile seizure, refer immediately",
        ],
        "symptoms": ["fever", "seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Poora pet phula hua, dast bhi, aankhein pili, liver fail ho raha",
            "Ascites, jaundice, severe dehydration — multi-organ failure signs",
        ],
        "symptoms": ["jaundice", "diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Baar baar behosh ho rahi hai, sugar low lag rahi hai",
            "Recurrent unconsciousness, hypoglycaemia likely",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "Body tuta hua hai, bukhar, saans, dast, sab ek saath, bahut bura",
            "Multi-symptom severe — fever, breathlessness, diarrhoea, vomiting",
        ],
        "symptoms": ["fever", "breathlessness", "diarrhoea", "vomiting"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "2 saal ki bachi seizure mein hai, 5 minute se zyada ho gaye",
            "Prolonged seizure, 2 yr female, status epilepticus possible",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "Khansi ke saath saans bahut tez, seene mein dard, bujurg hain",
            "Elderly with cough, dyspnoea, chest pain — cardiac or pneumonia",
        ],
        "symptoms": ["cough", "breathlessness", "bodyache"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Bache ke aankhein andar ho gayi, rone pe aansu nahi, dast bahut",
            "Child severe dehydration — sunken eyes, absent tears, severe diarrhoea",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Wound se khoon bahut aa raha, pressure lagane pe bhi nahi ruka",
            "Major laceration bleeding uncontrolled, tourniquet needed",
        ],
        "symptoms": ["bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Bukhar ke saath hont nile, breathlessness, unconscious ho raha",
            "Fever with cyanosis, loss of consciousness — critical",
        ],
        "symptoms": ["fever", "breathlessness", "unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "5 saal ke bacha ko baar baar seizure, diazepam diya par aya phir",
            "5 yr child recurrent seizures, diazepam given, not responding fully",
        ],
        "symptoms": ["seizure"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 6 — Mild self-treatable (target 60 = 50 train + 10 eval)
# ---------------------------------------------------------------------------
CAT6_MILD: list[dict[str, Any]] = [
    {
        "texts": [
            "Halki khansi hai, ek din se, bukhar nahi",
            "Thodi khansi hai, koi aur takleef nahi",
            "Halki khansi hai, {N} din se, paani pi rahe hain",
        ],
        "symptoms": ["cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Naak beh rahi hai, thoda sar dard",
            "Zukaam hai, naak se paani aa raha hai, {N} din se",
            "Runny nose aur thodi khansi, seasonal hai",
        ],
        "symptoms": ["runny_nose", "headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Pet mein halka dard tha, theek ho gaya",
            "Thoda sa pet dard hai, ek baar ulti hui, ab theek hai",
        ],
        "symptoms": ["vomiting"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Gala dukh raha hai, pani pine mein taklif",
            "Sore throat hai thoda, {N} din se, bukhar nahi",
            "Gale mein kharash hai, khansi nahi",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Halka bukhar hai ek din se, {N} ghante se",
            "Low grade fever hai, paracetamol de diya, rest karo",
            "Bukhar thoda hai, bahut zyada nahi, ghabrana nahi",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Sar mein halka dard hai, {N} ghante se, tablet le li",
            "Thoda headache hai, nind se theek ho jaega",
        ],
        "symptoms": ["headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Ek baar dast hua, ab nahi ho raha, theek lag raha",
            "Thoda dast tha subah, ORS diya, ab stable hai",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Aankhein thodi laal hain, cleaning se theek ho raha",
            "Conjunctivitis mild hai, ek aankh mein, eye drop diya",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Body mein thoda dard hai, rest karne se theek ho raha",
            "Halka bodyache hai, koi bukhar nahi",
        ],
        "symptoms": ["bodyache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bukhar aur naak beh rahi, common cold jaisa, theek ho jaega",
            "Normal seasonal flu jaisa hai, ghabrana nahi chahiye",
        ],
        "symptoms": ["fever", "runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bache ko thoda bukhar hai, khel raha hai, doodh pi raha hai",
            "Child ko {N} din se mild fever hai, active hai, no referral",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Thodi ulti hui ek baar, ab kha pi raha hai",
            "Ek ulti thi, pet mein dard nahi, ab theek hai",
        ],
        "symptoms": ["vomiting"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Khansi aur gala dard hai, bukhar nahi, {N} din se",
            "Upper respiratory symptoms, no fever, mild case",
        ],
        "symptoms": ["cough", "sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Naak band hai, thoda sar bhari bhari, seasonal change lagta hai",
            "Naak se paani aa raha hai, khansi bhi thodi, mausam ki wajah se",
        ],
        "symptoms": ["runny_nose", "cough", "headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Pet mein gas hai, thodi discomfort, khaana khane ke baad",
            "Indigestion jaisa hai, ek ghante mein theek ho jaega",
        ],
        "symptoms": ["vomiting"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Aankhon mein thodi jalan hai, paani se dhone pe theek hoga",
            "Mild eye irritation, dust fall gayi thi aankhon mein",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bachche ko sirf thodi naak beh rahi hai, no fever, active hai",
            "Child runny nose only, playing well, no fever, no referral needed",
        ],
        "symptoms": ["runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "Gale mein thodi takleef, paani peene mein dard, ek din se",
            "Mild sore throat, no fever, rest aur warm water recommended",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "F",
    },
    {
        "texts": [
            "Halka dard hai body mein, rest ke baad theek ho gaya",
            "Mild myalgia, no fever, took paracetamol, feeling better",
        ],
        "symptoms": ["bodyache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "M",
    },
    {
        "texts": [
            "Subah se thodi khansi hai, dawa li, aaram chal raha hai",
            "Morning cough since today, no other symptoms, self-limiting",
        ],
        "symptoms": ["cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Ek din ka bukhar, paracetamol se theek ho gaya",
            "Brief fever yesterday, afebrile now, no other symptoms",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Pet dard thoda, khana khane ke baad, gas nikalti hai to aaram",
            "Mild flatulence and stomach discomfort, no vomiting, no diarrhoea",
        ],
        "symptoms": ["vomiting"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Ek hafte se halki khansi hai, aur kuch nahi, tablet li hai",
            "Persistent but mild cough, no systemic symptoms, watch",
        ],
        "symptoms": ["cough"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Naak beh rahi aur gala thoda dard kar raha, normal cold",
            "Mild URI symptoms, {N} din se, no fever, no referral",
        ],
        "symptoms": ["runny_nose", "sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
    {
        "texts": [
            "Bahut halka sar dard hai, nind ke baad theek ho jaega",
            "Mild tension headache, no other symptoms",
        ],
        "symptoms": ["headache"],
        "severity": "mild", "referral": False,
        "age_group": "adult", "gender": "random",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 7 — Elderly patients (target 42 = 35 train + 7 eval)
# ---------------------------------------------------------------------------
CAT7_ELDERLY: list[dict[str, Any]] = [
    {
        "texts": [
            "Dadi ko sans lene mein takleef hai, seene mein dard",
            "Burhiya ko saans fulti hai, seene mein bhaari lagta hai",
            "Nani ko breathlessness aur chest pain, kaafi serious hai",
        ],
        "symptoms": ["breathlessness", "bodyache"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Baba 70 saal ke, haath pair mein sujan, aankhein pili",
            "Bujurg 70 plus, pedal edema aur jaundice, liver condition",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Budhiya ko 3 din se aata-jaata hosh nahi",
            "Dadi beech beech mein behosh ho jaati hain, {N} din se",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Bujurg ko tez bukhar hai aur saans bhi nahi le pa rahe theek se",
            "Old man ko high fever aur breathlessness, critical",
        ],
        "symptoms": ["fever", "breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Dadaji ko khansi bahut ho rahi hai, {N} hafte se, balgam mein khoon",
            "Elderly man, chronic cough with hemoptysis, TB suspect",
        ],
        "symptoms": ["cough", "bleeding"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Nani ko halka bukhar hai, khansi hai, naak beh rahi, theek ho jaengi",
            "Elderly lady, mild cold symptoms, no breathlessness, mild case",
        ],
        "symptoms": ["fever", "cough", "runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Budhwa ko {N} din se dast aa rahe hain, bahut kamzor ho gaye",
            "Elderly male, diarrhoea {N} days, significant weakness",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Dadi ke pure body pe peela rang aa gaya, aankhein bhi pili",
            "Grandma, total jaundice — skin and eyes both yellow, critical",
        ],
        "symptoms": ["jaundice"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Bade uncle ko sar dard hai bahut, chakkar aa rahe hain",
            "Elderly male, severe headache and dizziness, BP check karna hai",
        ],
        "symptoms": ["headache"],
        "severity": "moderate", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Burhiya ko haath pair aur chehre mein sujan, saans mein bhi takleef",
            "Elderly lady, generalised oedema, dyspnoea, cardiac cause likely",
        ],
        "symptoms": ["breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Bujurg ko rash aa gaya hai, bukhar bhi hai, herpes jaisa lag raha",
            "Elder male, rash with fever, possible shingles",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Nani ko sirf gala dard hai, aur kuch nahi, aaram kar rahi hain",
            "Elderly female, sore throat only, mild, no systemic involvement",
        ],
        "symptoms": ["sore_throat"],
        "severity": "mild", "referral": False,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Baba ko body mein dard hai, bukhar bhi, bahut kamzor lag rahe hain",
            "Old man, fever and bodyache, {N} din se, quite weak",
        ],
        "symptoms": ["fever", "bodyache"],
        "severity": "moderate", "referral": False,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Burhiya behosh pad gayi, hath pair thande, saans aa ja rahi hai",
            "Elderly female unconscious, cold extremities, emergency",
        ],
        "symptoms": ["unconscious"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Dadi ko dast aur ulti dono hain, kha nahi pa rahi, kamzori bahut",
            "Elderly lady, diarrhoea and vomiting, unable to eat, severe dehydration",
        ],
        "symptoms": ["diarrhoea", "vomiting"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "F",
    },
    {
        "texts": [
            "Dada jo ki naak beh rahi hai sirf, bukhar nahi, active hain",
            "Elderly male, just runny nose, no fever, self-limiting",
        ],
        "symptoms": ["runny_nose"],
        "severity": "mild", "referral": False,
        "age_group": "elderly", "gender": "M",
    },
    {
        "texts": [
            "Bujurg ko aankhein laal hain, discharge hai, conjunctivitis",
            "Elder, bilateral conjunctivitis, {N} din se, eye drops needed",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "elderly", "gender": "random",
    },
    {
        "texts": [
            "Bade uncle, 75 saal, body pe daane aur bukhar, hospitalization ho sakti hai",
            "75 yr male, rash and high fever, serious presentation",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "severe", "referral": True,
        "age_group": "elderly", "gender": "M",
    },
]

# ---------------------------------------------------------------------------
# CATEGORY 8 — Children under 5, malnutrition & fever (42 = 35 train + 7 eval)
# ---------------------------------------------------------------------------
CAT8_CHILDREN: list[dict[str, Any]] = [
    {
        "texts": [
            "Ek saal ka bachcha, sukh raha hai, haddi dikh rahi, pet foolaa",
            "1 year old, wasting with oedema, bones visible, SAM",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "2 saal ki bachi, 4 din se dast, aankhein andar ho gayi, rone pe aansu nahi",
            "2 yr girl, diarrhoea {N} days, sunken eyes, no tears — severe dehydration",
        ],
        "symptoms": ["diarrhoea", "malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "Teen saal ka baccha, MUAC kam, khansi bhi",
            "3 yr boy, MUAC low, cough, possible pneumonia and malnutrition combo",
        ],
        "symptoms": ["malnutrition", "cough"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "18 mahine ki bachi, bukhar {N} din se, kha nahi rahi, MUAC border",
            "18 months girl, fever, poor feeding, borderline MUAC",
        ],
        "symptoms": ["fever", "malnutrition"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "5 saal ka bachcha, tez bukhar aur khansi, saans bhi tez",
            "5 yr child, high fever, cough, fast breathing — pneumonia suspect",
        ],
        "symptoms": ["fever", "cough", "breathlessness"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "4 saal ki bachi, rash nikal aaya, bukhar bhi, khuj rahi hai",
            "4 yr girl, rash all over, high fever, possible measles or chickenpox",
        ],
        "symptoms": ["rash", "fever"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "2 saal ka bachcha, seizure aya, {N} minute ruka, ab thak gaya",
            "2 yr boy, febrile seizure, post-ictal state, emergency referral",
        ],
        "symptoms": ["seizure", "fever"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "6 mahine ka bachcha, dast aur ulti dono, bahut kamzor",
            "6 month infant, diarrhoea and vomiting, severe dehydration",
        ],
        "symptoms": ["diarrhoea", "vomiting"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "3 saal ki bachi, kha nahi rahi {N} din se, bahut patla, haddi dikh rahi",
            "3 yr girl, not eating {N} days, visible wasting, SAM likely",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "4 saal ka bacha, halka bukhar hai, khel raha hai, OPD mein aa gaye",
            "4 yr boy, mild fever since yesterday, playful, no emergency",
        ],
        "symptoms": ["fever"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "2 saal ki bachi, naak beh rahi hai, khansi thodi, active hai",
            "2 yr girl, mild URTI, active and feeding well, no referral",
        ],
        "symptoms": ["runny_nose", "cough"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "18 mahine ka bachcha, aankhein laal hain, discharge, conjunctivitis",
            "18 month infant, bilateral conjunctivitis, mild, eye drops",
        ],
        "symptoms": ["conjunctivitis"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "1 saal ki bachi, body pe daane, bukhar nahi, thodi khujli",
            "1 yr girl, mild rash no fever, possibly heat rash",
        ],
        "symptoms": ["rash"],
        "severity": "mild", "referral": False,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "3 saal ka bachcha, MUAC 11.5, thoda patla, follow up karo",
            "3 yr boy, MUAC 11.5 — MAM, nutritional counselling needed",
        ],
        "symptoms": ["malnutrition"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "5 saal ki bachi, {N} din se dast, ORS diya, ab thoda theek hai",
            "5 yr girl, diarrhoea {N} days, ORS given, mild dehydration, stable",
        ],
        "symptoms": ["diarrhoea"],
        "severity": "moderate", "referral": False,
        "age_group": "child", "gender": "F",
    },
    {
        "texts": [
            "2 saal ka bacha, rona band nahi karta, bukhar hai, kaan pakad raha",
            "2 yr boy, fever with ear pulling, possible ear infection",
        ],
        "symptoms": ["fever"],
        "severity": "moderate", "referral": True,
        "age_group": "child", "gender": "M",
    },
    {
        "texts": [
            "Navajaata shishu — 1 mahine ka, saans tez, narak laag raha",
            "Neonate 1 month, tachypnoea, unwell — urgent evaluation",
        ],
        "symptoms": ["breathlessness", "fever"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "random",
    },
    {
        "texts": [
            "4 saal ki bachi, MUAC 9.5, bilateral pitting edema — marasmic kwashiorkor",
            "4 yr girl, MUAC 9.5, oedema — most severe malnutrition, NRC immediately",
        ],
        "symptoms": ["malnutrition"],
        "severity": "severe", "referral": True,
        "age_group": "child", "gender": "F",
    },
]

# ---------------------------------------------------------------------------
# Distribution targets
# ---------------------------------------------------------------------------
CATEGORY_TARGETS = {
    "standard_hindi":   {"templates": CAT1_HINDI,    "train": 50, "eval": 10},
    "bhojpuri":         {"templates": CAT2_BHOJPURI, "train": 60, "eval": 12},
    "hinglish":         {"templates": CAT3_HINGLISH,  "train": 60, "eval": 12},
    "asha_clinical":    {"templates": CAT4_ASHA,      "train": 60, "eval": 12},
    "severe_emergency": {"templates": CAT5_SEVERE,    "train": 50, "eval": 10},
    "mild_cases":       {"templates": CAT6_MILD,      "train": 50, "eval": 10},
    "elderly":          {"templates": CAT7_ELDERLY,   "train": 35, "eval":  7},
    "child_malnutrition": {"templates": CAT8_CHILDREN, "train": 35, "eval":  7},
}


def build_output(tmpl: dict[str, Any], duration: int | None) -> dict[str, Any]:
    """Construct the JSON label dict from a template."""
    gender = tmpl["gender"]
    if gender == "random":
        gender = random.choice(["M", "F", "unknown"])
    return {
        "symptoms": tmpl["symptoms"],
        "duration": duration,
        "ageGroup": tmpl["age_group"],
        "gender": gender,
        "severity": tmpl["severity"],
        "referral": tmpl["referral"],
    }


def generate_examples(
    templates: list[dict[str, Any]], count: int, category: str
) -> list[dict[str, Any]]:
    """
    Generate ``count`` examples by cycling through the template list
    and picking a random text variant for each.
    """
    examples: list[dict[str, Any]] = []
    indices = list(range(len(templates)))
    random.shuffle(indices)

    for i in range(count):
        tmpl = templates[indices[i % len(indices)]]
        text: str = random.choice(tmpl["texts"])

        # Replace {N} with a random duration word
        if "{N}" in text:
            n = random.randint(1, 7)
            text = text.replace("{N}", str(n))
            duration: int | None = n
        else:
            duration = _dur()

        output = build_output(tmpl, duration)

        examples.append({
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user",   "content": text},
                {
                    "role": "assistant",
                    "content": json.dumps(output, ensure_ascii=False),
                },
            ],
            "category": category,
        })

    return examples


def save_jsonl(examples: list[dict[str, Any]], path: Path) -> None:
    """Write examples to a JSONL file (one JSON object per line)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        for ex in examples:
            fh.write(json.dumps(ex, ensure_ascii=False) + "\n")


def print_stats(
    examples: list[dict[str, Any]], label: str = "Dataset"
) -> None:
    """Print a summary of dataset composition."""
    from collections import Counter

    total = len(examples)
    referral_true  = sum(1 for e in examples
                         if json.loads(e["messages"][2]["content"])["referral"])
    referral_false = total - referral_true

    severity_cnt: Counter[str] = Counter()
    symptom_cnt:  Counter[str] = Counter()
    category_cnt: Counter[str] = Counter()

    for ex in examples:
        out = json.loads(ex["messages"][2]["content"])
        severity_cnt[out["severity"]] += 1
        for s in out["symptoms"]:
            symptom_cnt[s] += 1
        category_cnt[ex["category"]] += 1

    print(f"\n{'='*56}")
    print(f"  {label}  —  {total} examples")
    print(f"{'='*56}")
    print(f"  Referral true : {referral_true}  ({referral_true/total*100:.1f}%)")
    print(f"  Referral false: {referral_false}  ({referral_false/total*100:.1f}%)")
    print()
    print("  Severity distribution:")
    for sev in ["mild", "moderate", "severe"]:
        c = severity_cnt[sev]
        print(f"    {sev:10s}: {c:4d}  ({c/total*100:.1f}%)")
    print()
    print("  Top symptoms:")
    for sym, cnt in symptom_cnt.most_common(8):
        print(f"    {sym:20s}: {cnt}")
    print()
    print("  Category counts:")
    for cat, cnt in category_cnt.most_common():
        print(f"    {cat:25s}: {cnt}")

    # Warn if any canonical symptom appears fewer than 10 times
    missing = [s for s in CANONICAL_SYMPTOMS if symptom_cnt[s] < 10]
    if missing:
        print(f"\n  WARNING — symptoms with < 10 occurrences: {missing}")
    print(f"{'='*56}\n")


def main() -> None:
    """Generate and save train and eval JSONL datasets."""
    train_examples: list[dict[str, Any]] = []
    eval_examples:  list[dict[str, Any]] = []

    for cat_name, cfg in CATEGORY_TARGETS.items():
        all_ex = generate_examples(
            cfg["templates"],
            cfg["train"] + cfg["eval"],
            cat_name,
        )
        random.shuffle(all_ex)
        train_examples.extend(all_ex[: cfg["train"]])
        eval_examples.extend(all_ex[cfg["train"]:])

    random.shuffle(train_examples)
    random.shuffle(eval_examples)

    here = Path(__file__).parent
    train_path = here / "jansetu_symptoms_train.jsonl"
    eval_path  = here / "jansetu_symptoms_eval.jsonl"

    save_jsonl(train_examples, train_path)
    save_jsonl(eval_examples,  eval_path)

    print(f"Saved {len(train_examples)} training examples -> {train_path}")
    print(f"Saved {len(eval_examples)}  eval examples     -> {eval_path}")

    print_stats(train_examples, "TRAIN set")
    print_stats(eval_examples,  "EVAL set")


if __name__ == "__main__":
    main()
