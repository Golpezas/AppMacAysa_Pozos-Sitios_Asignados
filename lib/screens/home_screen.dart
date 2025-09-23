import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/database_helper.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Site> sites = [];
  List<Well> wells = [];
  int currentPageSites = 1;
  int currentPageWells = 1;
  final int perPage = 20;
  bool isLoading = true;
  String searchQuery = '';
  int totalSites = 0;
  int totalWells = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _searchController.addListener(_onSearchChanged);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadDataForCurrentTab();
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _loadDataForCurrentTab();
    });
  }

  Future<void> _loadAllData() async {
    await _loadSites();
    await _loadWells();
  }

  Future<void> _loadDataForCurrentTab() async {
    if (_tabController.index == 0) {
      _loadSites();
    } else {
      _loadWells();
    }
  }

  Future<void> _loadSites({int? page}) async {
    setState(() => isLoading = true);
    final nextPage = page ?? currentPageSites;
    final loadedSites = await dbHelper.getSites(
      query: searchQuery,
      page: nextPage,
      perPage: perPage,
    );
    final count = await dbHelper.getSitesCount(query: searchQuery);
    setState(() {
      sites = loadedSites;
      currentPageSites = nextPage;
      totalSites = count;
      isLoading = false;
    });
  }

  Future<void> _loadWells({int? page}) async {
    setState(() => isLoading = true);
    final nextPage = page ?? currentPageWells;
    final loadedWells = await dbHelper.getWells(
      query: searchQuery,
      page: nextPage,
      perPage: perPage,
    );
    final count = await dbHelper.getWellsCount(query: searchQuery);
    setState(() {
      wells = loadedWells;
      currentPageWells = nextPage;
      totalWells = count;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSitesTab = _tabController.index == 0;
    final int totalItems = isSitesTab ? totalSites : totalWells;
    final int currentPage = isSitesTab ? currentPageSites : currentPageWells;
    final int totalPages = (totalItems / perPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Servicios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Sitios'),
                  Tab(text: 'Pozos'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: SpinKitCircle(color: Colors.blue, size: 50.0))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(sites),
                _buildListView(wells),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: currentPage > 1 ? () => isSitesTab ? _loadSites(page: currentPage - 1) : _loadWells(page: currentPage - 1) : null,
              child: const Icon(Icons.arrow_back),
            ),
            Text('Página $currentPage de $totalPages'),
            ElevatedButton(
              onPressed: currentPage < totalPages ? () => isSitesTab ? _loadSites(page: currentPage + 1) : _loadWells(page: currentPage + 1) : null,
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List items) {
    if (items.isEmpty) {
      return const Center(child: Text('No se encontraron resultados.'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Estado: ${item.status}'),
            onTap: () => _showItemDetails(context, item),
          ),
        );
      },
    );
  }

  Future<void> _showItemDetails(BuildContext context, dynamic item) async {
    final mobileUnit = await dbHelper.getMobileUnit(item.mobileUnitId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dirección: ${item.address}'),
            if (item is Site) Text('Motivo: ${item.motive}'),
            Text('Horario: ${item.serviceSchedule}'),
            const SizedBox(height: 10),
            Text('Unidad Móvil: ${mobileUnit?.name ?? 'N/A'}'),
            Text('Teléfono: ${mobileUnit?.phone ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}