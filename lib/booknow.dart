import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details.dart';
import 'package:firebase_core/firebase_core.dart';
import 'profile.dart';
import 'paymentinfo.dart';

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

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.hasData) {
            // User is logged in
            return MyHomePage();
          } else {
            // User is not logged in
            return LoginPage();
          }
        }
      },
    );
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
            // Perform login
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
          // IconButton(
          //   icon: Icon(Icons.account_circle),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => ProfilePageWidget(),
          //       ),
          //     );
          //   },
          // ),
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
                  .where('status', isEqualTo: 1)
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
                      onTap: () async {
                        await _rentCar(car);
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
          title: Text('Filter Cars'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: minPriceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: maxPriceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  items: ['2022', '2023', '2024', '2025']
                      .map((year) => DropdownMenuItem(
                            child: Text(
                              year,
                              style: TextStyle(color: Colors.white),
                            ),
                            value: year,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value;
                    });
                  },
                  value: selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  items: ['Compact', 'SUV', 'Truck', 'Sedan']
                      .map((carClass) => DropdownMenuItem(
                            child: Text(
                              carClass,
                              style: TextStyle(color: Colors.white),
                            ),
                            value: carClass,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCarClass = value;
                    });
                  },
                  value: selectedCarClass,
                  decoration: InputDecoration(
                    labelText: 'Car Class',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  items: ['Automatic', 'Manual']
                      .map((transmission) => DropdownMenuItem(
                            child: Text(
                              transmission,
                              style: TextStyle(color: Colors.white),
                            ),
                            value: transmission,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTransmission = value;
                    });
                  },
                  value: selectedTransmission,
                  decoration: InputDecoration(
                    labelText: 'Transmission',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rentCar(DocumentSnapshot car) async {
    final carId = car.id;
    final data = car.data() as Map<String, dynamic>;

    // Set car status to rented (0)
    await FirebaseFirestore.instance
        .collection('cars')
        .doc(carId)
        .update({'status': '0'});

    // Navigate to rent page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentCarPage(
          brand: data['brand'] ?? 'Unknown Brand',
          year: data['year'] ?? 'Unknown Year',
          basePrice: data['price']?.toDouble() ?? 0.0,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          imageUrl: data['imageUrl'] ?? '',
        ),
      ),
    );
  }
}

class CarCard extends StatelessWidget {
  final String brand;
  final String year;
  final String carClass;
  final double price;
  final String imageUrl;

  const CarCard({
    Key? key,
    required this.brand,
    required this.year,
    required this.carClass,
    required this.price,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 100,
                fit: BoxFit.cover,
              )
            : Container(
                width: 100,
                color: Colors.grey,
                child: Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.white,
                ),
              ),
        title: Text(
          '$brand - $year',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '$carClass\nPrice: \$${price.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text('Rent Now'),
        ),
      ),
    );
  }
}

class RentCarPage extends StatefulWidget {
  final String brand;
  final String year;
  final double basePrice;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;

  const RentCarPage({
    Key? key,
    required this.brand,
    required this.year,
    required this.basePrice,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _RentCarPageState createState() => _RentCarPageState();
}

class _RentCarPageState extends State<RentCarPage> {
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  double _taxRate = 0.15; // Tax rate of 15%
  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    _totalPrice = widget.basePrice * numberOfDays + totalTaxes;
  }

  int get numberOfDays =>
      _selectedEndDate.difference(_selectedStartDate).inDays;

  double get totalTaxes => widget.basePrice * numberOfDays * _taxRate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Rent Now',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '[${widget.brand}]',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            Text(
              '[${widget.year}]',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose date',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(width: 0),
                      Text(
                        'Start: ${DateFormat('yyyy-MM-dd').format(_selectedStartDate)}',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          _selectStartDate(context);
                        },
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'End: ${DateFormat('yyyy-MM-dd').format(_selectedEndDate)}',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          _selectEndDate(context);
                        },
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Information',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: 'Card number',
                      hintStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black,
                            hintText: 'Exp. Date',
                            hintStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black,
                            hintText: 'CVV',
                            hintStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Base Price',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      Text(
                        '\$${widget.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Taxes',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      Text(
                        '\$${totalTaxes.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: Colors.grey, fontSize: 22),
                      ),
                      Text(
                        '\$${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  _rentNow();
                },
                child: Text(
                  'Rent Now',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rentNow() async {
// If payment is successful, update the car status to '0'
    await FirebaseFirestore.instance
        .collection('cars')
        .where('brand', isEqualTo: widget.brand)
        .where('year', isEqualTo: widget.year)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        await doc.reference.update({'status': '0'});
      });
    });

    // Navigate to PaymentInfoWidget
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentInfoWidget(
          brand: widget.brand,
          year: widget.year,
          totalPrice: _totalPrice,
          startDate: _selectedStartDate,
          endDate: _selectedEndDate,
        ),
      ),
    );
  }


  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _totalPrice = widget.basePrice * numberOfDays + totalTaxes;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
        _totalPrice = widget.basePrice * numberOfDays + totalTaxes;
      });
    }
  }
}
