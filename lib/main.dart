import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // 引入 camera 庫以使用相機功能
import 'package:qr_code_scanner/qr_code_scanner.dart'; // 引入 qr_code_scanner 庫以使用 QR Code 掃描器
import 'package:http/http.dart' as http; // 引入 http 庫以進行 HTTP 請求
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '臻琴社區郵件通知服務',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LineNotifyPage(),
    );
  }
}

class LineNotifyPage extends StatefulWidget {
  const LineNotifyPage({super.key});

  @override
  _LineNotifyPageState createState() => _LineNotifyPageState();
}

class _LineNotifyPageState extends State<LineNotifyPage> {
  CameraController? _cameraController; // 相機控制器
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR'); // 用於識別 QR Code 掃描器的全局鍵
  var _lastQrCode = "";
  String _scanInstruction = '請將郵件上的 QR Code 放入掃描區域內'; // 恢復原始提示文字
  bool _scanControlFlag = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // 初始化相機
  }

  void _initializeCamera() async {
    List<CameraDescription> cameras = await availableCameras(); // 獲取可用相機列表
    if (cameras.isEmpty) {
      return; // 如果沒有可用相機，離開函數
    }

    _cameraController = CameraController(cameras[0], ResolutionPreset.high); // 使用第一個相機初始化相機控制器
    await _cameraController?.initialize(); // 等待相機控制器初始化完成
    if (mounted) {
      setState(() {}); // 更新狀態以重新構建 widget
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // 釋放相機控制器資源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('臻琴社區郵件通知服務'),
      ),
      body: _cameraController != null && _cameraController!.value.isInitialized
          ? Column(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: _buildQrView(context), // 嵌套呼叫 _buildQrView 方法
                ),
              ],
            )
          : Center(
              child: const CircularProgressIndicator(), // 如果相機未初始化，顯示進度指示器
            ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 600 ||
            MediaQuery.of(context).size.height < 600)
        ? 300.0
        : 500.0; // 根據裝置寬高決定掃描區域大小
    return Stack(
    children: [
      QRView(
        key: _qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea,
        ),
        onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
      ),
      Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            _scanInstruction, // 使用 _scanInstruction 作為提示文字
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],);
  }

  // 播放手機內建預設警告聲
  Future<void> playDefaultAlertSound() async {
    final player = AudioPlayer();

    await player.setSourceAsset('sound_effects/alert.mp3');
    player.resume();
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無權限')), // 如果沒有權限，顯示SnackBar提示
      );
    }
  }
  Future<void> _sendLineNotify(String houseNo, String token) async {
    const String url = 'https://notify-api.line.me/api/notify';
    //const String token = 'FdK2OfT92Ab1GSDO3QsN7c9af9IgqJrNTlQcsQcHQzR';
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    String message = '親愛的$houseNo住戶，您信箱中尚有郵件未取，請別忘了，謝謝！\n$formattedDate';
    var response;
    try {
      response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
      'message': message,
        },
      );
    // 处理响应...
    } catch (e) {
    }
    if (response.statusCode == 200) {
      setState(() {
        _scanInstruction = '$houseNo，發送成功！'; // 更新提示文字
      });
      playDefaultAlertSound();
    } else {
      setState(() {
        _scanInstruction = '$houseNo，發送失敗！'; // 更新提示文字
      });
    }
  }

  void _processScannedData(String qrData) async {
    int index = qrData.indexOf(',');
    int len = qrData.length;
    String houseNo, token;
    if(!((index>0) && (index<len-1))){ // 檢查qrCdata是否為正確格式
      return;
    }
    houseNo = qrData.substring(0, index);
    token = qrData.substring(index+1);
    //_qrViewController?.pauseCamera(); // 暫停掃描器
    if((_lastQrCode != qrData) && !_scanControlFlag){
      _scanControlFlag = true;
      await _sendLineNotify(houseNo, token); // 發送 Line Notify 消息
    }else{
//      setState(() {
//        _scanInstruction = 'QR Code 已經掃描過了'; // 重覆掃瞄提示文字
//      });
    }
    
    _lastQrCode = qrData;
    _scanControlFlag = false;
    
    //_qrViewController?.resumeCamera(); // 恢復掃描器
/*
    Future.delayed(Duration(milliseconds: 500), () {
      //print('延迟 0.5 秒后执行的代码');
      // 在这里可以执行你想要延迟执行的操作
      setState(() {
        _scanInstruction = '請將郵件上的 QR Code 放入掃描區域內'; // 恢復原始提示文字
      });
    });*/
  }

  void _onQRViewCreated(QRViewController controller) {
    controller.scannedDataStream.listen((scanData) {
      // 使用 scanData.code 來訪問 QR Code 中的文本數據
      String? qrData = scanData.code;
      _processScannedData(qrData!); // 處理掃描到的文本數據
    });
  }
}