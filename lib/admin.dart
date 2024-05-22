import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          bottom: TabBar(
            tabs: [
              Tab(text: "Insert"),
              Tab(text: "View"),
              Tab(text: "Search"),
              Tab(text: "Update"),
              Tab(text: "Delete"),
            ],
          ),
          title: Center(
            child: Text(
              'Administrator',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            InsertScreen(),
            ViewScreen(),
            SearchScreen(),
            UpdateScreen(),
            DeleteScreen(),
          ],
        ),
      ),
    );
  }
}

class InsertScreen extends StatefulWidget {
  @override
  _InsertScreenState createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController milesController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  TextEditingController classController = TextEditingController();
  TextEditingController transmissionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String imageUrl = '';

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('car_images/$fileName');
      await firebaseStorageRef.putFile(File(pickedFile.path));
      String downloadURL = await firebaseStorageRef.getDownloadURL();

      print('Download URL: $downloadURL');
      setState(() {
        imageUrl = downloadURL;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: brandController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Brand',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: yearController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Year',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: classController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Class',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: transmissionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Transmission',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: priceController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Price',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Upload Image',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _uploadImage,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Add Car',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                String brand = brandController.text;
                String year = yearController.text;
                String carClass = classController.text;
                String transmission = transmissionController.text;

                double price;
                try {
                  price = double.parse(priceController.text);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }

                if (imageUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please upload an image')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('cars').add({
                    'brand': brand,
                    'year': year,
                    'class': carClass,
                    'transmission': transmission,
                    'price': price,
                    'imageUrl': imageUrl,
                    'description': descriptionController.text,
                    'status': '1',
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Car added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add car: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('cars').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final carDocs = snapshot.data?.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: carDocs?.length,
          itemBuilder: (BuildContext context, int index) {
            return CarCard(
              brand: carDocs?[index]['brand'],
              year: carDocs?[index]['year'],
              carClass: carDocs?[index]['class'],
              price: carDocs?[index]['price'],
              description: carDocs?[index]['description'],
              imageUrl: carDocs?[index]['imageUrl'],
            );
          },
        );
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController brandController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: brandController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Brand',
                labelStyle: TextStyle(color: Colors.white),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild when search text changes
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('cars').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final carDocs = snapshot.data?.docs;
                List<DocumentSnapshot> filteredCars = [];

                // Perform partial search based on brand
                if (brandController.text.isNotEmpty) {
                  for (var car in carDocs!) {
                    String brand = car['brand'].toString().toLowerCase();
                    String searchText = brandController.text.toLowerCase();
                    if (brand.contains(searchText)) {
                      filteredCars.add(car);
                    }
                  }
                } else {
                  filteredCars.addAll(carDocs!);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredCars.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        // Implement navigation to update page for the selected car
                      },
                      child: CarCard(
                        brand: filteredCars[index]['brand'],
                        year: filteredCars[index]['year'],
                        carClass: filteredCars[index]['class'],
                        price: filteredCars[index]['price'],
                        description: filteredCars[index]['description'],
                        imageUrl: filteredCars[index]['imageUrl'],
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
}

class UpdateScreen extends StatefulWidget {
  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search',
              labelStyle: TextStyle(color: Colors.white),
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild when search text changes
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('cars').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final carDocs = snapshot.data?.docs;
              List<DocumentSnapshot> filteredCars = [];

              // Perform partial search based on brand
              if (searchController.text.isNotEmpty) {
                for (var car in carDocs!) {
                  String brand = car['brand'].toString().toLowerCase();
                  String searchText = searchController.text.toLowerCase();
                  if (brand.contains(searchText)) {
                    filteredCars.add(car);
                  }
                }
              } else {
                filteredCars.addAll(carDocs!);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredCars.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UpdateCarPage(carSnapshot: filteredCars[index]),
                        ),
                      );
                    },
                    child: CarCard(
                      brand: filteredCars[index]['brand'],
                      year: filteredCars[index]['year'],
                      carClass: filteredCars[index]['class'],
                      price: filteredCars[index]['price'],
                      description: filteredCars[index]['description'],
                      imageUrl: filteredCars[index]['imageUrl'],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DeleteScreen extends StatefulWidget {
  @override
  _DeleteScreenState createState() => _DeleteScreenState();
}

class _DeleteScreenState extends State<DeleteScreen> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search',
              labelStyle: TextStyle(color: Colors.white),
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild when search text changes
            },
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('cars').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final carDocs = snapshot.data?.docs;
              List<DocumentSnapshot> filteredCars = [];

              // Perform partial search based on brand
              if (searchController.text.isNotEmpty) {
                for (var car in carDocs!) {
                  String brand = car['brand'].toString().toLowerCase();
                  String searchText = searchController.text.toLowerCase();
                  if (brand.contains(searchText)) {
                    filteredCars.add(car);
                  }
                }
              } else {
                filteredCars.addAll(carDocs!);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredCars.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      _showDeleteConfirmationDialog(
                          context, filteredCars[index]);
                    },
                    child: CarCard(
                      brand: filteredCars[index]['brand'],
                      year: filteredCars[index]['year'],
                      carClass: filteredCars[index]['class'],
                      price: filteredCars[index]['price'],
                      description: filteredCars[index]['description'],
                      imageUrl: filteredCars[index]['imageUrl'],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentSnapshot carSnapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this car?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteCar(carSnapshot);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCar(DocumentSnapshot carSnapshot) async {
    try {
      await carSnapshot.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete car: $e')),
      );
    }
  }
}

class UpdateCarPage extends StatefulWidget {
  final DocumentSnapshot carSnapshot;

  const UpdateCarPage({Key? key, required this.carSnapshot}) : super(key: key);

  @override
  _UpdateCarPageState createState() => _UpdateCarPageState();
}

class _UpdateCarPageState extends State<UpdateCarPage> {
  late TextEditingController brandController;
  late TextEditingController yearController;
  late TextEditingController classController;
  late TextEditingController transmissionController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController(text: widget.carSnapshot['brand']);
    yearController = TextEditingController(text: widget.carSnapshot['year']);
    classController = TextEditingController(text: widget.carSnapshot['class']);
    transmissionController =
        TextEditingController(text: widget.carSnapshot['transmission']);
    priceController =
        TextEditingController(text: widget.carSnapshot['price'].toString());
    descriptionController =
        TextEditingController(text: widget.carSnapshot['description']);
    imageUrl = widget.carSnapshot['imageUrl'];
  }

  Future<void> _updateCar(BuildContext context) async {
    try {
      await widget.carSnapshot.reference.update({
        'brand': brandController.text,
        'year': yearController.text,
        'class': classController.text,
        'transmission': transmissionController.text,
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car updated successfully')),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update car: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('car_images/$fileName');
      await firebaseStorageRef.putFile(File(pickedFile.path));
      String downloadURL = await firebaseStorageRef.getDownloadURL();

      print('Download URL: $downloadURL');
      setState(() {
        imageUrl = downloadURL;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Car')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: brandController,
                decoration: InputDecoration(labelText: 'Brand'),
              ),
              TextField(
                controller: yearController,
                decoration: InputDecoration(labelText: 'Year'),
              ),
              TextField(
                controller: classController,
                decoration: InputDecoration(labelText: 'Class'),
              ),
              TextField(
                controller: transmissionController,
                decoration: InputDecoration(labelText: 'Transmission'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl)
                  : SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('No Image Selected'),
                      ),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _updateCar(context);
                },
                child: Text('Update Car'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarCard extends StatelessWidget {
  final String? brand;
  final String? year;
  final String? carClass;
  final double? price;
  final String? description;
  final String? imageUrl;

  CarCard(
      {this.brand,
      this.year,
      this.carClass,
      this.price,
      this.description,
      this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Image.asset(
                      'assets/images/car_placeholder.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(year ?? ''),
                SizedBox(height: 4),
                Text(carClass ?? ''),
                SizedBox(height: 4),
                Text('\$${price?.toStringAsFixed(2)}' ?? ''),
                SizedBox(height: 4),
                Text(description ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
