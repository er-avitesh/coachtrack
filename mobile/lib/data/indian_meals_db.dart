// lib/data/indian_meals_db.dart
// Offline-first Indian food database — 86 foods, bilingual (English + Hindi)
// All nutrition values are per 100g unless noted. Sources: ICMR/NIN tables + USDA.

import '../models/models.dart';

// ── Reusable serving size presets ─────────────────────────────────────────────

const _svRice = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
  ServingSize(label: '1 bowl / 1 कटोरा  (250g)', grams: 250),
  ServingSize(label: '1 plate / 1 थाली  (400g)', grams: 400),
];

const _svRoti = [
  ServingSize(label: '1 roti / 1 रोटी  (35g)', grams: 35),
  ServingSize(label: '2 rotis / 2 रोटी  (70g)', grams: 70),
  ServingSize(label: '3 rotis / 3 रोटी  (105g)', grams: 105),
  ServingSize(label: '100g', grams: 100),
];

const _svParatha = [
  ServingSize(label: '1 paratha / 1 पराठा  (70g)', grams: 70),
  ServingSize(label: '2 parathas / 2 पराठा  (140g)', grams: 140),
  ServingSize(label: '100g', grams: 100),
];

const _svNaan = [
  ServingSize(label: '1 naan / 1 नान  (90g)', grams: 90),
  ServingSize(label: '2 naans / 2 नान  (180g)', grams: 180),
  ServingSize(label: '100g', grams: 100),
];

const _svPuri = [
  ServingSize(label: '1 puri / 1 पूरी  (35g)', grams: 35),
  ServingSize(label: '2 puris / 2 पूरी  (70g)', grams: 70),
  ServingSize(label: '4 puris / 4 पूरी  (140g)', grams: 140),
  ServingSize(label: '100g', grams: 100),
];

const _svCurry = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
  ServingSize(label: '1 bowl / 1 कटोरा  (200g)', grams: 200),
];

const _svDal = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
  ServingSize(label: '1 bowl / 1 कटोरा  (200g)', grams: 200),
  ServingSize(label: '2 katoris / 2 कटोरी  (300g)', grams: 300),
];

const _svSnack = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 piece / 1 टुकड़ा  (80g)', grams: 80),
  ServingSize(label: '2 pieces / 2 टुकड़े  (160g)', grams: 160),
];

const _svDrink = [
  ServingSize(label: '100ml', grams: 100),
  ServingSize(label: '1 cup / 1 कप  (150ml)', grams: 150),
  ServingSize(label: '1 glass / 1 गिलास  (250ml)', grams: 250),
];

const _svFruit = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 small / छोटा  (80g)', grams: 80),
  ServingSize(label: '1 medium / मध्यम  (130g)', grams: 130),
  ServingSize(label: '1 large / बड़ा  (180g)', grams: 180),
];

const _svPaneer = [
  ServingSize(label: '25g', grams: 25),
  ServingSize(label: '50g', grams: 50),
  ServingSize(label: '100g', grams: 100),
];

const _svGhee = [
  ServingSize(label: '1 tsp / 1 चम्मच  (5g)', grams: 5),
  ServingSize(label: '1 tbsp / 1 बड़ा चम्मच  (15g)', grams: 15),
  ServingSize(label: '100g', grams: 100),
];

const _svEgg = [
  ServingSize(label: '1 egg / 1 अंडा  (50g)', grams: 50),
  ServingSize(label: '2 eggs / 2 अंडे  (100g)', grams: 100),
  ServingSize(label: '3 eggs / 3 अंडे  (150g)', grams: 150),
];

const _svBiryani = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 plate / 1 थाली  (300g)', grams: 300),
  ServingSize(label: '1 large plate / बड़ी थाली  (450g)', grams: 450),
];

const _svSweet = [
  ServingSize(label: '100g', grams: 100),
  ServingSize(label: '1 piece / 1 टुकड़ा  (50g)', grams: 50),
  ServingSize(label: '2 pieces / 2 टुकड़े  (100g)', grams: 100),
];

// ── The complete Indian foods database ───────────────────────────────────────

const List<FoodItem> indianFoodsDb = [

  // ── Rice & Cooked Grains ─────────────────────────────────────────────────

  FoodItem(
    id: 'cooked_white_rice',
    name: 'Cooked White Rice',
    nameHi: 'उबले सफ़ेद चावल',
    caloriesPer100g: 130, proteinG: 2.7, carbsG: 28.2, fatG: 0.3, fiberG: 0.4,
    servings: _svRice,
  ),
  FoodItem(
    id: 'cooked_brown_rice',
    name: 'Cooked Brown Rice',
    nameHi: 'ब्राउन चावल',
    caloriesPer100g: 123, proteinG: 2.6, carbsG: 25.6, fatG: 0.9, fiberG: 1.8,
    servings: _svRice,
  ),
  FoodItem(
    id: 'cooked_basmati_rice',
    name: 'Cooked Basmati Rice',
    nameHi: 'बासमती चावल',
    caloriesPer100g: 121, proteinG: 2.5, carbsG: 25.2, fatG: 0.3, fiberG: 0.4,
    servings: _svRice,
  ),
  FoodItem(
    id: 'idli',
    name: 'Steamed Idli',
    nameHi: 'इडली',
    caloriesPer100g: 58, proteinG: 2.0, carbsG: 11.5, fatG: 0.3, fiberG: 0.5,
    servings: [
      ServingSize(label: '1 idli / 1 इडली  (40g)', grams: 40),
      ServingSize(label: '2 idlis / 2 इडली  (80g)', grams: 80),
      ServingSize(label: '3 idlis / 3 इडली  (120g)', grams: 120),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'plain_dosa',
    name: 'Plain Dosa',
    nameHi: 'सादा डोसा',
    caloriesPer100g: 162, proteinG: 3.5, carbsG: 25.0, fatG: 5.2, fiberG: 0.8,
    servings: [
      ServingSize(label: '1 dosa / 1 डोसा  (85g)', grams: 85),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'masala_dosa',
    name: 'Masala Dosa',
    nameHi: 'मसाला डोसा',
    caloriesPer100g: 149, proteinG: 3.8, carbsG: 22.0, fatG: 5.5, fiberG: 1.5,
    servings: [
      ServingSize(label: '1 dosa / 1 डोसा  (140g)', grams: 140),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'upma',
    name: 'Upma',
    nameHi: 'उपमा',
    caloriesPer100g: 133, proteinG: 2.8, carbsG: 22.0, fatG: 3.8, fiberG: 1.5,
    servings: _svRice,
  ),
  FoodItem(
    id: 'poha',
    name: 'Poha (Flattened Rice)',
    nameHi: 'पोहा',
    caloriesPer100g: 130, proteinG: 2.5, carbsG: 25.5, fatG: 2.5, fiberG: 1.0,
    servings: _svRice,
  ),

  // ── Indian Breads ────────────────────────────────────────────────────────

  FoodItem(
    id: 'roti_chapati',
    name: 'Roti / Chapati',
    nameHi: 'रोटी / चपाती',
    caloriesPer100g: 297, proteinG: 8.5, carbsG: 52.0, fatG: 5.8, fiberG: 4.2,
    servings: _svRoti,
  ),
  FoodItem(
    id: 'whole_wheat_paratha',
    name: 'Whole Wheat Paratha',
    nameHi: 'गेहूं का पराठा',
    caloriesPer100g: 327, proteinG: 7.5, carbsG: 50.5, fatG: 10.5, fiberG: 3.8,
    servings: _svParatha,
  ),
  FoodItem(
    id: 'aloo_paratha',
    name: 'Aloo Paratha',
    nameHi: 'आलू पराठा',
    caloriesPer100g: 355, proteinG: 7.0, carbsG: 52.0, fatG: 13.0, fiberG: 3.5,
    servings: _svParatha,
  ),
  FoodItem(
    id: 'plain_naan',
    name: 'Plain Naan',
    nameHi: 'सादा नान',
    caloriesPer100g: 310, proteinG: 9.5, carbsG: 54.0, fatG: 5.0, fiberG: 2.0,
    servings: _svNaan,
  ),
  FoodItem(
    id: 'butter_naan',
    name: 'Butter Naan',
    nameHi: 'बटर नान',
    caloriesPer100g: 340, proteinG: 9.5, carbsG: 54.0, fatG: 9.0, fiberG: 2.0,
    servings: _svNaan,
  ),
  FoodItem(
    id: 'puri',
    name: 'Puri',
    nameHi: 'पूरी',
    caloriesPer100g: 403, proteinG: 6.5, carbsG: 52.0, fatG: 19.0, fiberG: 2.5,
    servings: _svPuri,
  ),
  FoodItem(
    id: 'bhature',
    name: 'Bhature',
    nameHi: 'भटूरे',
    caloriesPer100g: 390, proteinG: 7.0, carbsG: 51.0, fatG: 17.0, fiberG: 2.0,
    servings: [
      ServingSize(label: '1 bhatura / 1 भटूरा  (90g)', grams: 90),
      ServingSize(label: '2 bhaturas / 2 भटूरे  (180g)', grams: 180),
      ServingSize(label: '100g', grams: 100),
    ],
  ),

  // ── Dals & Legumes ───────────────────────────────────────────────────────

  FoodItem(
    id: 'dal_tadka',
    name: 'Dal Tadka',
    nameHi: 'दाल तड़का',
    caloriesPer100g: 85, proteinG: 5.5, carbsG: 12.0, fatG: 2.5, fiberG: 3.0,
    servings: _svDal,
  ),
  FoodItem(
    id: 'dal_makhani',
    name: 'Dal Makhani',
    nameHi: 'दाल मखनी',
    caloriesPer100g: 135, proteinG: 7.0, carbsG: 11.0, fatG: 7.5, fiberG: 4.0,
    servings: _svDal,
  ),
  FoodItem(
    id: 'chana_dal',
    name: 'Chana Dal',
    nameHi: 'चना दाल',
    caloriesPer100g: 96, proteinG: 6.5, carbsG: 14.0, fatG: 1.5, fiberG: 5.5,
    servings: _svDal,
  ),
  FoodItem(
    id: 'moong_dal_yellow',
    name: 'Yellow Moong Dal',
    nameHi: 'पीली मूंग दाल',
    caloriesPer100g: 82, proteinG: 5.5, carbsG: 12.5, fatG: 0.7, fiberG: 3.0,
    servings: _svDal,
  ),
  FoodItem(
    id: 'masoor_dal',
    name: 'Masoor Dal (Red Lentil)',
    nameHi: 'मसूर दाल',
    caloriesPer100g: 92, proteinG: 7.0, carbsG: 13.0, fatG: 0.7, fiberG: 4.0,
    servings: _svDal,
  ),
  FoodItem(
    id: 'rajma',
    name: 'Rajma (Kidney Beans)',
    nameHi: 'राजमा',
    caloriesPer100g: 127, proteinG: 8.5, carbsG: 19.0, fatG: 1.0, fiberG: 6.5,
    servings: _svDal,
  ),
  FoodItem(
    id: 'chole_chana_masala',
    name: 'Chole / Chana Masala',
    nameHi: 'छोले / चना मसाला',
    caloriesPer100g: 165, proteinG: 8.5, carbsG: 18.0, fatG: 6.0, fiberG: 6.0,
    servings: _svDal,
  ),
  FoodItem(
    id: 'kadhi',
    name: 'Kadhi',
    nameHi: 'कढ़ी',
    caloriesPer100g: 78, proteinG: 2.5, carbsG: 8.0, fatG: 4.0, fiberG: 0.5,
    servings: _svDal,
  ),

  // ── Paneer Dishes ────────────────────────────────────────────────────────

  FoodItem(
    id: 'paneer_raw',
    name: 'Paneer (Cottage Cheese)',
    nameHi: 'पनीर',
    caloriesPer100g: 265, proteinG: 18.3, carbsG: 3.6, fatG: 20.8, fiberG: 0.0,
    servings: _svPaneer,
  ),
  FoodItem(
    id: 'paneer_butter_masala',
    name: 'Paneer Butter Masala',
    nameHi: 'पनीर बटर मसाला',
    caloriesPer100g: 184, proteinG: 10.5, carbsG: 8.0, fatG: 12.5, fiberG: 1.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'palak_paneer',
    name: 'Palak Paneer',
    nameHi: 'पालक पनीर',
    caloriesPer100g: 155, proteinG: 9.5, carbsG: 7.0, fatG: 11.0, fiberG: 2.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'paneer_bhurji',
    name: 'Paneer Bhurji',
    nameHi: 'पनीर भुर्जी',
    caloriesPer100g: 193, proteinG: 12.0, carbsG: 6.0, fatG: 14.0, fiberG: 1.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'matar_paneer',
    name: 'Matar Paneer',
    nameHi: 'मटर पनीर',
    caloriesPer100g: 168, proteinG: 10.0, carbsG: 9.0, fatG: 11.0, fiberG: 3.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'kadhai_paneer',
    name: 'Kadhai Paneer',
    nameHi: 'कढ़ाई पनीर',
    caloriesPer100g: 215, proteinG: 14.0, carbsG: 6.0, fatG: 15.0, fiberG: 1.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'shahi_paneer',
    name: 'Shahi Paneer',
    nameHi: 'शाही पनीर',
    caloriesPer100g: 232, proteinG: 11.0, carbsG: 9.0, fatG: 17.5, fiberG: 1.0,
    servings: _svCurry,
  ),

  // ── Vegetable Dishes ─────────────────────────────────────────────────────

  FoodItem(
    id: 'aloo_matar',
    name: 'Aloo Matar',
    nameHi: 'आलू मटर',
    caloriesPer100g: 95, proteinG: 2.5, carbsG: 14.0, fatG: 3.5, fiberG: 2.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'aloo_gobi',
    name: 'Aloo Gobi',
    nameHi: 'आलू गोबी',
    caloriesPer100g: 78, proteinG: 2.0, carbsG: 10.0, fatG: 3.2, fiberG: 2.2,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'aloo_sabzi',
    name: 'Aloo Sabzi',
    nameHi: 'आलू सब्जी',
    caloriesPer100g: 97, proteinG: 2.2, carbsG: 14.0, fatG: 3.8, fiberG: 2.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'bhindi_masala',
    name: 'Bhindi Masala (Okra)',
    nameHi: 'भिंडी मसाला',
    caloriesPer100g: 72, proteinG: 2.2, carbsG: 8.0, fatG: 3.5, fiberG: 3.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'palak_sabzi',
    name: 'Palak / Saag',
    nameHi: 'पालक / साग',
    caloriesPer100g: 58, proteinG: 3.5, carbsG: 5.0, fatG: 3.0, fiberG: 3.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'baingan_bharta',
    name: 'Baingan Bharta',
    nameHi: 'बैंगन भर्ता',
    caloriesPer100g: 70, proteinG: 2.0, carbsG: 8.0, fatG: 3.5, fiberG: 3.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'mix_veg_curry',
    name: 'Mix Vegetable Curry',
    nameHi: 'मिक्स सब्जी',
    caloriesPer100g: 82, proteinG: 2.5, carbsG: 9.0, fatG: 4.0, fiberG: 2.8,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'methi_sabzi',
    name: 'Methi Sabzi (Fenugreek)',
    nameHi: 'मेथी सब्जी',
    caloriesPer100g: 63, proteinG: 3.0, carbsG: 6.0, fatG: 3.5, fiberG: 3.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'lauki_sabzi',
    name: 'Lauki Sabzi (Bottle Gourd)',
    nameHi: 'लौकी सब्जी',
    caloriesPer100g: 45, proteinG: 1.5, carbsG: 5.0, fatG: 2.0, fiberG: 2.0,
    servings: _svCurry,
  ),

  // ── Rice Dishes ──────────────────────────────────────────────────────────

  FoodItem(
    id: 'chicken_biryani',
    name: 'Chicken Biryani',
    nameHi: 'चिकन बिरयानी',
    caloriesPer100g: 199, proteinG: 14.0, carbsG: 22.0, fatG: 6.5, fiberG: 1.0,
    servings: _svBiryani,
  ),
  FoodItem(
    id: 'veg_biryani',
    name: 'Veg Biryani',
    nameHi: 'वेज बिरयानी',
    caloriesPer100g: 172, proteinG: 4.0, carbsG: 27.0, fatG: 5.5, fiberG: 1.5,
    servings: _svBiryani,
  ),
  FoodItem(
    id: 'veg_pulao',
    name: 'Veg Pulao',
    nameHi: 'वेज पुलाव',
    caloriesPer100g: 148, proteinG: 3.5, carbsG: 25.0, fatG: 3.5, fiberG: 1.2,
    servings: _svRice,
  ),
  FoodItem(
    id: 'khichdi',
    name: 'Khichdi',
    nameHi: 'खिचड़ी',
    caloriesPer100g: 92, proteinG: 4.5, carbsG: 15.0, fatG: 1.5, fiberG: 2.0,
    servings: _svRice,
  ),
  FoodItem(
    id: 'curd_rice',
    name: 'Curd Rice',
    nameHi: 'दही चावल',
    caloriesPer100g: 98, proteinG: 2.8, carbsG: 18.0, fatG: 2.5, fiberG: 0.5,
    servings: _svRice,
  ),

  // ── Chicken ──────────────────────────────────────────────────────────────

  FoodItem(
    id: 'chicken_curry',
    name: 'Chicken Curry',
    nameHi: 'चिकन करी',
    caloriesPer100g: 175, proteinG: 18.0, carbsG: 5.0, fatG: 9.5, fiberG: 1.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'butter_chicken',
    name: 'Butter Chicken',
    nameHi: 'बटर चिकन',
    caloriesPer100g: 195, proteinG: 18.0, carbsG: 7.0, fatG: 12.0, fiberG: 1.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'tandoori_chicken',
    name: 'Tandoori Chicken',
    nameHi: 'तंदूरी चिकन',
    caloriesPer100g: 173, proteinG: 26.0, carbsG: 5.0, fatG: 6.0, fiberG: 0.5,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1 piece / 1 टुकड़ा  (120g)', grams: 120),
      ServingSize(label: '2 pieces / 2 टुकड़े  (240g)', grams: 240),
    ],
  ),
  FoodItem(
    id: 'chicken_tikka',
    name: 'Chicken Tikka',
    nameHi: 'चिकन टिक्का',
    caloriesPer100g: 185, proteinG: 25.0, carbsG: 4.0, fatG: 8.0, fiberG: 0.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'chicken_tikka_masala',
    name: 'Chicken Tikka Masala',
    nameHi: 'चिकन टिक्का मसाला',
    caloriesPer100g: 205, proteinG: 19.0, carbsG: 7.0, fatG: 13.0, fiberG: 1.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'chicken_keema',
    name: 'Chicken Keema',
    nameHi: 'चिकन कीमा',
    caloriesPer100g: 185, proteinG: 20.0, carbsG: 4.0, fatG: 11.0, fiberG: 0.5,
    servings: _svCurry,
  ),

  // ── Eggs ─────────────────────────────────────────────────────────────────

  FoodItem(
    id: 'boiled_egg',
    name: 'Boiled Egg',
    nameHi: 'उबला अंडा',
    caloriesPer100g: 155, proteinG: 13.0, carbsG: 1.1, fatG: 11.0, fiberG: 0.0,
    servings: _svEgg,
  ),
  FoodItem(
    id: 'egg_curry',
    name: 'Egg Curry',
    nameHi: 'अंडे की करी',
    caloriesPer100g: 165, proteinG: 11.0, carbsG: 5.0, fatG: 11.0, fiberG: 1.0,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'omelette_plain',
    name: 'Plain Omelette',
    nameHi: 'सादा ऑमलेट',
    caloriesPer100g: 180, proteinG: 11.5, carbsG: 0.5, fatG: 14.5, fiberG: 0.0,
    servings: _svEgg,
  ),
  FoodItem(
    id: 'egg_bhurji',
    name: 'Egg Bhurji (Scrambled)',
    nameHi: 'अंडा भुर्जी',
    caloriesPer100g: 172, proteinG: 11.0, carbsG: 3.0, fatG: 13.0, fiberG: 0.5,
    servings: _svEgg,
  ),

  // ── Fish & Mutton ────────────────────────────────────────────────────────

  FoodItem(
    id: 'fish_curry',
    name: 'Fish Curry',
    nameHi: 'मछली करी',
    caloriesPer100g: 135, proteinG: 16.0, carbsG: 5.0, fatG: 7.0, fiberG: 0.5,
    servings: _svCurry,
  ),
  FoodItem(
    id: 'mutton_curry',
    name: 'Mutton Curry',
    nameHi: 'मटन करी',
    caloriesPer100g: 210, proteinG: 18.0, carbsG: 5.0, fatG: 14.0, fiberG: 0.5,
    servings: _svCurry,
  ),

  // ── Dairy ────────────────────────────────────────────────────────────────

  FoodItem(
    id: 'whole_milk',
    name: 'Whole Milk',
    nameHi: 'दूध',
    caloriesPer100g: 61, proteinG: 3.2, carbsG: 4.8, fatG: 3.4, fiberG: 0.0,
    servings: _svDrink,
  ),
  FoodItem(
    id: 'curd_dahi',
    name: 'Curd / Dahi',
    nameHi: 'दही',
    caloriesPer100g: 98, proteinG: 3.1, carbsG: 3.4, fatG: 4.3, fiberG: 0.0,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
      ServingSize(label: '1 bowl / 1 कटोरा  (200g)', grams: 200),
    ],
  ),
  FoodItem(
    id: 'low_fat_dahi',
    name: 'Low Fat Dahi',
    nameHi: 'कम वसा दही',
    caloriesPer100g: 62, proteinG: 4.0, carbsG: 4.5, fatG: 0.8, fiberG: 0.0,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
    ],
  ),
  FoodItem(
    id: 'lassi_sweet',
    name: 'Sweet Lassi',
    nameHi: 'मीठी लस्सी',
    caloriesPer100g: 88, proteinG: 2.5, carbsG: 13.0, fatG: 2.8, fiberG: 0.0,
    servings: _svDrink,
  ),
  FoodItem(
    id: 'buttermilk_chaas',
    name: 'Buttermilk / Chaas',
    nameHi: 'छाछ / मट्ठा',
    caloriesPer100g: 15, proteinG: 0.7, carbsG: 1.6, fatG: 0.6, fiberG: 0.0,
    servings: _svDrink,
  ),
  FoodItem(
    id: 'ghee',
    name: 'Ghee (Clarified Butter)',
    nameHi: 'घी',
    caloriesPer100g: 900, proteinG: 0.0, carbsG: 0.0, fatG: 99.5, fiberG: 0.0,
    servings: _svGhee,
  ),
  FoodItem(
    id: 'butter',
    name: 'Butter',
    nameHi: 'मक्खन',
    caloriesPer100g: 717, proteinG: 0.9, carbsG: 0.1, fatG: 81.0, fiberG: 0.0,
    servings: _svGhee,
  ),

  // ── Snacks & Street Food ─────────────────────────────────────────────────

  FoodItem(
    id: 'samosa_veg',
    name: 'Veg Samosa',
    nameHi: 'समोसा',
    caloriesPer100g: 308, proteinG: 5.5, carbsG: 36.0, fatG: 16.0, fiberG: 2.5,
    servings: [
      ServingSize(label: '1 samosa / 1 समोसा  (85g)', grams: 85),
      ServingSize(label: '2 samosas / 2 समोसे  (170g)', grams: 170),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'veg_pakora',
    name: 'Veg Pakora / Bhajiya',
    nameHi: 'पकोड़ा / भजिया',
    caloriesPer100g: 260, proteinG: 6.5, carbsG: 28.0, fatG: 14.0, fiberG: 2.5,
    servings: _svSnack,
  ),
  FoodItem(
    id: 'dhokla',
    name: 'Dhokla',
    nameHi: 'ढोकला',
    caloriesPer100g: 152, proteinG: 5.5, carbsG: 23.0, fatG: 4.5, fiberG: 1.5,
    servings: [
      ServingSize(label: '2 pieces / 2 टुकड़े  (80g)', grams: 80),
      ServingSize(label: '4 pieces / 4 टुकड़े  (160g)', grams: 160),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'pav_bhaji',
    name: 'Pav Bhaji',
    nameHi: 'पाव भाजी',
    caloriesPer100g: 188, proteinG: 5.5, carbsG: 25.0, fatG: 8.0, fiberG: 4.0,
    servings: [
      ServingSize(label: '1 serving (bhaji) / 1 सर्विंग  (150g)', grams: 150),
      ServingSize(label: '1 plate (bhaji + 2 pav)  (290g)', grams: 290),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'vada_pav',
    name: 'Vada Pav',
    nameHi: 'वड़ा पाव',
    caloriesPer100g: 290, proteinG: 7.0, carbsG: 44.0, fatG: 10.0, fiberG: 3.0,
    servings: [
      ServingSize(label: '1 vada pav / 1 वड़ा पाव  (130g)', grams: 130),
      ServingSize(label: '2 vada pav / 2 वड़ा पाव  (260g)', grams: 260),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'aloo_tikki',
    name: 'Aloo Tikki',
    nameHi: 'आलू टिक्की',
    caloriesPer100g: 195, proteinG: 3.5, carbsG: 28.0, fatG: 8.0, fiberG: 2.5,
    servings: [
      ServingSize(label: '1 tikki / 1 टिक्की  (60g)', grams: 60),
      ServingSize(label: '2 tikkis / 2 टिक्की  (120g)', grams: 120),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'bhel_puri',
    name: 'Bhel Puri',
    nameHi: 'भेल पूरी',
    caloriesPer100g: 188, proteinG: 4.5, carbsG: 32.0, fatG: 5.0, fiberG: 2.5,
    servings: [
      ServingSize(label: '1 plate / 1 थाली  (150g)', grams: 150),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'kachori',
    name: 'Kachori',
    nameHi: 'कचौरी',
    caloriesPer100g: 450, proteinG: 8.0, carbsG: 54.0, fatG: 22.0, fiberG: 3.0,
    servings: [
      ServingSize(label: '1 kachori / 1 कचौरी  (60g)', grams: 60),
      ServingSize(label: '2 kachoris / 2 कचौरी  (120g)', grams: 120),
      ServingSize(label: '100g', grams: 100),
    ],
  ),

  // ── Fruits ───────────────────────────────────────────────────────────────

  FoodItem(
    id: 'banana',
    name: 'Banana',
    nameHi: 'केला',
    caloriesPer100g: 89, proteinG: 1.1, carbsG: 23.0, fatG: 0.3, fiberG: 2.6,
    servings: [
      ServingSize(label: '1 small / छोटा  (80g)', grams: 80),
      ServingSize(label: '1 medium / मध्यम  (118g)', grams: 118),
      ServingSize(label: '1 large / बड़ा  (152g)', grams: 152),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'apple',
    name: 'Apple',
    nameHi: 'सेब',
    caloriesPer100g: 52, proteinG: 0.3, carbsG: 13.8, fatG: 0.2, fiberG: 2.4,
    servings: [
      ServingSize(label: '1 small / छोटा  (140g)', grams: 140),
      ServingSize(label: '1 medium / मध्यम  (182g)', grams: 182),
      ServingSize(label: '1 large / बड़ा  (223g)', grams: 223),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'mango',
    name: 'Mango',
    nameHi: 'आम',
    caloriesPer100g: 60, proteinG: 0.8, carbsG: 15.0, fatG: 0.4, fiberG: 1.6,
    servings: [
      ServingSize(label: '1/2 mango / आधा आम  (130g)', grams: 130),
      ServingSize(label: '1 medium mango / 1 आम  (265g)', grams: 265),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'orange',
    name: 'Orange',
    nameHi: 'संतरा',
    caloriesPer100g: 47, proteinG: 0.9, carbsG: 12.0, fatG: 0.1, fiberG: 2.4,
    servings: _svFruit,
  ),
  FoodItem(
    id: 'guava',
    name: 'Guava',
    nameHi: 'अमरूद',
    caloriesPer100g: 68, proteinG: 2.6, carbsG: 14.3, fatG: 0.9, fiberG: 5.4,
    servings: _svFruit,
  ),
  FoodItem(
    id: 'watermelon',
    name: 'Watermelon',
    nameHi: 'तरबूज',
    caloriesPer100g: 30, proteinG: 0.6, carbsG: 7.6, fatG: 0.2, fiberG: 0.4,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1 slice / 1 स्लाइस  (280g)', grams: 280),
      ServingSize(label: '2 cups / 2 कप  (300g)', grams: 300),
    ],
  ),
  FoodItem(
    id: 'papaya',
    name: 'Papaya',
    nameHi: 'पपीता',
    caloriesPer100g: 43, proteinG: 0.5, carbsG: 11.0, fatG: 0.4, fiberG: 1.7,
    servings: _svFruit,
  ),
  FoodItem(
    id: 'grapes',
    name: 'Grapes',
    nameHi: 'अंगूर',
    caloriesPer100g: 69, proteinG: 0.7, carbsG: 18.0, fatG: 0.2, fiberG: 0.9,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1 cup / 1 कप  (150g)', grams: 150),
    ],
  ),
  FoodItem(
    id: 'pomegranate',
    name: 'Pomegranate',
    nameHi: 'अनार',
    caloriesPer100g: 83, proteinG: 1.7, carbsG: 18.7, fatG: 1.2, fiberG: 4.0,
    servings: [
      ServingSize(label: '100g', grams: 100),
      ServingSize(label: '1/2 pomegranate / आधा अनार  (140g)', grams: 140),
    ],
  ),

  // ── Sweets ───────────────────────────────────────────────────────────────

  FoodItem(
    id: 'kheer_rice_pudding',
    name: 'Kheer (Rice Pudding)',
    nameHi: 'खीर',
    caloriesPer100g: 175, proteinG: 4.5, carbsG: 26.0, fatG: 6.5, fiberG: 0.3,
    servings: [
      ServingSize(label: '1 katori / 1 कटोरी  (150g)', grams: 150),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'rasgulla',
    name: 'Rasgulla',
    nameHi: 'रसगुल्ला',
    caloriesPer100g: 148, proteinG: 4.0, carbsG: 28.0, fatG: 3.0, fiberG: 0.0,
    servings: _svSweet,
  ),
  FoodItem(
    id: 'gulab_jamun',
    name: 'Gulab Jamun',
    nameHi: 'गुलाब जामुन',
    caloriesPer100g: 385, proteinG: 5.0, carbsG: 60.0, fatG: 14.0, fiberG: 0.5,
    servings: [
      ServingSize(label: '1 piece / 1 टुकड़ा  (40g)', grams: 40),
      ServingSize(label: '2 pieces / 2 टुकड़े  (80g)', grams: 80),
      ServingSize(label: '100g', grams: 100),
    ],
  ),
  FoodItem(
    id: 'gajar_ka_halwa',
    name: 'Gajar ka Halwa',
    nameHi: 'गाजर का हलवा',
    caloriesPer100g: 258, proteinG: 4.5, carbsG: 32.0, fatG: 12.0, fiberG: 1.5,
    servings: [
      ServingSize(label: '1 serving / 1 सर्विंग  (100g)', grams: 100),
      ServingSize(label: '1 bowl / 1 कटोरी  (150g)', grams: 150),
    ],
  ),

  // ── Beverages ────────────────────────────────────────────────────────────

  FoodItem(
    id: 'chai_milk_tea',
    name: 'Chai / Milk Tea',
    nameHi: 'चाय',
    caloriesPer100g: 35, proteinG: 1.0, carbsG: 5.5, fatG: 1.2, fiberG: 0.0,
    servings: _svDrink,
  ),
  FoodItem(
    id: 'coffee_with_milk',
    name: 'Coffee with Milk',
    nameHi: 'कॉफी',
    caloriesPer100g: 25, proteinG: 0.8, carbsG: 3.5, fatG: 0.8, fiberG: 0.0,
    servings: _svDrink,
  ),
];

// ── Search helper ─────────────────────────────────────────────────────────────
// Returns up to [limit] results matching [query] case-insensitively.
List<FoodItem> searchLocalFoods(String query, {int limit = 20}) {
  if (query.trim().length < 2) return [];
  final lower = query.trim().toLowerCase();
  return indianFoodsDb
      .where((f) =>
          f.name.toLowerCase().contains(lower) ||
          f.nameHi.contains(lower) ||
          f.id.contains(lower.replaceAll(' ', '_')))
      .take(limit)
      .toList();
}
