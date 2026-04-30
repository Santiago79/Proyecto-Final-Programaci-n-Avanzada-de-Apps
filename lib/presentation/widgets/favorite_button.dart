import 'package:flutter/material.dart';
import 'package:proyecto_final/services/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String breed;
  final String imageUrl;
  final Map<String, dynamic> breedInfo;

  const FavoriteButton({
    super.key,
    required this.breed,
    required this.imageUrl,
    required this.breedInfo,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesService _favoritesService = FavoritesService();
  late Future<bool> _isFavoriteFuture;

  @override
  void initState() {
    super.initState();
    _refreshFavoriteStatus();
  }

  void _refreshFavoriteStatus() {
    _isFavoriteFuture = _favoritesService.isFavorite(widget.breed);
  }

  Future<void> _toggleFavorite() async {
    final isFav = await _favoritesService.isFavorite(widget.breed);
    
    if (isFav) {
      await _favoritesService.removeFavorite(widget.breed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.breed} eliminado de favoritos')),
      );
    } else {
      
      await _favoritesService.addFavorite(
        breed: widget.breed,
        imageUrl: widget.imageUrl,
        breedInfo: widget.breedInfo,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.breed} agregado a favoritos')),
      );
    }
    
    _refreshFavoriteStatus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFavoriteFuture,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
            size: 28,
          ),
          onPressed: _toggleFavorite,
          tooltip: isFavorite ? 'Eliminar de favoritos' : 'Agregar a favoritos',
        );
      },
    );
  }
}