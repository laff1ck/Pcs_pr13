import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class ProfPage extends StatefulWidget {
  @override
  ProfPageState createState() => ProfPageState();
}

class ProfPageState extends State<ProfPage> {
  String? _userName;
  String? _userEmail;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrders();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('Пользователь не авторизован.');
      }

      print('Current User ID: ${user.id}');
      final response = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Пользователь не найден в базе данных.');
      }

      setState(() {
        _userName = response['name'] ?? 'Имя не указано';
        _userEmail = user.email;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );

      setState(() {
        _userName = 'Ошибка загрузки данных';
        _userEmail = '';
      });
    }
  }

  Future<void> _loadOrders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('Пользователь не авторизован.');
      }

      final response = await Supabase.instance.client
          .from('orders')
          .select('id, total_price, items, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        print('Полученные заказы: $response');
        setState(() {
          _orders = response as List<dynamic>;
        });
      } else {
        setState(() {
          _orders = [];
        });
      }
    } catch (e) {
      print('Ошибка загрузки заказов: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки заказов: $e')),
      );
    }
  }



  void _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Выйти',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Профиль'),
              Tab(text: 'Мои заказы'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Вкладка "Профиль"
            Center(
              child: _userName != null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Имя: $_userName',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Почта: $_userEmail',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
                  : const CircularProgressIndicator(),
            ),
            // Вкладка "Мои заказы"
            _orders.isEmpty
                ? const Center(child: Text('У вас нет заказов.'))
                : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final items = (order['items'] as List<dynamic>)
                    .map((item) =>
                '${item['product_name']} x${item['quantity']}')
                    .join(', ');

                return ListTile(
                  title: Text('Заказ #${order['id']}'),
                  subtitle: Text(items),
                  trailing: Text('${order['total_price']} ₽'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}