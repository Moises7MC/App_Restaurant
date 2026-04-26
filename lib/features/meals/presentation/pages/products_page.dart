import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../meals/domain/entities/product.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../../services/api_service.dart';
import '../pages/cart_page.dart';

class ProductsPage extends StatefulWidget {
  final String mealType;
  final int tableNumber;
  final bool isParaLlevar; // ← NUEVO

  const ProductsPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    this.isParaLlevar = false, // ← NUEVO
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final Map<int, int> _itemsFromBackend = {};
  final Map<int, int> _backendItemIds = {};
  int? _activeOrderId;

  List<Map<String, dynamic>> _categories = [];
  bool _loadingProducts = true;
  String? _errorMessage;

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  HubConnection? _hubConnection;
  bool _signalRConnected = false;
  bool _refreshing = false;

  static const String _hubUrl = 'http://localhost:5245/hubs/orders';
  // static const String _hubUrl = 'https://app-restaurant-api.onrender.com/hubs/orders';

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(
      SelectTable(mealType: widget.mealType, tableNumber: widget.tableNumber),
    );
    _loadProducts();
    _loadExistingOrder();
    _connectSignalR();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hubConnection?.stop();
    super.dispose();
  }

  Future<void> _connectSignalR() async {
    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(_hubUrl)
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('MenuActualizado', (args) {
        if (!mounted) return;
        String reason = 'Menu actualizado';
        try {
          if (args != null && args.isNotEmpty) {
            final data = args[0];
            if (data is Map<String, dynamic>) {
              reason = data['reason']?.toString() ?? 'Menu actualizado';
            }
          }
        } catch (_) {}
        _showRefreshSnackbar(reason);
        _reloadProducts();
      });

      await _hubConnection!.start();
      await _hubConnection!.invoke('JoinWaitersGroup');
      if (mounted) setState(() => _signalRConnected = true);
    } catch (e) {
      debugPrint('SignalR no disponible: $e');
    }
  }

  void _showRefreshSnackbar(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _reloadProducts() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final data = await ApiService.getProductsByCategory();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          if (_selectedCategoryIndex >= _categories.length)
            _selectedCategoryIndex = 0;
          _refreshing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final data = await ApiService.getProductsByCategory();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar productos';
          _loadingProducts = false;
        });
      }
    }
  }

  Future<void> _loadExistingOrder() async {
    if (widget.isParaLlevar) return;
    try {
      final lastOrder = await ApiService.getLastPendingOrder(
        widget.tableNumber,
        isParaLlevar: widget.isParaLlevar,
      );
      if (lastOrder != null && mounted) {
        final items = lastOrder['items'] as List<dynamic>;
        setState(() => _activeOrderId = lastOrder['id'] as int);
        context.read<CartBloc>().add(LimpiarCarrito());
        for (var item in items) {
          final productId = item['productId'] as int;
          final quantity = item['quantity'] as int;
          final itemId = item['id'] as int;
          _itemsFromBackend[productId] = quantity;
          _backendItemIds[productId] = itemId;
          final product = Product(
            id: productId,
            name: item['product']?['name'] ?? 'Producto',
            price: (item['unitPrice'] as num).toDouble(),
            description: '',
            imageUrl: '',
            category: widget.mealType,
          );
          for (int i = 0; i < quantity; i++) {
            context.read<CartBloc>().add(AddToCart(product));
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando orden existente: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    if (_categories.isEmpty) return [];
    final category = _categories[_selectedCategoryIndex];
    final products = List<Map<String, dynamic>>.from(
      category['products'] ?? [],
    );
    if (_searchQuery.isEmpty) return products;
    return products
        .where(
          (p) => (p['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  Future<void> _openParaLlevar() async {
    final newCartBloc = CartBloc();
    newCartBloc.add(
      SelectTable(
        mealType: '${widget.mealType}_llevar',
        tableNumber: widget.tableNumber,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: newCartBloc,
          child: ProductsPage(
            mealType: widget.mealType,
            tableNumber: widget.tableNumber,
            isParaLlevar: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('${widget.mealType} - Mesa ${widget.tableNumber}'),
        title: Text(
          widget.isParaLlevar
              ? 'Para llevar — Mesa ${widget.tableNumber}'
              : '${widget.mealType} - Mesa ${widget.tableNumber}',
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goToTables(widget.mealType);
            }
          },
        ),
        actions: [
          // Indicador SignalR + Refresh
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _signalRConnected ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                _refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar menu',
                        onPressed: _reloadProducts,
                      ),
              ],
            ),
          ),
          // Botón Para llevar
          if (!widget.isParaLlevar)
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Para llevar',
              onPressed: _openParaLlevar,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoaded && state.totalItems > 0) {
                  return Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => CartPage(
                                  mealType: widget.mealType,
                                  tableNumber: widget.tableNumber,
                                  itemsFromBackend: widget.isParaLlevar
                                      ? {}
                                      : _itemsFromBackend,
                                  activeOrderId: widget.isParaLlevar
                                      ? null
                                      : _activeOrderId,
                                  backendItemIds: widget.isParaLlevar
                                      ? {}
                                      : _backendItemIds,
                                  isParaLlevar: widget.isParaLlevar,
                                ),
                              ),
                            )
                            .then((_) => _loadExistingOrder());
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

  Widget _buildBody() {
    if (_loadingProducts)
      return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loadingProducts = true;
                  _errorMessage = null;
                });
                _loadProducts();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_categories.isEmpty)
      return const Center(child: Text('No hay platos disponibles'));

    final filteredProducts = _getFilteredProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Text(
            'Selecciona tus platos',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),

        // Tabs categorías
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      cat['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Buscador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: _categories.isNotEmpty
                  ? 'Buscar en ${_categories[_selectedCategoryIndex]['name']}...'
                  : 'Buscar...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Lista de platos
        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No se encontraron platos'
                        : 'No hay platos en esta categoria',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 120,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    final product = Product(
                      id: p['id'] as int,
                      name: p['name'] as String,
                      price: (p['price'] as num).toDouble(),
                      description: p['description'] as String? ?? '',
                      imageUrl: p['imageUrl'] as String? ?? '',
                      category:
                          _categories[_selectedCategoryIndex]['name'] as String,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCard(context, product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        int quantity = 0;
        if (state is CartLoaded) {
          final item = state.items
              .where((i) => i.product.id == product.id)
              .firstOrNull;
          if (item != null) quantity = item.quantity;
        }

        final bool isFromBackend = _itemsFromBackend.containsKey(product.id);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromBackend
                ? AppColors.cardBackground.withValues(alpha: 0.7)
                : AppColors.cardBackground,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child:
                      product.imageUrl.isNotEmpty &&
                          product.imageUrl.startsWith('http')
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
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
                                  fontSize: 15,
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
                                fontSize: 15,
                              ),
                        ),
                      ],
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),

                    if (isFromBackend) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Agregado · modifica en el carrito',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 18,
                              color: AppColors.white,
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
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          GestureDetector(
                            onTap: quantity > 0
                                ? () => context.read<CartBloc>().add(
                                    RemoveFromCart(product.id),
                                  )
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
                            onTap: () => context.read<CartBloc>().add(
                              AddToCart(product),
                            ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 32))),
    );
  }
}
