final List<Map<String, dynamic>> mockUsers = [
  {
    'id': 1,
    'email': 'headvet@example.com',
    'password': '1234',
    'role': 'HeadVet',
    'name': 'Dr. Jane Doe',
  },
  {
    'id': 2,
    'email': 'assistvet@example.com',
    'password': '1234',
    'role': 'AssistantVet',
    'name': 'Dr. John Smith',
  },
  {
    'id': 3,
    'email': 'caretaker_c@example.com',
    'password': '1234',
    'role': 'CaretakerC',
    'name': 'Bert',
  },
  {
    'id': 4,
    'email': 'caretaker_b@example.com',
    'password': '1234',
    'role': 'CaretakerB',
    'name': 'victoy',
  },
  {
    'id': 5,
    'email': 'caretaker_a@example.com',
    'password': '1234',
    'role': 'CaretakerA',
    'name': 'Crisma',
  },
  {
    'id': 6,
    'email': 'caretaker_a1@example.com',
    'password': '1234',
    'role': 'CaretakerA',
    'name': 'Bert2',
  },
];

final List<Map<String, dynamic>> animals = [
  // Avian: African Lovebird
  {
    'id': 1,
    'name': 'African Lovebird',
    'category': 'Avian',
    'count': 6,
    'status': 'Mixed',
    'isUrgent': true,
    'lastCheckup': '2023-11-10',
    'image':
        'https://lafeber.com/pet-birds/wp-content/uploads/2018/06/Lovebird.jpg',
    'remarks': [
      {
        'user': 1,
        'remark': 'Ensure daily feeding.',
        'date': '2024-11-23',
        'time': '10:30 AM',
      },
      {
        'user': 3,
        'remark': 'Monitor injured birds closely.',
        'date': '2024-11-24',
        'time': '2:15 PM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://www.lovebirbs.com/wp-content/uploads/2020/09/apache-trying-apple.jpg',
        'likes': 120,
        'comments': [
          {'user': 1, 'text': 'Beautiful moment!'},
          {'user': 3, 'text': 'Such a lovely photo.'},
        ],
        'caption': 'Fed the birds in the morning.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 5, 'Injured': 1, 'Isolated': 0, 'Died': 0},
    },
  },
  // Avian: Scarlet Macaw
  {
    'id': 3,
    'name': 'Scarlet Macaw',
    'category': 'Avian',
    'count': 3,
    'status': 'Healthy',
    'isUrgent': false,
    'lastCheckup': '2023-11-15',
    'image':
        'https://lafeber.com/pet-birds/wp-content/uploads/2018/06/Scarlet-Macaw-2.jpg',
    'remarks': [
      {
        'user': 1,
        'remark': 'Ensure enough space in the aviary.',
        'date': '2024-11-20',
        'time': '3:00 PM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://img.freepik.com/free-photo/beautiful-bright-colored-scarlet-macaw-tree-perch_493961-1287.jpg',
        'likes': 85,
        'comments': [
          {'user': 2, 'text': 'Gorgeous plumage!'},
          {'user': 3, 'text': 'Bright and vibrant!'},
        ],
        'caption': 'Macaws enjoying their morning perch.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 3, 'Injured': 0, 'Isolated': 0, 'Died': 0},
    },
  },
  // Mammal: Cassowary
  {
    'id': 2,
    'name': 'Cassowary',
    'category': 'Mammal',
    'count': 2,
    'status': 'Healthy',
    'isUrgent': false,
    'lastCheckup': '2023-10-20',
    'image':
        'https://cdn.i-scmp.com/sites/default/files/styles/1200x800/public/d8/images/canvas/2024/06/05/f048e7d5-80b0-4ff9-8bd3-ab226aa5e244_e31a5471.jpg?itok=1gZJ_Xap&v=1717581405',
    'remarks': [
      {
        'user': 2,
        'remark': 'Schedule monthly health checkups.',
        'date': '2024-11-25',
        'time': '9:00 AM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://alouattasen.weebly.com/uploads/8/9/5/6/8956452/4463276_orig.jpg',
        'likes': 75,
        'comments': [
          {'user': 2, 'text': 'Amazing work!'},
          {'user': 3, 'text': 'What a view!'},
        ],
        'caption': 'Cassowary enclosure after cleanup.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 2, 'Injured': 0, 'Isolated': 0, 'Died': 0},
    },
  },
  // Mammal: Bengal Tiger
  {
    'id': 4,
    'name': 'Bengal Tiger',
    'category': 'Mammal',
    'count': 1,
    'status': 'Mixed',
    'isUrgent': true,
    'lastCheckup': '2023-11-05',
    'image':
        'https://bigcatsindia.com/wp-content/uploads/2018/06/Royal-Bengal-Tiger.jpg',
    'remarks': [
      {
        'user': 3,
        'remark': 'Monitor behavior closely due to reduced activity.',
        'date': '2024-11-22',
        'time': '4:00 PM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://media.licdn.com/dms/image/v2/C4E12AQEIIKPTmUj3OQ/article-cover_image-shrink_423_752/article-cover_image-shrink_423_752/0/1643617368570?e=1738195200&v=beta&t=gVh5hUSKoK6W2G9JSanZ5-6NBxVdtd5ko3S06VZDrak',
        'likes': 140,
        'comments': [
          {'user': 1, 'text': 'A majestic animal!'},
          {'user': 2, 'text': 'Such an adorable tiger cub.'},
        ],
        'caption': 'Tigers after a successful meal.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 0, 'Injured': 1, 'Isolated': 0, 'Died': 0},
    },
  },
  // Reptile: Komodo Dragon
  {
    'id': 5,
    'name': 'Komodo Dragon',
    'category': 'Reptile',
    'count': 2,
    'status': 'Healthy',
    'isUrgent': false,
    'lastCheckup': '2023-09-15',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Komodo_dragon_%28Varanus_komodoensis%29.jpg/330px-Komodo_dragon_%28Varanus_komodoensis%29.jpg',
    'remarks': [
      {
        'user': 1,
        'remark': 'Provide extra heating during cooler months.',
        'date': '2024-11-18',
        'time': '11:00 AM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://nerdnomads.com/wp-content/uploads/DSC1442-705x468.jpg',
        'likes': 90,
        'comments': [
          {'user': 2, 'text': 'Such an incredible creature!'},
          {'user': 3, 'text': 'The scales look amazing.'},
        ],
        'caption': 'Enjoying a bask in the sun.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 2, 'Injured': 0, 'Isolated': 0, 'Died': 0},
    },
  },
  // Reptile: Green Iguana
  {
    'id': 6,
    'name': 'Green Iguana',
    'category': 'Reptile',
    'count': 4,
    'status': 'Mixed',
    'isUrgent': false,
    'lastCheckup': '2023-11-01',
    'image':
        'https://www.petplace.com/article/reptiles/general/media_1737bada0845e8f1e454d68e52639ccacddd6dd83.jpeg?width=2000&format=webply&optimize=medium',
    'remarks': [
      {
        'user': 2,
        'remark': 'Increase foliage in the enclosure.',
        'date': '2024-11-19',
        'time': '2:00 PM',
      },
    ],
    'gallery': [
      {
        'image':
            'https://images.pexels.com/photos/5727067/pexels-photo-5727067.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
        'likes': 65,
        'comments': [
          {'user': 1, 'text': 'This iguana looks stunning!'},
        ],
        'caption': 'Green iguanas feeding on leafy greens.',
      },
    ],
    'statistics': {
      'Day': {'Healthy': 3, 'Injured': 1, 'Isolated': 0, 'Died': 0},
    },
  },
];

final List<Map<String, dynamic>> mockAppointments = [
  {
    'id': 'apt_001',
    'title': 'Health Checkup',
    'time': '10:00 AM',
    'date': '2024-11-26',
    'assignedPerson': 2, // User ID for 'Dr. Jane Doe'
    'status': 'pending',
    'animals': [1, 2], // Animal IDs for 'African Lovebird' and 'Cassowary'
  },
  {
    'id': 'apt_002',
    'title': 'Vaccination',
    'time': '11:00 AM',
    'date': '2024-11-25',
    'assignedPerson': 2, // User ID for 'Dr. John Smith'
    'status': 'approved',
    'animals': [1], // Animal ID for 'Python'
  },
];

final List<Map<String, dynamic>> mockRequests = [
  {
    'id': 'req_1',
    'animals': [
      {
        'id': 1, // Links to 'African Lovebird' in the animals list
        'name': 'African Lovebird',
        'caretaker': 5, // User ID for 'Bert'
      },
    ],
    'requestDate': '2024-11-24',
    'requestTime': '14:00',
  },
  {
    'id': 'req_2',
    'animals': [
      {
        'id': 4,
        'name': 'Bengal Tiger',
        'caretaker': 4, // User ID for 'Caretaker B'
      },
    ],
    'requestDate': '2024-11-24',
    'requestTime': '09:30',
  },
];

List<Map<String, dynamic>> mockInventory = [
  {
    "itemNo": 1,
    "prQty": 4,
    "unit": "Bot",
    "description": "Amoxicillin Trihydrate + Tylosin + Paracetamol 1kg",
    "brand": 'Keith',
    "lbNo": "ATBPV-033",
    "mfgDate": "2024-04-24",
    "exp": "2024-04-26",
    "actualQty": 4,
    "animalAssigned": [1, 4] // African Lovebird, Bengal Tiger
  },
  {
    "itemNo": 2,
    "prQty": 2,
    "unit": "Pc",
    "description": "Adson Tissue Forceps",
    "brand": null,
    "lbNo": null,
    "mfgDate": null,
    "exp": null,
    "actualQty": 2,
    "animalAssigned": [3] // Scarlet Macaw
  },
  {
    "itemNo": 3,
    "prQty": 2,
    "unit": "Pc",
    "description": "Double Tip Hook / Skin Retractor",
    "brand": null,
    "lbNo": "E62159",
    "mfgDate": "2022-11-22",
    "exp": "2025-10-25",
    "actualQty": 2,
    "animalAssigned": [2] // Cassowary
  },
  {
    "itemNo": 4,
    "prQty": 12,
    "unit": "Bot",
    "description": "Fipronil Spray 100ml",
    "brand": null,
    "lbNo": null,
    "mfgDate": null,
    "exp": null,
    "actualQty": 11,
    "animalAssigned": [1, 6] // African Lovebird, Green Iguana
  },
  {
    "itemNo": 5,
    "prQty": 1,
    "unit": "Pc",
    "description": "First Aide Tackle Box",
    "brand": null,
    "lbNo": null,
    "mfgDate": null,
    "exp": null,
    "actualQty": 1,
    "animalAssigned": [4, 5] // Bengal Tiger, Komodo Dragon
  },
];

final List<Map<String, dynamic>> mockDailyTasks = [
  // Task for Avian: African Lovebird
  {
    'id': 1,
    'task': 'Clean Aviary',
    'status': 'In Progress',
    'priority': 'Medium',
    'assignedTo': 'caretaker_a1@example.com',
    'expectedCompletion': '12:00 PM',
    'details': 'Clean the aviary and refill bird feeders.',
    'animals': ['African Lovebird'],
  },
  // Task for Avian: Administer Medication to Birds
  {
    'id': 2,
    'task': 'Administer Medication to Birds',
    'status': 'Pending',
    'priority': 'High',
    'assignedTo': 'caretaker_a1@example.com',
    'expectedCompletion': '11:00 AM',
    'details': 'Provide antibiotics to the injured African Lovebirds.',
    'animals': ['African Lovebird'],
  },
  // Task for Mammal: Feed the Mammals
  {
    'id': 3,
    'task': 'Feed the Mammals',
    'status': 'Pending',
    'priority': 'High',
    'assignedTo': 'caretaker_b@example.com',
    'expectedCompletion': '10:00 AM',
    'details': 'Provide food to all mammals, including tigers and cassowaries.',
    'animals': ['Bengal Tiger'],
  },
  // Task for Mammal: Check Bengal Tiger Enclosure
  {
    'id': 4,
    'task': 'Check Bengal Tiger Enclosure',
    'status': 'In Progress',
    'priority': 'High',
    'assignedTo': 'caretaker_b@example.com',
    'expectedCompletion': '4:00 PM',
    'details': 'Inspect the Bengal Tiger enclosure for safety concerns.',
    'animals': ['Bengal Tiger'],
  },
  // Task for Reptile: Check and Repair Heating Lamps
  {
    'id': 5,
    'task': 'Check and Repair Heating Lamps',
    'status': 'Pending',
    'priority': 'Medium',
    'assignedTo': 'caretaker_c@example.com',
    'expectedCompletion': '3:00 PM',
    'details': 'Ensure heating lamps are functional for reptiles.',
    'animals': ['Komodo Dragon'],
  },
  // Task for Reptile: Clean and Sanitize Enclosure
  {
    'id': 6,
    'task': 'Clean and Sanitize Reptile Enclosure',
    'status': 'Pending',
    'priority': 'Low',
    'assignedTo': 'caretaker_c@example.com',
    'expectedCompletion': '2:00 PM',
    'details': 'Clean the enclosures for Komodo Dragons and Iguanas.',
    'animals': ['Komodo Dragon'],
  },
  // General: Avian Health Monitoring
  {
    'id': 7,
    'task': 'Avian Health Monitoring',
    'status': 'Pending',
    'priority': 'High',
    'assignedTo': 'caretaker_a@example.com',
    'expectedCompletion': '9:30 AM',
    'details': 'Perform a health check for all aviary birds.',
    'animals': ['Scarlet Macaw'],
  },
];
