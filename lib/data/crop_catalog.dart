import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CropCategory { fruit, vegetable }

extension CropCategoryX on CropCategory {
  String get label => this == CropCategory.fruit ? 'Fruit' : 'Vegetable';
  String get plural => this == CropCategory.fruit ? 'Fruits' : 'Vegetables';
  String get headerEmoji => this == CropCategory.fruit ? '🍎' : '🥦';

  LinearGradient get gradient => this == CropCategory.fruit
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF74C69D), Color(0xFF2D6A4F)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4A261), Color(0xFFE76F51)],
        );

  Color get accent =>
      this == CropCategory.fruit ? AppColors.forestMid : AppColors.terracotta;
}

class CropInfo {
  final String name;
  final String emoji;
  final CropCategory category;
  final String latin;
  final String idealTemp;
  final String waterNeed;
  final int growthDays;
  final String difficulty;
  final double phMin;
  final double phMax;
  final int tempMin;
  final int tempMax;
  final String overview;
  final List<String> growingConditions;
  final String nutrition;
  final String marketPrice;
  final String marketDemand;
  final List<String> bestRegions;

  const CropInfo({
    required this.name,
    required this.emoji,
    required this.category,
    required this.latin,
    required this.idealTemp,
    required this.waterNeed,
    required this.growthDays,
    required this.difficulty,
    required this.phMin,
    required this.phMax,
    required this.tempMin,
    required this.tempMax,
    required this.overview,
    required this.growingConditions,
    required this.nutrition,
    required this.marketPrice,
    required this.marketDemand,
    required this.bestRegions,
  });
}

/// TODO: Connect to backend — replace with live crop catalog from server.
class CropCatalog {
  static const List<CropInfo> fruits = [
    CropInfo(
      name: 'Apple',
      emoji: '🍎',
      category: CropCategory.fruit,
      latin: 'Malus domestica',
      idealTemp: '15-25°C',
      waterNeed: 'Medium',
      growthDays: 150,
      difficulty: 'Moderate',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 15,
      tempMax: 25,
      overview:
          'A versatile temperate fruit tree thriving in well-drained loamy soils with cool winters and moderate summers.',
      growingConditions: [
        'Full sun, sheltered from strong winds',
        'Loamy, well-drained soil',
        'Annual pruning required',
        'Chill hours: 800-1000',
      ],
      nutrition: 'High in fiber, vitamin C, antioxidants',
      marketPrice: '\$1.80/kg average',
      marketDemand: 'Stable year-round',
      bestRegions: ['Cap Bon', 'Beja', 'Jendouba'],
    ),
    CropInfo(
      name: 'Mango',
      emoji: '🥭',
      category: CropCategory.fruit,
      latin: 'Mangifera indica',
      idealTemp: '24-30°C',
      waterNeed: 'Medium',
      growthDays: 120,
      difficulty: 'Moderate',
      phMin: 5.5,
      phMax: 7.5,
      tempMin: 24,
      tempMax: 30,
      overview:
          'Tropical fruit tree producing sweet stone fruits, prefers warm climates with a distinct dry season.',
      growingConditions: [
        'Warm tropical climate',
        'Sandy loam, well-drained',
        'Drought-tolerant once established',
        'Frost-sensitive',
      ],
      nutrition: 'Rich in vitamin A, C, fiber',
      marketPrice: '\$3.20/kg average',
      marketDemand: 'High during summer',
      bestRegions: ['Gabes', 'Medenine'],
    ),
    CropInfo(
      name: 'Banana',
      emoji: '🍌',
      category: CropCategory.fruit,
      latin: 'Musa acuminata',
      idealTemp: '26-30°C',
      waterNeed: 'High',
      growthDays: 270,
      difficulty: 'Hard',
      phMin: 5.5,
      phMax: 7.0,
      tempMin: 26,
      tempMax: 30,
      overview:
          'Fast-growing tropical herbaceous plant requiring consistent warmth and moisture.',
      growingConditions: [
        'High humidity (>50%)',
        'Rich, deep loamy soil',
        'Wind protection essential',
        'Heavy potassium feeder',
      ],
      nutrition: 'Excellent potassium, vitamin B6',
      marketPrice: '\$1.20/kg average',
      marketDemand: 'High year-round',
      bestRegions: ['Gabes', 'Sfax'],
    ),
    CropInfo(
      name: 'Orange',
      emoji: '🍊',
      category: CropCategory.fruit,
      latin: 'Citrus sinensis',
      idealTemp: '20-30°C',
      waterNeed: 'Medium',
      growthDays: 240,
      difficulty: 'Moderate',
      phMin: 6.0,
      phMax: 7.5,
      tempMin: 20,
      tempMax: 30,
      overview:
          'Subtropical evergreen citrus, productive in Mediterranean climates with mild winters.',
      growingConditions: [
        'Mild winters (no hard frost)',
        'Well-drained sandy loam',
        'Regular irrigation',
        'Annual pruning',
      ],
      nutrition: 'Very high vitamin C, folate',
      marketPrice: '\$1.10/kg average',
      marketDemand: 'High in winter months',
      bestRegions: ['Cap Bon', 'Nabeul'],
    ),
    CropInfo(
      name: 'Strawberry',
      emoji: '🍓',
      category: CropCategory.fruit,
      latin: 'Fragaria × ananassa',
      idealTemp: '15-22°C',
      waterNeed: 'Medium',
      growthDays: 90,
      difficulty: 'Easy',
      phMin: 5.5,
      phMax: 6.8,
      tempMin: 15,
      tempMax: 22,
      overview:
          'Low-growing perennial producing delicate fruit, suited to cool springs and well-drained beds.',
      growingConditions: [
        'Raised beds preferred',
        'Sandy loam, slightly acidic',
        'Mulch to retain moisture',
        'Replant every 3-4 years',
      ],
      nutrition: 'High vitamin C, manganese',
      marketPrice: '\$4.50/kg average',
      marketDemand: 'Peak in spring',
      bestRegions: ['Nabeul', 'Bizerte'],
    ),
    CropInfo(
      name: 'Watermelon',
      emoji: '🍉',
      category: CropCategory.fruit,
      latin: 'Citrullus lanatus',
      idealTemp: '22-32°C',
      waterNeed: 'High',
      growthDays: 90,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 22,
      tempMax: 32,
      overview:
          'Heat-loving vine producing large juicy fruits, requires long warm seasons and ample space.',
      growingConditions: [
        'Long warm season required',
        'Sandy loam, deep root zone',
        'Heavy mulch, deep watering',
        'Wide spacing (1.5m+)',
      ],
      nutrition: 'Hydrating, lycopene-rich',
      marketPrice: '\$0.80/kg average',
      marketDemand: 'Very high in summer',
      bestRegions: ['Sidi Bouzid', 'Kairouan'],
    ),
    CropInfo(
      name: 'Grape',
      emoji: '🍇',
      category: CropCategory.fruit,
      latin: 'Vitis vinifera',
      idealTemp: '15-30°C',
      waterNeed: 'Low',
      growthDays: 180,
      difficulty: 'Hard',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 15,
      tempMax: 30,
      overview:
          'Climbing perennial vine cultivated for table fruit and wine, drought-tolerant and Mediterranean-adapted.',
      growingConditions: [
        'Full sun, low humidity',
        'Well-drained, gravelly soils',
        'Trellis support required',
        'Annual dormant pruning',
      ],
      nutrition: 'Resveratrol, vitamin K',
      marketPrice: '\$2.40/kg average',
      marketDemand: 'Peak in late summer',
      bestRegions: ['Cap Bon', 'Mornag'],
    ),
    CropInfo(
      name: 'Pineapple',
      emoji: '🍍',
      category: CropCategory.fruit,
      latin: 'Ananas comosus',
      idealTemp: '24-30°C',
      waterNeed: 'Low',
      growthDays: 540,
      difficulty: 'Hard',
      phMin: 4.5,
      phMax: 6.5,
      tempMin: 24,
      tempMax: 30,
      overview:
          'Tropical bromeliad with rosette of stiff leaves, slow-maturing but drought-tolerant.',
      growingConditions: [
        'Warm tropical climate',
        'Acidic, sandy soil',
        'Drought-tolerant',
        'Frost-sensitive',
      ],
      nutrition: 'Bromelain enzyme, vitamin C',
      marketPrice: '\$2.80/kg average',
      marketDemand: 'Steady',
      bestRegions: ['Greenhouse only'],
    ),
  ];

  static const List<CropInfo> vegetables = [
    CropInfo(
      name: 'Tomato',
      emoji: '🍅',
      category: CropCategory.vegetable,
      latin: 'Solanum lycopersicum',
      idealTemp: '18-27°C',
      waterNeed: 'Medium',
      growthDays: 75,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 6.8,
      tempMin: 18,
      tempMax: 27,
      overview:
          'Warm-season annual fruit-vegetable, the backbone of Mediterranean cuisine and a heavy producer.',
      growingConditions: [
        'Full sun (8+ hours)',
        'Loamy soil with compost',
        'Stake or cage tall varieties',
        'Even moisture prevents splitting',
      ],
      nutrition: 'Lycopene, vitamin C, potassium',
      marketPrice: '\$1.40/kg average',
      marketDemand: 'Year-round demand',
      bestRegions: ['Sidi Bouzid', 'Kairouan', 'Sfax'],
    ),
    CropInfo(
      name: 'Carrot',
      emoji: '🥕',
      category: CropCategory.vegetable,
      latin: 'Daucus carota',
      idealTemp: '15-22°C',
      waterNeed: 'Medium',
      growthDays: 70,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 15,
      tempMax: 22,
      overview:
          'Cool-season root vegetable, develops deepest color in well-loosened sandy soils.',
      growingConditions: [
        'Loose, deep, stone-free soil',
        'Full sun to partial shade',
        'Thin seedlings to 5cm apart',
        'Avoid fresh manure',
      ],
      nutrition: 'Beta-carotene, vitamin K',
      marketPrice: '\$0.90/kg average',
      marketDemand: 'High year-round',
      bestRegions: ['Beja', 'Bizerte'],
    ),
    CropInfo(
      name: 'Potato',
      emoji: '🥔',
      category: CropCategory.vegetable,
      latin: 'Solanum tuberosum',
      idealTemp: '15-20°C',
      waterNeed: 'Medium',
      growthDays: 100,
      difficulty: 'Easy',
      phMin: 5.0,
      phMax: 6.5,
      tempMin: 15,
      tempMax: 20,
      overview:
          'Versatile starchy tuber, adaptable to many soils but yields best in loose, slightly acidic loam.',
      growingConditions: [
        'Loose, slightly acidic soil',
        'Hill soil over tubers',
        'Avoid waterlogging',
        'Rotate every 3 years',
      ],
      nutrition: 'Carbohydrates, potassium, B6',
      marketPrice: '\$0.70/kg average',
      marketDemand: 'Stable',
      bestRegions: ['Manouba', 'Beja'],
    ),
    CropInfo(
      name: 'Cabbage',
      emoji: '🥬',
      category: CropCategory.vegetable,
      latin: 'Brassica oleracea',
      idealTemp: '15-20°C',
      waterNeed: 'Medium',
      growthDays: 80,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 6.8,
      tempMin: 15,
      tempMax: 20,
      overview:
          'Cool-season leafy brassica, frost-tolerant and productive in fertile, slightly alkaline soils.',
      growingConditions: [
        'Cool weather preferred',
        'Rich, well-drained soil',
        'Heavy nitrogen feeder',
        'Watch for cabbage moths',
      ],
      nutrition: 'Vitamin K, C, fiber',
      marketPrice: '\$0.85/kg average',
      marketDemand: 'High in winter',
      bestRegions: ['Beja', 'Jendouba'],
    ),
    CropInfo(
      name: 'Onion',
      emoji: '🧅',
      category: CropCategory.vegetable,
      latin: 'Allium cepa',
      idealTemp: '13-25°C',
      waterNeed: 'Low',
      growthDays: 110,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 13,
      tempMax: 25,
      overview:
          'Day-length sensitive bulb crop, adapts to many climates with proper variety selection.',
      growingConditions: [
        'Full sun',
        'Loose, fertile soil',
        'Reduce water near maturity',
        'Match variety to day length',
      ],
      nutrition: 'Quercetin, vitamin C',
      marketPrice: '\$0.60/kg average',
      marketDemand: 'Constant',
      bestRegions: ['Sfax', 'Kairouan'],
    ),
    CropInfo(
      name: 'Spinach',
      emoji: '🥬',
      category: CropCategory.vegetable,
      latin: 'Spinacia oleracea',
      idealTemp: '10-20°C',
      waterNeed: 'Medium',
      growthDays: 45,
      difficulty: 'Easy',
      phMin: 6.5,
      phMax: 7.5,
      tempMin: 10,
      tempMax: 20,
      overview:
          'Fast-growing cool-season leafy green, ideal for autumn and early spring sowings.',
      growingConditions: [
        'Cool weather (bolts in heat)',
        'Rich, moist soil',
        'Succession plant every 2 weeks',
        'Partial shade in warm climates',
      ],
      nutrition: 'Iron, folate, vitamin K',
      marketPrice: '\$2.00/kg average',
      marketDemand: 'High in cool seasons',
      bestRegions: ['Bizerte', 'Beja'],
    ),
    CropInfo(
      name: 'Pepper',
      emoji: '🌶️',
      category: CropCategory.vegetable,
      latin: 'Capsicum annuum',
      idealTemp: '20-30°C',
      waterNeed: 'Medium',
      growthDays: 90,
      difficulty: 'Moderate',
      phMin: 6.0,
      phMax: 6.8,
      tempMin: 20,
      tempMax: 30,
      overview:
          'Warm-season fruiting vegetable, productive when warm nights and steady moisture are provided.',
      growingConditions: [
        'Warm nights (>15°C)',
        'Loamy, fertile soil',
        'Stake heavy-fruit varieties',
        'Calcium prevents blossom-end rot',
      ],
      nutrition: 'Vitamin C, capsaicin',
      marketPrice: '\$1.60/kg average',
      marketDemand: 'Steady',
      bestRegions: ['Sidi Bouzid', 'Sfax'],
    ),
    CropInfo(
      name: 'Cucumber',
      emoji: '🥒',
      category: CropCategory.vegetable,
      latin: 'Cucumis sativus',
      idealTemp: '20-28°C',
      waterNeed: 'High',
      growthDays: 60,
      difficulty: 'Easy',
      phMin: 6.0,
      phMax: 7.0,
      tempMin: 20,
      tempMax: 28,
      overview:
          'Fast vining cucurbit, prolific in warm weather with consistent moisture and trellis support.',
      growingConditions: [
        'Warm soil (>18°C)',
        'Rich, well-drained loam',
        'Trellis to save space',
        'Consistent watering',
      ],
      nutrition: 'Hydrating, vitamin K',
      marketPrice: '\$1.10/kg average',
      marketDemand: 'High in summer',
      bestRegions: ['Cap Bon', 'Sfax'],
    ),
  ];

  static List<CropInfo> all() => [...fruits, ...vegetables];

  static CropInfo? findByName(String name) {
    final lower = name.toLowerCase();
    for (final c in all()) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }
}
