// Este es un archivo de prueba básico para los widgets de la aplicación.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_management_mobile/main.dart';
import 'package:service_management_mobile/screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  // Configurar sqflite para pruebas en ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Copia la base de datos de los assets a un directorio de prueba
  Future<void> copyDatabaseForTest() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'service_db.sqlite');
    if (await Directory(dirname(path)).exists()) {
      await Directory(dirname(path)).delete(recursive: true);
    }
    await Directory(dirname(path)).create(recursive: true);
    final file = File('assets/service_db.sqlite');
    if (await file.exists()) {
      await file.copy(path);
    }
  }

  setUpAll(() async {
    // Asegúrate de que la base de datos de prueba exista antes de ejecutar los tests
    await copyDatabaseForTest();
  });

  testWidgets('HomeScreen se renderiza y muestra la barra de búsqueda y las pestañas', (WidgetTester tester) async {
    // Construye nuestra aplicación.
    await tester.pumpWidget(const MyApp());

    // Espera a que los datos se carguen y los widgets se rendericen
    await tester.pumpAndSettle();

    // Verifica que la pantalla principal (HomeScreen) esté presente
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verifica que la barra de búsqueda esté presente
    expect(find.byType(TextField), findsOneWidget);

    // Verifica que las pestañas "Sitios" y "Pozos" estén presentes
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.text('Sitios'), findsOneWidget);
    expect(find.text('Pozos'), findsOneWidget);
  });

  testWidgets('Se muestran las tarjetas de sitios y la paginación', (WidgetTester tester) async {
    // Construye nuestra aplicación
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verifica que se muestren las tarjetas (listas) de sitios.
    // La prueba asume que la base de datos no está vacía.
    expect(find.byType(Card), findsWidgets);

    // Verifica que los botones de paginación estén presentes
    expect(find.byType(ElevatedButton), findsNWidgets(2));
  });

  testWidgets('Tocar un ítem muestra un diálogo de detalles', (WidgetTester tester) async {
    // Construye nuestra aplicación
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Toca el primer ítem en la lista para abrir el diálogo de detalles
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Verifica que el diálogo de detalles se muestre
    expect(find.byType(AlertDialog), findsOneWidget);

    // Verifica que el diálogo contenga la información esperada (por ejemplo, el botón "Cerrar")
    expect(find.text('Cerrar'), findsOneWidget);
    
    // Cierra el diálogo
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}