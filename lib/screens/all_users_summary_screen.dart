import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/services/settings_service.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

class AllUsersSummaryScreen extends StatefulWidget {
  final int eventId;
  final int userId;
  final String userRole;

  const AllUsersSummaryScreen({
    required this.eventId,
    required this.userId,
    this.userRole = 'USER',
    super.key,
  });

  @override
  State<AllUsersSummaryScreen> createState() => _AllUsersSummaryScreenState();
}

class _AllUsersSummaryScreenState extends State<AllUsersSummaryScreen> {
  List<dynamic> usersData = [];
  bool isLoading = false;
  bool _applyDeposit = true;
  final baseUrl = AppConfig.baseUrl;
  final Color mainColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // Carga el setting "a cuenta" en paralelo con los datos de usuarios.
      final settingsService = SettingsService(
        adminUserId: widget.userId,
        adminUserRole: widget.userRole,
      );
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/summary/all-users?eventId=${widget.eventId}')),
        settingsService.getSettings().then<bool>((s) {
          final raw = s['apply_deposit'];
          return raw == true || raw == 'true';
        }).catchError((_) => true),
      ]);

      if (!mounted) return;
      final response = results[0] as http.Response;
      final applyDeposit = results[1] as bool;
      if (response.statusCode == 200) {
        setState(() {
          usersData = jsonDecode(utf8.decode(response.bodyBytes));
          _applyDeposit = applyDeposit;
        });
      } else {
        _showError('Error al cargar el resumen');
      }
    } catch (_) {
      if (!mounted) return;
      _showError('Error de red al cargar el resumen');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    AppSnackBar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen por usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: fetchAllUsers,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 800,
          child: isLoading
              ? const SkeletonList(itemCount: 6)
              : usersData.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No hay datos disponibles',
                      message: 'Cuando haya participantes verás aquí el balance de cada uno.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: usersData.length,
                      itemBuilder: (context, index) =>
                          _UserCard(user: usersData[index], mainColor: mainColor, applyDeposit: _applyDeposit),
                    ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card expandible por usuario
// ---------------------------------------------------------------------------
class _UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final Color mainColor;
  final bool applyDeposit;

  const _UserCard({required this.user, required this.mainColor, required this.applyDeposit});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _expanded = false;

  Future<void> _generatePdf(Map<String, dynamic> u) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto.ttf');
    final ttf = pw.Font.ttf(fontData);
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final username = u['username'] ?? 'Usuario';
    final balance = (u['balance'] ?? 0.0).toDouble();
    final haAportado = (u['ha_aportado'] ?? 0.0).toDouble();
    final debe = (u['debe'] ?? 0.0).toDouble();
    final totalConsumption = (u['total_consumption'] ?? 0.0).toDouble();
    final totalLunch = (u['total_lunch_cost'] ?? 0.0).toDouble();
    final commonShare = (u['common_share'] ?? 0.0).toDouble();

    final consumptions = (u['consumptions'] as List? ?? []);
    // Filtra "A cuenta" si el modo no está activo.
    final allPaidExpenses = (u['paid_expenses_by_type'] as List? ?? []);
    final paidExpenses = widget.applyDeposit
        ? allPaidExpenses
        : allPaidExpenses.where((e) => e['expense_type'] != 'A cuenta').toList();
    final aCuentaPdf = widget.applyDeposit
        ? 0.0
        : allPaidExpenses
            .where((e) => e['expense_type'] == 'A cuenta')
            .fold<double>(0.0, (s, e) => s + ((e['total_amount'] ?? 0.0) as num).toDouble());
    final totalPaidByType = ((u['total_paid_by_type'] ?? 0.0) as num).toDouble() - aCuentaPdf;
    final lunchCosts = (u['lunch_costs'] as List? ?? [])
        .where((l) => (l['user_cost'] ?? 0.0) > 0)
        .toList();
    final commonExpenses = (u['common_expenses_detail'] as List? ?? []);

    final balanceStr = balance >= 0
        ? 'Le deben: €${balance.toStringAsFixed(2)}'
        : 'Debe: €${balance.abs().toStringAsFixed(2)}';

    pw.Widget _pdfSection(String title, List<pw.Widget> rows) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 10),
          pw.Text(title,
              style: pw.TextStyle(font: ttf, fontSize: 13, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800)),
          pw.Divider(thickness: 0.5),
          ...rows,
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, height: 36),
              pw.Text(username,
                  style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          // Balance destacado
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: balance >= 0 ? PdfColors.green50 : PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ha aportado: €${haAportado.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.Text('Debe: €${debe.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: ttf, fontSize: 12)),
                pw.Text(balanceStr,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0 ? PdfColors.green700 : PdfColors.red700)),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          // Totales
          pw.Table.fromTextArray(
            headers: ['Consumo', 'Almuerzos', 'Gastos pagados', 'Parte común'],
            data: [
              [
                '€${totalConsumption.toStringAsFixed(2)}',
                '€${totalLunch.toStringAsFixed(2)}',
                '€${totalPaidByType.toStringAsFixed(2)}',
                '€${commonShare.toStringAsFixed(2)}',
              ]
            ],
            headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 11),
            cellAlignment: pw.Alignment.center,
          ),

          // Consumiciones
          if (consumptions.isNotEmpty)
            _pdfSection('Consumiciones', [
              pw.Table.fromTextArray(
                headers: ['Producto', 'Tipología', 'Cantidad', 'Total'],
                data: consumptions.map<List<String>>((c) => [
                  c['product_name'] ?? '',
                  c['typology'] ?? '',
                  '${c['total_qty']}',
                  '€${(c['total_price'] ?? 0.0).toStringAsFixed(2)}',
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                cellAlignment: pw.Alignment.center,
              ),
            ]),

          // Gastos pagados
          if (paidExpenses.isNotEmpty)
            _pdfSection('Gastos pagados', [
              pw.Table.fromTextArray(
                headers: ['Tipo', 'Total'],
                data: paidExpenses.map<List<String>>((e) => [
                  e['expense_type'] ?? '',
                  '€${(e['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                cellAlignment: pw.Alignment.center,
              ),
            ]),

          // Almuerzos
          if (lunchCosts.isNotEmpty)
            _pdfSection('Almuerzos', [
              pw.Table.fromTextArray(
                headers: ['Descripción', 'Personas', '€/plato', 'Tu parte'],
                data: lunchCosts.map<List<String>>((l) => [
                  l['description'] ?? '',
                  '${l['user_people']}',
                  '€${(l['cost_per_plate'] ?? 0.0).toStringAsFixed(2)}',
                  '€${(l['user_cost'] ?? 0.0).toStringAsFixed(2)}',
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                cellAlignment: pw.Alignment.center,
              ),
            ]),

          // Gastos comunes
          if (commonExpenses.isNotEmpty)
            _pdfSection('Gastos comunes', [
              pw.Table.fromTextArray(
                headers: ['Concepto', 'Total', 'Tu parte'],
                data: commonExpenses.map<List<String>>((e) => [
                  e['concept'] ?? '',
                  '€${(e['amount'] ?? 0.0).toStringAsFixed(2)}',
                  '€${(e['user_share'] ?? 0.0).toStringAsFixed(2)}',
                ]).toList(),
                headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                cellAlignment: pw.Alignment.center,
              ),
            ]),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } else {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${username.replaceAll(' ', '_')}_resumen.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final color = widget.mainColor;
    final balance = (u['balance'] ?? 0.0).toDouble();
    final debe = (u['debe'] ?? 0.0).toDouble();
    final haAportado = (u['ha_aportado'] ?? 0.0).toDouble();
    final balanceColor = balance >= 0 ? Colors.green[700]! : Colors.red[700]!;
    final balanceLabel = balance >= 0
        ? 'Recibe €${balance.toStringAsFixed(2)}'
        : 'Debe €${balance.abs().toStringAsFixed(2)}';

    // Filtra gastos "A cuenta" si el modo no está activo.
    final allExpenses = List<dynamic>.from(u['paid_expenses_by_type'] ?? []);
    final filteredExpenses = widget.applyDeposit
        ? allExpenses
        : allExpenses.where((e) => e['expense_type'] != 'A cuenta').toList();
    final aCuentaTotal = widget.applyDeposit
        ? 0.0
        : allExpenses
            .where((e) => e['expense_type'] == 'A cuenta')
            .fold<double>(0.0, (s, e) => s + ((e['total_amount'] ?? 0.0) as num).toDouble());
    final adjustedPaidTotal =
        ((u['total_paid_by_type'] ?? 0.0) as num).toDouble() - aCuentaTotal;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (u['username'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          title: Text(
            u['username'] ?? 'Usuario',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
          subtitle: Text(
            balanceLabel,
            style: TextStyle(color: balanceColor, fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Descargar PDF',
                color: color,
                onPressed: () => _generatePdf(u),
              ),
              // flecha por defecto del ExpansionTile
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            _SummaryTotalsRow(user: u, mainColor: color, paidTotal: adjustedPaidTotal),
            const Divider(),
            _LossDetailRow(
              drinkLoss: (u['drink_loss_per_user'] ?? 0.0).toDouble(),
              foodLoss: (u['food_loss_per_user'] ?? 0.0).toDouble(),
            ),
            _BalanceDetailRow(haAportado: haAportado, debe: debe, balance: balance),
            const Divider(),
            _ConsumptionsSection(consumptions: u['consumptions'] ?? [], mainColor: color),
            const SizedBox(height: 6),
            _ExpensesSection(expenses: filteredExpenses, mainColor: color),
            const SizedBox(height: 6),
            _LunchSection(lunchCosts: u['lunch_costs'] ?? [], mainColor: color),
            const SizedBox(height: 6),
            _CommonExpensesSection(
              items: u['common_expenses_detail'] ?? [],
              commonShare: (u['common_share'] ?? 0.0).toDouble(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila resumen de totales del usuario
// ---------------------------------------------------------------------------
class _SummaryTotalsRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final Color mainColor;
  final double paidTotal;

  const _SummaryTotalsRow({required this.user, required this.mainColor, required this.paidTotal});

  Widget _tile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _tile('Consumo', '€${(user['total_consumption'] ?? 0.0).toStringAsFixed(2)}', mainColor),
          _tile('Almuerzos', '€${(user['total_lunch_cost'] ?? 0.0).toStringAsFixed(2)}', Colors.blue[700]!),
          _tile('Gastos pagados', '€${paidTotal.toStringAsFixed(2)}', Colors.orange[800]!),
          _tile('Parte común', '€${(user['common_share'] ?? 0.0).toStringAsFixed(2)}', Colors.purple[700]!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila ha_aportado / debe + balance destacado
// ---------------------------------------------------------------------------
class _BalanceDetailRow extends StatelessWidget {
  final double haAportado;
  final double debe;
  final double balance;

  const _BalanceDetailRow({
    required this.haAportado,
    required this.debe,
    required this.balance,
  });

  Widget _smallTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.black54),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        balance >= 0 ? Colors.green[700]! : Colors.red[700]!;
    final balanceLabel =
        balance >= 0 ? 'Recibe' : 'Debe pagar';
    final balanceStr =
        '${balance >= 0 ? '+' : ''}€${balance.abs().toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Fila secundaria: ha aportado + debe
          Row(
            children: [
              _smallTile('Ha aportado',
                  '€${haAportado.toStringAsFixed(2)}', Colors.green[700]!),
              _smallTile(
                  'Debe', '€${debe.toStringAsFixed(2)}', Colors.red[700]!),
            ],
          ),
          const SizedBox(height: 8),
          // Balance destacado: barra ancha con fondo sólido
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: balanceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balanceLabel,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Balance final',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  balanceStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección consumiciones
// ---------------------------------------------------------------------------
class _ConsumptionsSection extends StatelessWidget {
  final List<dynamic> consumptions;
  final Color mainColor;

  const _ConsumptionsSection({required this.consumptions, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    if (consumptions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.local_drink, label: 'Consumiciones', color: mainColor),
        ...consumptions.map((c) => ListTile(
              dense: true,
              title: Text(c['product_name'] ?? ''),
              subtitle: Text(c['typology'] ?? ''),
              trailing: Text(
                'x${c['total_qty']}  €${(c['total_price'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w600, color: mainColor),
              ),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sección gastos pagados por tipo
// ---------------------------------------------------------------------------
class _ExpensesSection extends StatelessWidget {
  final List<dynamic> expenses;
  final Color mainColor;

  const _ExpensesSection({required this.expenses, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.receipt_long, label: 'Gastos pagados', color: Colors.orange[800]!),
        ...expenses.map((e) => ListTile(
              dense: true,
              title: Text(e['expense_type'] ?? ''),
              trailing: Text(
                '€${(e['total_amount'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange[800]),
              ),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sección almuerzos
// ---------------------------------------------------------------------------
class _LunchSection extends StatelessWidget {
  final List<dynamic> lunchCosts;
  final Color mainColor;

  const _LunchSection({required this.lunchCosts, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    final filtered = lunchCosts.where((l) => (l['user_cost'] ?? 0.0) > 0).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.restaurant, label: 'Almuerzos', color: Colors.blue[700]!),
        ...filtered.map((l) => ListTile(
              dense: true,
              title: Text(l['description'] ?? 'Almuerzo'),
              subtitle: Text(
                '${l['user_people']} persona(s) • €${(l['cost_per_plate'] ?? 0.0).toStringAsFixed(2)}/plato',
              ),
              trailing: Text(
                '€${(l['user_cost'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[700]),
              ),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sección gastos comunes (desglose + parte proporcional)
// ---------------------------------------------------------------------------
class _CommonExpensesSection extends StatelessWidget {
  final List<dynamic> items;
  final double commonShare;

  const _CommonExpensesSection({required this.items, required this.commonShare});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.share,
          label: 'Gastos comunes',
          color: Colors.purple[700]!,
        ),
        ...items.map((e) => ListTile(
              dense: true,
              title: Text(e['concept'] ?? ''),
              subtitle: Text('Total: €${(e['amount'] ?? 0.0).toStringAsFixed(2)}'),
              trailing: Text(
                '€${(e['user_share'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tiles de pérdida proporcional por bebida y comida
// Mismo estilo visual que _BalanceDetailRow
// ---------------------------------------------------------------------------
class _LossDetailRow extends StatelessWidget {
  final double drinkLoss;
  final double foodLoss;

  const _LossDetailRow({required this.drinkLoss, required this.foodLoss});

  String _formatLoss(double value) {
    if (value == 0.0) return '€0.00';
    final sign = value > 0 ? '+' : '';
    return '$sign€${value.toStringAsFixed(2)}';
  }

  Color _colorFor(double value) {
    if (value < 0) return Colors.green[700]!;
    if (value > 0) return Colors.red[700]!;
    return Colors.black54;
  }

  Widget _tile(String label, double value) {
    final color = _colorFor(value);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              _formatLoss(value),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (drinkLoss <= 0.0 && foodLoss <= 0.0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (drinkLoss > 0.0) _tile('Pérdida bebida / socio', drinkLoss),
          if (foodLoss > 0.0) _tile('Pérdida comida / socio', foodLoss),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabecera de sección interna
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

