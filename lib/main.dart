import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/product_model.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';
import 'pages/splash/splash_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/user/home_page.dart';
import 'pages/user/product_detail_page.dart';
import 'pages/user/cart_page.dart';
import 'pages/user/checkout_page.dart';
import 'pages/user/profile_page.dart';
import 'pages/user/order_history_page.dart';
import 'pages/admin/admin_home_page.dart';
import 'pages/admin/product_manage_page.dart';
import 'pages/admin/admin_orders_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Toko Elektronik',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.splash:
                  return MaterialPageRoute(builder: (_) => const SplashPage());
                case AppRoutes.login:
                  return MaterialPageRoute(builder: (_) => const LoginPage());
                case AppRoutes.register:
                  return MaterialPageRoute(builder: (_) => const RegisterPage());
                case AppRoutes.userHome:
                  return MaterialPageRoute(builder: (_) => const UserHomePage());
                case AppRoutes.productDetail:
                  final product = settings.arguments as ProductModel;
                  return MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: product));
                case AppRoutes.cart:
                  return MaterialPageRoute(builder: (_) => const CartPage());
                case AppRoutes.checkout:
                  return MaterialPageRoute(builder: (_) => const CheckoutPage());
                case AppRoutes.profile:
                  return MaterialPageRoute(builder: (_) => const ProfilePage());
                case AppRoutes.orderHistory:
                  return MaterialPageRoute(builder: (_) => const OrderHistoryPage());
                case AppRoutes.adminHome:
                  return MaterialPageRoute(builder: (_) => const AdminHomePage());
                case AppRoutes.adminProductManage:
                  return MaterialPageRoute(builder: (_) => const ProductManagePage());
                case AppRoutes.adminOrders:
                  return MaterialPageRoute(builder: (_) => const AdminOrdersPage());
                default:
                  return MaterialPageRoute(builder: (_) => const SplashPage());
              }
            },
          );
        },
      ),
    );
  }
}
