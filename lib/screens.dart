import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'db.dart';

String money(num n)=>'৳${n.toStringAsFixed(2)}';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  int tab=0;
  final pages=const [Dashboard(),MedicinePage(),SalePage(),ReportPage()];
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('Pharmacy POS')),
    body:pages[tab],
    bottomNavigationBar:NavigationBar(
      selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.dashboard),label:'Dashboard'),
        NavigationDestination(icon:Icon(Icons.medication),label:'Medicine'),
        NavigationDestination(icon:Icon(Icons.point_of_sale),label:'Sale'),
        NavigationDestination(icon:Icon(Icons.analytics),label:'Reports'),
      ]),
    floatingActionButton:tab==1?FloatingActionButton(onPressed:()=>medicineForm(c),child:const Icon(Icons.add)):null);
}

class Dashboard extends StatefulWidget{const Dashboard({super.key});@override State<Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<Dashboard>{
  Map<String,double>d={};
  @override void initState(){super.initState();load();}
  Future<void>load()async{d=await AppDb.instance.dashboard();if(mounted)setState((){});}
  @override Widget build(BuildContext c)=>RefreshIndicator(
    onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('আজকের সারাংশ',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      Wrap(spacing:10,runSpacing:10,children:[
        tile('বিক্রি',d['sales']??0,Icons.point_of_sale),
        tile('খরচ',d['expense']??0,Icons.payments),
        tile('পাওনা',d['due']??0,Icons.account_balance_wallet),
        tile('স্টক',d['stock']??0,Icons.inventory),
      ])
    ]));
  Widget tile(String t,double v,IconData i)=>SizedBox(width:160,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),Text(t),Text(money(v),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]))));
}

class MedicinePage extends StatefulWidget{const MedicinePage({super.key});@override State<MedicinePage> createState()=>_MedicinePageState();}
class _MedicinePageState extends State<MedicinePage>{
  final q=TextEditingController();List<Map<String,Object?>>data=[];
  @override void initState(){super.initState();load();}
  Future<void>load()async{data=await AppDb.instance.medicines(q:q.text);if(mounted)setState((){});}
  @override Widget build(BuildContext c)=>Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:TextField(controller:q,onChanged:(_)=>load(),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ওষুধ / generic / barcode',border:OutlineInputBorder()))),
    Expanded(child:ListView.builder(itemCount:data.length,itemBuilder:(_,i){
      final m=data[i];return ListTile(
        leading:CircleAvatar(child:Text('${(m['stock'] as num).toInt()}')),
        title:Text('${m['name']} • ${m['batch']??''}'),
        subtitle:Text('Expiry ${m['expiry']??'-'} | ${money((m['sale'] as num?)??0)}'),
        onTap:()=>medicineForm(c,existing:m));
    }))
  ]);
}

Future<void>medicineForm(BuildContext c,{Map<String,Object?>?existing})async{
  final n=TextEditingController(text:'${existing?['name']??''}');
  final g=TextEditingController(text:'${existing?['generic']??''}');
  final co=TextEditingController(text:'${existing?['company']??''}');
  final b=TextEditingController(text:'${existing?['barcode']??''}');
  final ba=TextEditingController(text:'${existing?['batch']??''}');
  final e=TextEditingController(text:'${existing?['expiry']??''}');
  final p=TextEditingController(text:'${existing?['purchase']??''}');
  final s=TextEditingController(text:'${existing?['sale']??''}');
  final st=TextEditingController(text:'${existing?['stock']??''}');
  await showDialog(context:c,builder:(x)=>AlertDialog(
    title:Text(existing==null?'নতুন ওষুধ':'ওষুধ সম্পাদনা'),
    content:SizedBox(width:500,child:SingleChildScrollView(child:Column(children:[
      fld(n,'ওষুধের নাম'),fld(g,'Generic'),fld(co,'কোম্পানি'),fld(b,'Barcode'),
      fld(ba,'Batch'),fld(e,'Expiry YYYY-MM-DD'),fld(p,'ক্রয় মূল্য'),fld(s,'বিক্রয় মূল্য'),fld(st,'স্টক')
    ]))),
    actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('Cancel')),
      FilledButton(onPressed:()async{
        final m={'name':n.text,'generic':g.text,'company':co.text,'barcode':b.text,'batch':ba.text,'expiry':e.text,
          'purchase':double.tryParse(p.text)??0,'sale':double.tryParse(s.text)??0,'stock':double.tryParse(st.text)??0};
        if(existing==null)await AppDb.instance.addMedicine(m);else await AppDb.instance.updateMedicine(existing['id'] as int,m);
        if(x.mounted)Navigator.pop(x);
      },child:const Text('Save'))]));
}
Widget fld(TextEditingController x,String l)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:x,decoration:InputDecoration(labelText:l,border:const OutlineInputBorder())));

class SalePage extends StatefulWidget{const SalePage({super.key});@override State<SalePage> createState()=>_SalePageState();}
class _SalePageState extends State<SalePage>{
  final q=TextEditingController();List<Map<String,Object?>>found=[],cart=[];
  Future<void>find()async{found=await AppDb.instance.medicines(q:q.text);setState((){});}
  double get total=>cart.fold(0,(a,x)=>a+(x['qty'] as num)*(x['sale'] as num));
  @override Widget build(BuildContext c)=>Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      Expanded(child:TextField(controller:q,onChanged:(_)=>find(),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ওষুধ খুঁজুন',border:OutlineInputBorder()))),
      IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Scanner(onCode:(v){Navigator.pop(c);q.text=v;find();}))),icon:const Icon(Icons.qr_code_scanner))
    ])),
    if(found.isNotEmpty)SizedBox(height:150,child:ListView(children:found.take(10).map((m)=>ListTile(title:Text('${m['name']} (${m['batch']})'),subtitle:Text('Stock ${m['stock']} • ${money(m['sale'] as num)}'),onTap:(){final x=Map<String,Object?>.from(m);x['qty']=1;setState(()=>cart.add(x));q.clear();found=[];})).toList())),
    Expanded(child:ListView.builder(itemCount:cart.length,itemBuilder:(_,i){final x=cart[i];return ListTile(title:Text('${x['name']}'),subtitle:Text('Qty ${x['qty']} × ${money(x['sale'] as num)}'),trailing:IconButton(icon:const Icon(Icons.delete),onPressed:()=>setState(()=>cart.removeAt(i))));})),
    Padding(padding:const EdgeInsets.all(12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('মোট ${money(total)}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),FilledButton(onPressed:cart.isEmpty?null:()=>checkout(c),child:const Text('Checkout'))]))
  ]);
  Future<void>checkout(BuildContext c)async{
    final paid=TextEditingController(text:total.toStringAsFixed(2)),customer=TextEditingController();
    await showDialog(context:c,builder:(x)=>AlertDialog(title:const Text('Checkout'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      Text('Total ${money(total)}'),fld(paid,'Paid'),fld(customer,'Customer')
    ]),actions:[FilledButton(onPressed:()async{await AppDb.instance.saveSale(cart,double.tryParse(paid.text)??0,'Cash',customer.text);cart=[];if(x.mounted)Navigator.pop(x);setState((){});},child:const Text('Save'))]));
  }
}

class Scanner extends StatelessWidget{
  final void Function(String)onCode;const Scanner({super.key,required this.onCode});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Barcode Scanner')),body:MobileScanner(onDetect:(capture){final code=capture.barcodes.first.rawValue;if(code!=null)onCode(code);}));
}

class ReportPage extends StatelessWidget{const ReportPage({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('Reports',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
  ListTile(leading:const Icon(Icons.receipt_long),title:const Text('Daily sales'),subtitle:const Text('Dashboard-এ আজকের বিক্রি দেখুন')),
  ListTile(leading:const Icon(Icons.warning),title:const Text('Expiry / low stock'),subtitle:const Text('Medicine list থেকে batch ও expiry দেখুন')),
  ListTile(leading:const Icon(Icons.add_card),title:const Text('Expense'),onTap:()=>expenseForm(c)),
]);}

Future<void>expenseForm(BuildContext c)async{
  final t=TextEditingController(),a=TextEditingController();
  await showDialog(context:c,builder:(x)=>AlertDialog(title:const Text('খরচ যোগ করুন'),content:Column(mainAxisSize:MainAxisSize.min,children:[fld(t,'বিবরণ'),fld(a,'পরিমাণ')]),actions:[FilledButton(onPressed:()async{await AppDb.instance.addExpense(t.text,double.tryParse(a.text)??0,'Cash');if(x.mounted)Navigator.pop(x);},child:const Text('Save'))]));
}
