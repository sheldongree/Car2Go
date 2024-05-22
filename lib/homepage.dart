import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details.dart';
import 'package:firebase_core/firebase_core.dart';
import 'profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car2Go',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  String? _loggedInUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.hasData) {
            return FutureBuilder(
              future: _getLoggedInUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else {
                  return MyHomePage(userId: _loggedInUserId!);
                }
              },
            );
          } else {
            return LoginPage();
          }
        }
      },
    );
  }

  Future<void> _getLoggedInUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final userId = snapshot.docs.first.id;
        setState(() {
          _loggedInUserId = userId;
        });
      }
    }
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signInAnonymously();
            } catch (e) {
              print('Error signing in: $e');
            }
          },
          child: Text('Login Anonymously'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String userId;

  const MyHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();

  String? selectedYear;
  String? selectedCarClass;
  String? selectedTransmission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Car2Go',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfilePageWidget(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome!',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Explore the World Behind the Wheel',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Icon(Icons.search, color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Icon(Icons.filter_alt, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .where('status', isEqualTo: '1')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final carDocs = snapshot.data?.docs;
                List<DocumentSnapshot> filteredCars = [];

                if (carDocs != null) {
                  filteredCars = carDocs.where((car) {
                    final data = car.data() as Map<String, dynamic>;
                    final carBrand = data['brand'] ?? '';
                    final carPrice = data['price']?.toDouble() ?? 0.0;

                    bool matchesSearch = carBrand
                        .toLowerCase()
                        .contains(searchController.text.toLowerCase());

                    bool matchesPrice = true;
                    if (minPriceController.text.isNotEmpty &&
                        maxPriceController.text.isNotEmpty) {
                      final minPrice =
                          double.tryParse(minPriceController.text) ?? 0.0;
                      final maxPrice =
                          double.tryParse(maxPriceController.text) ??
                              double.infinity;
                      matchesPrice =
                          carPrice >= minPrice && carPrice <= maxPrice;
                    }

                    bool matchesFilters = true;
                    if (selectedYear != null) {
                      matchesFilters &=
                          data['year'] == selectedYear; // No need for int.parse
                    }
                    if (selectedCarClass != null) {
                      matchesFilters &= data['class'] == selectedCarClass;
                    }
                    if (selectedTransmission != null) {
                      matchesFilters &=
                          data['transmission'] == selectedTransmission;
                    }

                    return matchesSearch && matchesPrice && matchesFilters;
                  }).toList();
                }

                return ListView.builder(
                  itemCount: filteredCars.length,
                  itemBuilder: (context, index) {
                    final car = filteredCars[index];
                    final data = car.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailsWidget(
                              carId: car.id,
                            ),
                          ),
                        );
                      },
                      child: CarCard(
                        brand: data['brand'] ?? 'Unknown Brand',
                        year: data['year'] ?? 'Unknown Year',
                        // Year treated as string
                        carClass: data['class'] ?? 'Unknown Class',
                        price: data['price']?.toDouble() ?? 0.0,
                        imageUrl: data['imageUrl'] ?? '',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filters'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text('Year'),
                DropdownButton<String>(
                  value: selectedYear,
                  hint: Text('Select Year'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedYear = newValue;
                    });
                  },
                  items: <String>['2020', '2021', '2022', '2023']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text('Class'),
                DropdownButton<String>(
                  value: selectedCarClass,
                  hint: Text('Select Class'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCarClass = newValue;
                    });
                  },
                  items: <String>['Economy', 'Luxury', 'SUV']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text('Transmission'),
                DropdownButton<String>(
                  value: selectedTransmission,
                  hint: Text('Select Transmission'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTransmission = newValue;
                    });
                  },
                  items: <String>['Automatic', 'Manual']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text('Price Range'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Min Price'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Max Price'),
                      ),
                    ),
                  ],
                ),
                // Clear Button to clear all filters
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedYear = null;
                      selectedCarClass = null;
                      selectedTransmission = null;
                      minPriceController.clear();
                      maxPriceController.clear();
                    });
                  },
                  child: Text('Clear Filters'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class CarCard extends StatelessWidget {
  final String brand;
  final String year;
  final String carClass; // Added class field
  final double price;
  final String imageUrl;

  const CarCard({
    required this.brand,
    required this.year,
    required this.carClass,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  '$year',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  carClass, // Display class here
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '\$$price per day',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}