import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MemoryMatchApp());
}

class MemoryMatchApp extends StatelessWidget {
  const MemoryMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Match',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        fontFamily: 'Arial',
      ),
      home: const MemoryGameScreen(),
    );
  }
}

class GameCard {
  final int id;
  final String imagePath;
  bool isFaceUp;
  bool isMatched;

  GameCard({
    required this.id,
    required this.imagePath,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<String> _images = const [
    'assets/images/card_1.png',
    'assets/images/card_2.png',
    'assets/images/card_3.png',
    'assets/images/card_4.png',
    'assets/images/card_5.png',
    'assets/images/card_6.png',
    'assets/images/card_7.png',
    'assets/images/card_8.png',
  ];

  late List<GameCard> _cards;
  final List<int> _selectedIndexes = [];
  bool _canTap = true;
  int _moves = 0;
  int _matches = 0;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _startNewGame() {
    final duplicated = [..._images, ..._images];
    duplicated.shuffle(Random());
    _cards = List.generate(
      duplicated.length,
      (index) => GameCard(id: index, imagePath: duplicated[index]),
    );
    _selectedIndexes.clear();
    _canTap = true;
    _moves = 0;
    _matches = 0;
    _seconds = 0;
    _startTimer();
    setState(() {});
  }

  void _onCardTap(int index) async {
    if (!_canTap || _cards[index].isFaceUp || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFaceUp = true;
      _selectedIndexes.add(index);
    });

    if (_selectedIndexes.length == 2) {
      _canTap = false;
      _moves++;
      final firstIndex = _selectedIndexes[0];
      final secondIndex = _selectedIndexes[1];
      final firstCard = _cards[firstIndex];
      final secondCard = _cards[secondIndex];

      await Future.delayed(const Duration(milliseconds: 700));

      if (firstCard.imagePath == secondCard.imagePath) {
        setState(() {
          firstCard.isMatched = true;
          secondCard.isMatched = true;
          _matches++;
        });
      } else {
        setState(() {
          firstCard.isFaceUp = false;
          secondCard.isFaceUp = false;
        });
      }

      _selectedIndexes.clear();
      _canTap = true;

      if (_matches == _images.length) {
        _timer?.cancel();
        _showWinDialog();
      }
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Congratulations!'),
        content: Text('You matched all cards in $_moves moves and $_seconds seconds.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F2FF), Color(0xFFE8F7FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildScorePanel(),
                const SizedBox(height: 14),
                Expanded(child: _buildGameGrid()),
                TextButton.icon(
                  onPressed: _startNewGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Game'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Match',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF302A67),
                  ),
            ),
            const SizedBox(height: 4),
            const Text('Find all matching pairs!'),
          ],
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
          child: const Icon(Icons.extension, color: Color(0xFF6C63FF)),
        ),
      ],
    );
  }

  Widget _buildScorePanel() {
    return Row(
      children: [
        Expanded(child: _statCard('Moves', '$_moves', Icons.touch_app)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Pairs', '$_matches/8', Icons.emoji_events)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Time', _formatTime(_seconds), Icons.timer)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = min(constraints.maxWidth, 520.0);
        return Center(
          child: SizedBox(
            width: maxWidth,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) => _buildCard(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    final showFront = card.isFaceUp || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: showFront ? Colors.white : const Color(0xFF6C63FF),
          border: Border.all(
            color: card.isMatched ? const Color(0xFF31C48D) : Colors.white,
            width: card.isMatched ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: showFront
              ? Padding(
                  key: ValueKey('front$index'),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(card.imagePath, fit: BoxFit.contain),
                )
              : const Center(
                  key: ValueKey('back'),
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
