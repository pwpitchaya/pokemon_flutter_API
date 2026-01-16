import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex Pro',
      theme: ThemeData(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: const Color(0xfff6f6f6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const PokemonListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//////////////////////////////////////////////////////////////
// LIST SCREEN
//////////////////////////////////////////////////////////////

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List pokemons = [];
  int offset = 0;
  final int limit = 20;
  bool isGrid = false;
  bool isLoading = false;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPokemon();

    _controller.addListener(() {
      if (_controller.position.pixels ==
          _controller.position.maxScrollExtent) {
        fetchPokemon();
      }
    });
  }

  Future<void> fetchPokemon() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset');

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    setState(() {
      pokemons.addAll(data['results']);
      offset += limit;
      isLoading = false;
    });
  }

  String getId(String url) => url.split('/')[6];

  String getImage(String url) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${getId(url)}.png';

  Color cardColor(int id) {
    final colors = [
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.yellow.shade100,
    ];
    return colors[id % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pokédex"),
        actions: [
          IconButton(
            icon: Icon(isGrid ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => isGrid = !isGrid),
          )
        ],
      ),
      body: isGrid ? buildGrid() : buildList(),
    );
  }

  //////////////////////////////////////////////////////////////
  // LIST VIEW
  //////////////////////////////////////////////////////////////

  Widget buildList() {
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(8),
      itemCount: pokemons.length,
      itemBuilder: (context, index) {
        final p = pokemons[index];
        final id = getId(p['url']);

        return Card(
          color: cardColor(int.parse(id)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: ListTile(
            leading: Hero(
              tag: p['name'],
              child: Image.network(getImage(p['url'])),
            ),
            title: Text(
              p['name'].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("#$id"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PokemonDetailScreen(
                    name: p['name'],
                    url: p['url'],
                    color: cardColor(int.parse(id)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  //////////////////////////////////////////////////////////////
  // GRID VIEW + LOAD MORE
  //////////////////////////////////////////////////////////////

  Widget buildGrid() {
    return GridView.builder(
      controller: _controller,
      padding: const EdgeInsets.all(8),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
      ),

      itemCount: pokemons.length + 1,

      itemBuilder: (context, index) {
        // ช่องสุดท้าย = Load More
        if (index == pokemons.length) {
          return Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: fetchPokemon,
                    child: const Text("Load More"),
                  ),
          );
        }

        final p = pokemons[index];
        final id = getId(p['url']);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PokemonDetailScreen(
                  name: p['name'],
                  url: p['url'],
                  color: cardColor(int.parse(id)),
                ),
              ),
            );
          },
          child: Card(
            color: cardColor(int.parse(id)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: p['name'],
                  child: Image.network(
                    getImage(p['url']),
                    height: 100,
                  ),
                ),
                const SizedBox(height: 8),
                Text("#$id"),
                Text(
                  p['name'].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////
// DETAIL SCREEN
//////////////////////////////////////////////////////////////

class PokemonDetailScreen extends StatefulWidget {
  final String name;
  final String url;
  final Color color;

  const PokemonDetailScreen({
    super.key,
    required this.name,
    required this.url,
    required this.color,
  });

  @override
  State<PokemonDetailScreen> createState() =>
      _PokemonDetailScreenState();
}

class _PokemonDetailScreenState
    extends State<PokemonDetailScreen> {

  Map? detail;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final res = await http.get(Uri.parse(widget.url));
    setState(() {
      detail = jsonDecode(res.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final id = detail!['id'];

    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(title: Text(widget.name.toUpperCase())),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: widget.name,
              child: Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                height: 200,
              ),
            ),

            Card(
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text("ID: $id"),
                    Text("Height: ${detail!['height']}"),
                    Text("Weight: ${detail!['weight']}"),

                    const SizedBox(height: 10),

                    Wrap(
                      children: (detail!['types'] as List)
                          .map((t) => Padding(
                                padding: const EdgeInsets.all(4),
                                child: Chip(
                                  backgroundColor:
                                      Colors.red.shade200,
                                  label: Text(t['type']['name']),
                                ),
                              ))
                          .toList(),
                    ),

                    const Divider(),

                    ...buildStats()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> buildStats() {
    return (detail!['stats'] as List).map((s) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(s['stat']['name']),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: s['base_stat'] / 200,
                color: Colors.red,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 8),
            Text("${s['base_stat']}"),
          ],
        ),
      );
    }).toList();
  }
}
