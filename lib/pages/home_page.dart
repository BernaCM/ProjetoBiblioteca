import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/book_detail_page.dart';

class HomePage extends StatefulWidget {
  final token;
  final decodedToken;
  const HomePage({@required this.token, this.decodedToken, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List searchResults = []; // Lista que armazena os resultados da busca

  final genres = [
    'Fantasy',
    'Science Fiction',
    'Mystery',
    'Romance',
  ];

  void _navigateToDetailPage(book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          book: book,
          token: widget.token,
          decodedToken: widget.decodedToken,
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(
          5,
          (index) => Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber[400],
              size: 16))
        ..add(Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${rating.toStringAsFixed(1)}/5',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        )),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomePage'); // Adicionado para debug
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GenreSection(
                    genre: genres[index],
                    genreNumber: index + 1,
                    token: widget.token,
                    decodedToken: widget.decodedToken,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GenreSection extends StatefulWidget {
  final genre;
  final int genreNumber;
  final token;
  final decodedToken;
  const GenreSection({
    super.key,
    required this.genre,
    required this.genreNumber,
    required this.token,
    required this.decodedToken,
  });

  @override
  State<GenreSection> createState() => _GenreSectionState();
}

class _GenreSectionState extends State<GenreSection> {
  late Future<List> _booksFuture;

  Future<List> fetchBooksByGenre() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/books/v1/volumes?q=subject:${widget.genre}&maxResults=40'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final books = data['items'] ?? [];
        debugPrint('data: $data');
        debugPrint('Items: $books');
        return books;
      }
      return [];
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _booksFuture = fetchBooksByGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.genre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final books = snapshot.data ?? [];
              if (books.isEmpty) {
                return const Center(child: Text('No books found'));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: books
                      .map(
                        (books) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: BookCard(
                            book: books,
                            token: widget.token,
                            decodedToken: widget.decodedToken,
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BookCard extends StatelessWidget {
  final book;
  final token;
  final decodedToken;
  const BookCard({
    super.key,
    required this.token,
    required this.decodedToken,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final volumeInfo = book['volumeInfo'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
              book: book,
              token: token,
              decodedToken: decodedToken,
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  volumeInfo['imageLinks'] != null &&
                          volumeInfo['imageLinks']['thumbnail'].isNotEmpty
                      ? volumeInfo['imageLinks']['thumbnail']
                      : 'https://via.placeholder.com/100',
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 150,
                      child: const Icon(Icons.book, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      volumeInfo['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volumeInfo['authors']?.join(', ') ?? 'Autor desconhecido',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${volumeInfo['pageCount']} páginas',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRatingStars(volumeInfo['averageRating'] != null
                        ? volumeInfo['averageRating'].toDouble()
                        : 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(
          5,
          (index) => Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber[400],
              size: 16))
        ..add(Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${rating.toStringAsFixed(1)}/5',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        )),
    );
  }
}
