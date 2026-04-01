import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../meals/domain/entities/product.dart';
import '../../../meals/domain/entities/cart_item.dart';
import '../pages/cart_page.dart';

/// Página de catálogo de productos
///
/// Muestra una lista de productos (platos) disponibles
/// para la comida seleccionada (Almuerzo, Desayuno, Cena)
class ProductsPage extends StatefulWidget {
  /// Tipo de comida seleccionada
  final String mealType;

  /// Número de mesa seleccionada
  final int tableNumber;

  const ProductsPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  /// Mapa para guardar la cantidad de cada producto
  /// Clave: product.id, Valor: cantidad
  final Map<String, int> _quantities = {};

  @override
  Widget build(BuildContext context) {
    // Generar productos de ejemplo para esta comida
    final products = _generateProducts();

    return Scaffold(
      // ════════════════════════════════════
      // APP BAR
      // ════════════════════════════════════
      appBar: AppBar(
        title: Text('${widget.mealType} - Mesa ${widget.tableNumber}'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToTables(widget.mealType),
        ),
      ),

      // ════════════════════════════════════
      // BODY
      // ════════════════════════════════════
      body: SafeArea(
        child: Stack(
          children: [
            // ════════════════════════════════════
            // LISTA DE PRODUCTOS
            // ════════════════════════════════════
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instrucción
                  Text(
                    'Selecciona tus platos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lista de productos
                  ...products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildProductCard(context, product),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Resumen del pedido
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen del pedido',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total de items seleccionados: ${_getTotalItems()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),

            // ════════════════════════════════════
            // BOTÓN FLOTANTE: VER CARRITO
            // ════════════════════════════════════
            if (_getTotalItems() > 0)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: ElevatedButton(
                  onPressed: () {
                    // Crear lista de CartItems
                    final cartItems = _createCartItems(_generateProducts());

                    // Navegar a CartPage
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CartPage(
                          mealType: widget.mealType,
                          tableNumber: widget.tableNumber,
                          cartItems: cartItems,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Carrito (${_getTotalItems()} items)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Widget para construir cada card de producto
  Widget _buildProductCard(BuildContext context, Product product) {
    // Obtener cantidad actual (por defecto 0)
    final quantity = _quantities[product.id] ?? 0;

    return Container(
      // ════════════════════════════════════
      // ESTILOS DEL CARD
      // ════════════════════════════════════
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      // ════════════════════════════════════
      // CONTENIDO DEL CARD
      // ════════════════════════════════════
      child: Row(
        children: [
          // ════════════════════════════════════
          // IMAGEN DEL PRODUCTO
          // ════════════════════════════════════
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('🍽️', style: const TextStyle(fontSize: 40)),
            ),
          ),

          const SizedBox(width: 16),

          // ════════════════════════════════════
          // INFORMACIÓN DEL PRODUCTO
          // ════════════════════════════════════
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Descripción
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // ════════════════════════════════════
                // CONTROLES DE CANTIDAD Y AGREGAR
                // ════════════════════════════════════
                Row(
                  children: [
                    // Botón MENOS
                    GestureDetector(
                      onTap: quantity > 0
                          ? () {
                              setState(() {
                                _quantities[product.id] = quantity - 1;
                              });
                            }
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: quantity > 0
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cantidad
                    Container(
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Botón AGREGAR (+ en círculo amarillo)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _quantities[product.id] = quantity + 1;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el total de items seleccionados
  int _getTotalItems() {
    return _quantities.values.fold(0, (sum, qty) => sum + qty);
  }

  /// Crea lista de CartItems a partir de productos y cantidades
  List<CartItem> _createCartItems(List<Product> products) {
    final cartItems = <CartItem>[];

    for (final product in products) {
      final quantity = _quantities[product.id] ?? 0;
      if (quantity > 0) {
        cartItems.add(CartItem(product: product, quantity: quantity));
      }
    }

    return cartItems;
  }

  /// Genera productos de ejemplo para esta comida
  List<Product> _generateProducts() {
    final products = <Product>[
      Product(
        id: 'prod_1',
        name: 'Colombia Tolima Coffee',
        price: 100.00,
        description: 'Café premium de la región Tolima',
        imageUrl: 'assets/images/coffee.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 'prod_2',
        name: 'Ensalada Fresca',
        price: 85.00,
        description: 'Ensalada con vegetales de temporada',
        imageUrl: 'assets/images/salad.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 'prod_3',
        name: 'Pechuga Grillada',
        price: 120.00,
        description: 'Pechuga de pollo a la parrilla',
        imageUrl: 'assets/images/chicken.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 'prod_4',
        name: 'Pasta Carbonara',
        price: 95.00,
        description: 'Pasta tradicional italiana',
        imageUrl: 'assets/images/pasta.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 'prod_5',
        name: 'Salmón a la Mantequilla',
        price: 150.00,
        description: 'Salmón fresco con salsa de mantequilla',
        imageUrl: 'assets/images/salmon.jpg',
        category: widget.mealType,
      ),
    ];

    return products;
  }
}
