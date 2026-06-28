import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة الفايربيس الأساسية
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة قاعدة البيانات الفورية

void main() async {
  // تأمين تهيئة الفايربيس قبل تشغيل الواجهات
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    // إعداد ثيم الهكرز: أسود، رمادي داكن، وأخضر فسفوري
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Color(0xFF0D0D0D), // أسود خالص
      primaryColor: Color(0xFF00FF66), // أخضر هكرز
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF00FF66),
        surface: Color(0xFF1A1A1A),
      ),
    ),
    home: LoginScreen(),
  ));
}

// ---------------- 1. شاشة تسجيل الدخول (الهكرز) ----------------
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  void _loginAndSaveToFirebase() async {
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim().toLowerCase();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("النظام يتطلب الاسم واليوزر لتخطي الحماية...")),
      );
      return;
    }

    // حفظ بيانات المستخدم في الفايربيس في مجموعة الـ users
    await FirebaseFirestore.instance.collection('users').doc(username).set({
      'name': name,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // الانتقال لشاشة البحث
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          currentUserName: name,
          currentUserId: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.terminal, size: 90, color: Color(0xFF00FF66)), // أيقونة التيرمنال
            SizedBox(height: 10),
            Text(
              "SECURE CHAT SYSTEM v1.0.4",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF00FF66), fontFamily: 'Courier', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            TextField(
              controller: _nameController,
              style: TextStyle(color: Color(0xFF00FF66)),
              decoration: InputDecoration(
                labelText: "الاسم المستعار (Alias)",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF66))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Color(0xFF00FF66)),
              decoration: InputDecoration(
                labelText: "معرف النظام (Username)",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF66))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loginAndSaveToFirebase,
              child: Text("ACCESS SYSTEM", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00FF66),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 2. شاشة البحث الفورية في الفايربيس ----------------
class SearchScreen extends StatefulWidget {
  final String currentUserName;
  final String currentUserId;

  SearchScreen({required this.currentUserName, required this.currentUserId});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DATABASE SEARCH", style: TextStyle(fontFamily: 'Courier', color: Color(0xFF00FF66))),
        backgroundColor: Color(0xFF1A1A1A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(color: Color(0xFF00FF66)),
              decoration: InputDecoration(
                hintText: "ابحث عن يوزر الصديق بداخل السيرفر...",
                prefixIcon: Icon(Icons.search, color: Color(0xFF00FF66)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF66))),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _searchQuery.isEmpty
                  ? Center(child: Text("في انتظار إدخال المعرف...", style: TextStyle(color: Colors.grey, fontFamily: 'Courier')))
                  : StreamBuilder<QuerySnapshot>(
                      // جلب وقراءة اليوزرات مباشرة من الفايربيس والبحث بينهم
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isGreaterThanOrEqualTo: _searchQuery)
                          .where('username', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Color(0xFF00FF66)));
                        var users = snapshot.data!.docs;
                        
                        return ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            var user = users[index].data() as Map<String, dynamic>;
                            if (user['username'] == widget.currentUserId) return Container(); // لا تظهر حسابك في البحث

                            return Card(
                              color: Color(0xFF1A1A1A),
                              child: ListTile(
                                title: Text(user['name'], style: TextStyle(color: Colors.white)),
                                subtitle: Text("@${user['username']}", style: TextStyle(color: Color(0xFF00FF66))),
                                trailing: Icon(Icons.bolt, color: Color(0xFF00FF66)),
                                onTap: () {
                                  // توليد معرّف محادثة فريد وموحد بين الشخصين دائماً
                                  List<String> ids = [widget.currentUserId, user['username']];
                                  ids.sort();
                                  String chatId = ids.join("_");

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatId: chatId,
                                        currentUserId: widget.currentUserId,
                                        friendName: user['name'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 3. غرفة المحادثة الفورية والرسائل الحقيقية ----------------
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String friendName;

  ChatScreen({required this.chatId, required this.currentUserId, required this.friendName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    String msg = _textController.text.trim();
    _textController.clear();

    // إرسال الرسالة وحفظها بداخل الـ Firestore فوراً
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'text': msg,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CONNECTED_TO: ${widget.friendName.toUpperCase()}", style: TextStyle(fontFamily: 'Courier', fontSize: 14)),
        backgroundColor: Color(0xFF1A1A1A),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // الاستماع الدائم لأي رسائل جديدة تدخل السيرفر وعرضها في نفس الثانية
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Color(0xFF00FF66)));
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFF005522) : Color(0xFF222222),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isMe ? Color(0xFF00FF66) : Colors.grey, width: 0.5),
                        ),
                        child: Text(
                          data['text'] ?? "",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Courier'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Color(0xFF00FF66)),
                    decoration: InputDecoration(
                      hintText: "اكتب رسالة مشفرة...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1A1A1A),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFF00FF66))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white)),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF00FF66), size: 30),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
