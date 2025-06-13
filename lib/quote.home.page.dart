import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteHomePage extends StatefulWidget {
  const QuoteHomePage({super.key});

  @override
  State<QuoteHomePage> createState() => _QuoteHomePageState();
}

class _QuoteHomePageState extends State<QuoteHomePage> {
  late String _quote = 'Loading Quotes';
  late String _author = '';
  bool _isLoading = true;
  bool _isFetchingNew = false;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadingDailyQuote();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favorites = favList.toSet();
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final current = '$_quote - $_author';

    setState(() {
      if (_favorites.contains(current)) {
        _favorites.remove(current);
        Fluttertoast.showToast(msg: 'Remove from favorites');
      } else {
        _favorites.add(current);
        Fluttertoast.showToast(msg: 'Added to favorites');
      }
    });
    prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> _loadingDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;

    final savedDate = prefs.getString('quote_date');
    final savedQuote = prefs.getString('quote_text');
    final savedAuthor = prefs.getString('quote_author');

    if (savedDate == today && savedQuote != null && savedAuthor != null) {
      setState(() {
        _quote = savedQuote;
        _author = savedAuthor;
        _isLoading = false;
      });
    } else {
      await _fetchNewQuote();
    }
  }

  Future<void> _fetchNewQuote() async {
    setState(() {
      _isFetchingNew = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://yourapiurl'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          _quote = data['q'];
          _author = data['a'];
          _isLoading = false;
          _isFetchingNew = false;
        });

        final today = DateTime.now().toIso8601String().split('T').first;
        prefs.setString('quote_date', today);
        prefs.setString('quote_text', data['q']);
        prefs.setString('quote_author', data['a']);
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    setState(() {
      _quote = 'Could not fetch quote. Please check your connection.';
      _author = '';
      _isLoading = false;
      _isFetchingNew = false;
    });
  }

  void _copyQuote() {
    Clipboard.setData(
      ClipboardData(text: 'Daily Motivation\n\n$_quote - $_author'),
    );
    Fluttertoast.showToast(
      msg: 'Quote copied!',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _shareQuote() {
    Share.share('Daily Motivation\n\n$_quote - $_author');
  }

  bool _isFavorite() {
    return _favorites.contains('$_quote - $_author');
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.merriweather(
      textStyle: TextStyle(
        fontSize: 20,
        fontStyle: FontStyle.italic,
        color: Colors.white,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Motivation',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     onPressed: _toggleFavorite,
        //     icon: Icon(
        //       _isFavorite() ? Icons.favorite : Icons.favorite_border,
        //       color: Colors.redAccent,
        //     ),
        //   ),
        // ],
        backgroundColor: Color(0xFF121212),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: AnimatedContainer(
                    duration: Duration(microseconds: 500),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 40,
                          color: Colors.tealAccent,
                        ),
                        SizedBox(height: 20),
                        Text(
                          _quote,
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                        SizedBox(height: 10),
                        if (_author.isNotEmpty)
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              '- $_author',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                color: Colors.tealAccent,
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Wrap(
                            children: [
                              IconButton(
                                onPressed: _isFetchingNew ? null : _fetchNewQuote,
                                icon: _isFetchingNew
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.refresh,
                                        color: Colors.white70,
                                      ),
                              ),
                              IconButton(
                                onPressed: _copyQuote,
                                icon: Icon(Icons.copy, color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: _shareQuote,
                                icon: Icon(Icons.share, color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: _toggleFavorite,
                                icon: Icon(
                                  _isFavorite()
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //   children: [
                        //     ElevatedButton.icon(
                        //       onPressed: _copyQuote,
                        //       icon: Icon(Icons.copy, color: Colors.white),
                        //       label: Text(
                        //         'Copy',
                        //         style: GoogleFonts.lato(color: Colors.white),
                        //       ),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.teal,
                        //       ),
                        //     ),
                        //     ElevatedButton.icon(
                        //       onPressed: _shareQuote,
                        //       icon: Icon(Icons.share, color: Colors.white),
                        //       label: Text(
                        //         'Share',
                        //         style: GoogleFonts.lato(color: Colors.white),
                        //       ),
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.teal,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // SizedBox(height: 30),
                        // ElevatedButton(
                        //   onPressed: _isFetchingNew ? null : _fetchNewQuote,
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.teal[900],
                        //   ),
                        //   child: _isFetchingNew
                        //       ? SizedBox(
                        //           width: 20,
                        //           height: 20,
                        //           child: CircularProgressIndicator(
                        //             strokeWidth: 2,
                        //             valueColor: AlwaysStoppedAnimation<Color>(
                        //               Colors.white,
                        //             ),
                        //           ),
                        //         )
                        //       : Row(
                        //           mainAxisSize: MainAxisSize.min,
                        //           children: [
                        //             Icon(
                        //               Icons.refresh_outlined,
                        //               color: Colors.white,
                        //             ),
                        //             SizedBox(width: 8),
                        //             Text(
                        //               'New Quote',
                        //               style: GoogleFonts.lato(
                        //                 color: Colors.white,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
