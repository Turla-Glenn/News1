import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity/connectivity.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '25 News',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<dynamic> articles = [];
  bool isLoading = false;
  String errorMessage = '';

  List<String> categories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology'
  ];
  String selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    fetchNews();
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        showNoConnectionDialog();
      }
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showNoConnectionDialog();
    }
  }

  Future<void> showNoConnectionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Connection Found'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please check your internet connection and try again.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                checkConnectivity();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, you can close the app when the user chooses to close the dialog
                // SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchNews() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiKey = '6173ddd0c15d46aeaa6fe39785e6a0f1';
    final apiUrl =
        'https://newsapi.org/v2/top-headlines?country=us&category=$selectedCategory&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          articles = json.decode(response.body)['articles'];
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load news';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect to the server';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('25 News'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                'Categories',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            for (var category in categories)
              ListTile(
                title: Text(category[0].toUpperCase() + category.substring(1)),
                selected: category == selectedCategory,
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                  fetchNews();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return ArticleTile(
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            url: article['url'] ?? '',
          );
        },
      ),
    );
  }
}

class ArticleTile extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String url;

  ArticleTile({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchURL(url);
      },
      child: Card(
        margin: EdgeInsets.all(8.0),
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildImageWidget(),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                description.isNotEmpty ? description : 'No description available',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 200.0,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey,
            height: 200.0,
            child: Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
          color: Colors.grey,
          height: 200.0,
          child: Center(
          child: Text(

            'Image not available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          ),
      );
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}