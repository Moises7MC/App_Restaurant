import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../meals/domain/entities/product.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../pages/cart_page.dart';

class ProductsPage extends StatefulWidget {
  final String mealType;
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
  @override
  void initState() {
    super.initState();

    // Cuando se abre ProductsPage, le decimos al CartBloc
    // que cargue el carrito de esta mesa
    context.read<CartBloc>().add(
      SelectTable(mealType: widget.mealType, tableNumber: widget.tableNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _generateProducts();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mealType} - Mesa ${widget.tableNumber}'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToTables(widget.mealType),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selecciona tus platos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildProductCard(context, product),
                    );
                  }),
                  const SizedBox(height: 24),
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      int totalItems = 0;
                      if (state is CartLoaded) {
                        totalItems = state.totalItems;
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
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
                              'Total de items seleccionados: $totalItems',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoaded && state.totalItems > 0) {
                  return Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CartPage(
                              mealType: widget.mealType,
                              tableNumber: widget.tableNumber,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart),
                          const SizedBox(width: 8),
                          Text(
                            'Ver Carrito (${state.totalItems} items)',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        int quantity = 0;
        if (state is CartLoaded) {
          final item = state.items
              .where((item) => item.product.id == product.id)
              .firstOrNull;
          if (item != null) {
            quantity = item.quantity;
          }
        }

        return Container(
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
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(product.imageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error cargando imagen: ${product.imageUrl}');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'S/.${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: quantity > 0
                              ? () {
                                  context.read<CartBloc>().add(
                                    RemoveFromCart(product.id),
                                  );
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
                        GestureDetector(
                          onTap: () {
                            context.read<CartBloc>().add(AddToCart(product));
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
      },
    );
  }

  List<Product> _generateProducts() {
    final products = <Product>[
      Product(
        id: 1,
        name: 'Pollo a la parrilla',
        price: 13,
        description: 'Sale con papas fritas o papas sanchadas',
        imageUrl: 'assets/images/pollo_parrilla.jpg', // ← COMPLETO
        category: widget.mealType,
      ),
      Product(
        id: 2,
        name: 'Cabrito',
        price: 15,
        description: 'Con frejol o mentestra',
        imageUrl: 'assets/images/cabrito.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 3,
        name: 'Pescado frito',
        price: 10,
        description: 'Pescado furel',
        imageUrl: 'assets/images/pescado frito.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 4,
        name: 'Ceviche mixto',
        price: 15,
        description: 'doble o trio marino',
        imageUrl: 'assets/images/ceviche mixto.jpg',
        category: widget.mealType,
      ),
      Product(
        id: 5,
        name: 'Lomo saltado',
        price: 13,
        description: 'Salmón fresco con salsa de mantequilla',
        imageUrl: 'assets/images/lomo saltado.jpg',
        category: widget.mealType,
      ),
    ];
    return products;
  }
}
